#!/usr/bin/env bash
#
# ======================================
# Plugin: Node Alert (Health + Logs + Telegram)
# Project: nguyendc-ols
# ID: nodealert
# Category: NODE
# ======================================

NODE_APPS_CONF="/etc/nguyendc-ols/node-apps.conf"
NODEALERT_LOG_LINES_KEY="NODEALERT_LOG_LINES"
NODEALERT_ERROR_THRESHOLD_KEY="NODEALERT_ERROR_THRESHOLD"

nodealert_get_log_lines() {
  local v
  v="$(state_get "$NODEALERT_LOG_LINES_KEY")"
  [[ -z "$v" ]] && v=300
  echo "$v"
}

nodealert_get_error_threshold() {
  local v
  v="$(state_get "$NODEALERT_ERROR_THRESHOLD_KEY")"
  [[ -z "$v" ]] && v=5
  echo "$v"
}

nodealert_set_thresholds() {
  read -r -p "Số dòng log dùng để phân tích (default 300): " l
  l="${l:-300}"
  state_set "$NODEALERT_LOG_LINES_KEY" "$l"

  read -r -p "Ngưỡng lỗi (ERROR/EXCEPTION/UNHANDLED) để cảnh báo (default 5): " t
  t="${t:-5}"
  state_set "$NODEALERT_ERROR_THRESHOLD_KEY" "$t"

  log_info "Đã cập nhật cấu hình: lines=${l}, error_threshold=${t}"
}

nodealert_ensure_conf() {
  if [[ ! -f "$NODE_APPS_CONF" ]]; then
    log_warn "Chưa có ${NODE_APPS_CONF}. Hãy dùng Node App Manager để tạo app trước."
    return 1
  fi
  return 0
}

nodealert_list_apps_raw() {
  nodealert_ensure_conf || return 1
  grep -v '^[[:space:]]*$' "$NODE_APPS_CONF"
}

# --------------------------------------
# PM2 status cho 1 app
# --------------------------------------
nodealert_pm2_status() {
  local name="$1"
  if ! command -v pm2 >/dev/null 2>&1; then
    echo "NO_PM2"
    return 1
  fi

  # nếu có jq dùng jlist, không thì fallback
  if command -v jq >/dev/null 2>&1; then
    local s
    s=$(pm2 jlist 2>/dev/null | jq -r ".[] | select(.name==\"${name}\") | .pm2_env.status" 2>/dev/null)
    [[ -z "$s" || "$s" == "null" ]] && s="NOT_FOUND"
    echo "$s"
  else
    # Fallback: dùng pm2 ls
    pm2 ls | awk -v n="$name" '$0 ~ n {print $10}' | head -n1
  fi
}

# --------------------------------------
# HTTP check (status + time_ms)
# --------------------------------------
nodealert_http_check() {
  local url="$1"
  if ! command -v curl >/dev/null 2>&1; then
    echo "000 0"
    return 1
  fi
  local out code t time_ms
  out=$(curl -o /dev/null -s -w "%{http_code} %{time_total}" --max-time 8 "$url" || echo "000 9.999")
  code=$(echo "$out" | awk '{print $1}')
  t=$(echo "$out" | awk '{print $2}')
  time_ms=$(awk -v x="$t" 'BEGIN{printf "%.0f", x*1000}')
  echo "${code} ${time_ms}"
}

# --------------------------------------
# Đếm lỗi trong log PM2 (gần N dòng)
# --------------------------------------
nodealert_error_count() {
  local name="$1"
  local lines="$2"
  if ! command -v pm2 >/dev/null 2>&1; then
    echo "0"
    return 1
  fi

  local tmp
  tmp=$(mktemp)
  # Lấy N dòng log PM2 cho app này
  pm2 logs "$name" --lines "$lines" --raw > "$tmp" 2>/dev/null &
  sleep 2
  pkill -f "pm2 logs $name" 2>/dev/null || true

  local cnt
  cnt=$(grep -Ei "error|exception|unhandled" "$tmp" | wc -l || echo 0)
  rm -f "$tmp"
  echo "$cnt"
}

# --------------------------------------
# Đánh giá 1 app
# Trả về line:
# name|domain|pm2_status|http_code|time_ms|errors|level|reason
# --------------------------------------
nodealert_check_one_app() {
  local name="$1" domain="$2" dir="$3" port="$4"
  local log_lines threshold
  log_lines=$(nodealert_get_log_lines)
  threshold=$(nodealert_get_error_threshold)

  local url="http://${domain}/"

  local pm2s
  pm2s=$(nodealert_pm2_status "$name")
  [[ -z "$pm2s" ]] && pm2s="UNKNOWN"

  local http_res code time_ms
  http_res=$(nodealert_http_check "$url")
  code=$(echo "$http_res" | awk '{print $1}')
  time_ms=$(echo "$http_res" | awk '{print $2}')

  local errors
  errors=$(nodealert_error_count "$name" "$log_lines")

  # Đánh giá
  local level="OK"
  local reason=""

  # PM2 status
  if [[ "$pm2s" != "online" ]]; then
    level="CRIT"
    reason+="PM2=${pm2s}; "
  fi

  # HTTP
  if [[ "$code" == "000" || "$code" == "500" || "$code" == "502" || "$code" == "503" ]]; then
    level="CRIT"
    reason+="HTTP=${code}; "
  elif [[ "$code" != "200" && "$code" != "301" && "$code" != "302" ]]; then
    [[ "$level" != "CRIT" ]] && level="WARN"
    reason+="HTTP=${code}; "
  fi

  # Response time
  if (( time_ms > 4000 )); then
    level="CRIT"
    reason+="SLOW=${time_ms}ms; "
  elif (( time_ms > 2000 )); then
    [[ "$level" == "OK" ]] && level="WARN"
    reason+="SLOW=${time_ms}ms; "
  fi

  # Error count
  if (( errors >= threshold * 2 )); then
    level="CRIT"
    reason+="ERRORS=${errors}; "
  elif (( errors >= threshold )); then
    [[ "$level" == "OK" ]] && level="WARN"
    reason+="ERRORS=${errors}; "
  fi

  [[ -z "$reason" ]] && reason="All good."

  echo "${name}|${domain}|${pm2s}|${code}|${time_ms}|${errors}|${level}|${reason}"
}

# --------------------------------------
# Chạy alert cho tất cả app
# --------------------------------------
nodealert_run_all() {
  nodealert_ensure_conf || return 1
  local line
  local header="App      Domain               PM2      HTTP  Time  Errs Level Reason"
  local summary=""
  local worst="OK"

  while IFS='|' read -r name domain dir port; do
    [[ -z "$name" ]] && continue
    local row
    row=$(nodealert_check_one_app "$name" "$domain" "$dir" "$port")
    IFS='|' read -r n d pm2s code time_ms errors level reason <<< "$row"

    summary+=$(printf "%-8s %-20s %-8s %-5s %-5s %-4s %-5s %s\n" "$n" "$d" "$pm2s" "$code" "$time_ms" "$errors" "$level" "$reason")
    summary+=$'\n'

    case "$level" in
      CRIT) worst="CRIT" ;;
      WARN) [[ "$worst" == "OK" ]] && worst="WARN" ;;
    esac
  done < <(nodealert_list_apps_raw)

  echo "══════════════════════════════════════════════"
  echo "              Node Alert Summary"
  echo "══════════════════════════════════════════════"
  echo "$header"
  echo "---------------------------------------------------------------------"
  echo -ne "$summary"
  echo "---------------------------------------------------------------------"
  echo "Overall: ${worst}"
  echo "Time   : $(date +'%Y-%m-%d %H:%M:%S')"

  nodealert_telegram_notify "$worst" "$summary"
}

# --------------------------------------
# Gửi Telegram nếu có vấn đề
# --------------------------------------
nodealert_telegram_notify() {
  local worst="$1"
  local summary="$2"

  if [[ "$(type -t telegram_send_message)" != "function" ]]; then
    return 0
  fi

  [[ "$worst" == "OK" ]] && return 0

  local emoji="⚠️"
  [[ "$worst" == "CRIT" ]] && emoji="🚨"

  local msg="${emoji} *Node Alert* (overall: ${worst})

\`\`\`
App      Domain               PM2      HTTP  Time  Errs Level Reason
------------------------------------------------------------------
$(echo "$summary")
\`\`\`

Time: $(date +'%Y-%m-%d %H:%M:%S')
"

  telegram_send_message "$msg" || true
}

nodealert_test_telegram() {
  if [[ "$(type -t telegram_send_message)" != "function" ]]; then
    log_error "Plugin Telegram chưa được load hoặc chưa có hàm telegram_send_message."
    return 1
  fi
  telegram_send_message "🔔 Test message từ NodeAlert / nguyendc-ols"
}

# --------------------------------------
# MENU
# --------------------------------------
nodealert_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "      Node Alert (Health + Logs + Telegram)"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "Log lines dùng để phân tích: $(nodealert_get_log_lines)"
    echo "Ngưỡng lỗi để cảnh báo     : $(nodealert_get_error_threshold)"
    echo
    echo "1) Chạy alert check ngay bây giờ"
    echo "2) Thiết lập log lines + error threshold"
    echo "3) Gửi test message Telegram"
    echo "0) Quay lại"
    echo
    read -rp "Chọn: " c
    case "$c" in
      1) nodealert_run_all; read -rp "Enter..." ;;
      2) nodealert_set_thresholds; read -rp "Enter..." ;;
      3) nodealert_test_telegram; read -rp "Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh nodealert run|config|test
nodealert_cli() {
  case "$1" in
    run|"") nodealert_run_all ;;
    config) nodealert_set_thresholds ;;
    test)   nodealert_test_telegram ;;
    *)
      echo "NodeAlert CLI:"
      echo "  nodealert run      - check health + logs & gửi Telegram nếu có ALERT"
      echo "  nodealert config   - thiết lập thresholds"
      echo "  nodealert test     - gửi test Telegram"
      ;;
  esac
}

ndc_register_plugin \
  "nodealert" \
  "Node Alert (Health + Logs + Telegram)" \
  "NODE" \
  "Giám sát Node apps: PM2 + HTTP + logs, gửi cảnh báo Telegram" \
  "nodealert_menu"
