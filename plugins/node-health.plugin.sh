#!/usr/bin/env bash
#
# ======================================
# Plugin: Node Health & Alert
# Project: nguyendc-ols
# ID: nodehealth
# Category: NODE
# ======================================

NODE_APPS_CONF="/etc/nguyendc-ols/node-apps.conf"

# -----------------------------
# Helper: đọc NODE_APPS_CONF
# format: name|domain|dir|port
# -----------------------------
nodehealth_ensure_conf() {
  if [[ ! -f "$NODE_APPS_CONF" ]]; then
    log_warn "Chưa có file ${NODE_APPS_CONF}. Hãy dùng plugin Node App Manager để tạo app trước."
    return 1
  fi
  return 0
}

nodehealth_list_apps_raw() {
  nodehealth_ensure_conf || return 1
  grep -v '^[[:space:]]*$' "$NODE_APPS_CONF"
}

# -----------------------------
# PM2 status cho 1 app
# -----------------------------
nodehealth_pm2_status() {
  local name="$1"
  if ! command -v pm2 >/dev/null 2>&1; then
    echo "NO_PM2"
    return 1
  fi

  # Lấy status cột status từ pm2 jlist
  local status
  status=$(pm2 jlist 2>/dev/null | jq -r ".[] | select(.name==\"${name}\") | .pm2_env.status" 2>/dev/null)
  [[ -z "$status" ]] && status="NOT_FOUND"
  echo "$status"
}

# -----------------------------
# HTTP check (status + time_total)
# -----------------------------
nodehealth_http_check() {
  local url="$1"
  if ! command -v curl >/dev/null 2>&1; then
    echo "ERR 0"
    return 1
  fi

  # Trả về: "<code> <time_ms>"
  local out code t time_ms
  out=$(curl -o /dev/null -s -w "%{http_code} %{time_total}" --max-time 8 "$url" || echo "000 9.999")
  code=$(echo "$out" | awk '{print $1}')
  t=$(echo "$out" | awk '{print $2}')
  time_ms=$(awk -v x="$t" 'BEGIN{printf "%.0f", x*1000}')
  echo "${code} ${time_ms}"
}

# -----------------------------
# Đánh giá health 1 app
# -----------------------------
nodehealth_check_one_app() {
  local name="$1" domain="$2" dir="$3" port="$4"
  local url="http://${domain}/"
  local pm2s
  pm2s=$(nodehealth_pm2_status "$name")

  local http_result code time_ms
  http_result=$(nodehealth_http_check "$url")
  code=$(echo "$http_result" | awk '{print $1}')
  time_ms=$(echo "$http_result" | awk '{print $2}')

  # Đánh giá
  local level="OK"   # OK / WARN / CRIT
  local reason=""

  if [[ "$pm2s" != "online" ]]; then
    level="CRIT"
    reason+="PM2=${pm2s}; "
  fi

  # HTTP 200/301/302 coi là ổn (nếu PM2 ok)
  if [[ "$code" == "000" || "$code" == "500" || "$code" == "502" || "$code" == "503" ]]; then
    level="CRIT"
    reason+="HTTP=${code}; "
  elif [[ "$code" != "200" && "$code" != "301" && "$code" != "302" ]]; then
    [[ "$level" != "CRIT" ]] && level="WARN"
    reason+="HTTP=${code}; "
  fi

  # time_ms threshold: > 2000ms coi là WARN/CRIT
  if (( time_ms > 4000 )); then
    level="CRIT"
    reason+="SLOW=${time_ms}ms; "
  elif (( time_ms > 2000 )); then
    [[ "$level" == "OK" ]] && level="WARN"
    reason+="SLOW=${time_ms}ms; "
  fi

  [[ -z "$reason" ]] && reason="All good."

  # In ra dạng máy đọc được:
  # name|domain|pm2_status|http_code|time_ms|level|reason
  echo "${name}|${domain}|${pm2s}|${code}|${time_ms}|${level}|${reason}"
}

# -----------------------------
# Tổng hợp health của tất cả app
# -----------------------------
nodehealth_run_all() {
  nodehealth_ensure_conf || return 1

  local line
  local summary_header="App     Domain                 PM2       HTTP  Time(ms) Level  Reason"
  local summary=""
  local worst="OK"  # OK < WARN < CRIT

  while IFS='|' read -r name domain dir port; do
    [[ -z "$name" ]] && continue

    local row
    row=$(nodehealth_check_one_app "$name" "$domain" "$dir" "$port")
    IFS='|' read -r n d pm2s code time_ms level reason <<< "$row"

    # build bảng
    summary+=$(printf "%-8s %-20s %-8s %-5s %-7s %-6s %s\n" "$n" "$d" "$pm2s" "$code" "$time_ms" "$level" "$reason")
    summary+=$'\n'

    # update worst
    case "$level" in
      CRIT) worst="CRIT" ;;
      WARN) [[ "$worst" == "OK" ]] && worst="WARN" ;;
    esac

  done < <(nodehealth_list_apps_raw)

  echo "══════════════════════════════════════════════"
  echo "         Node Apps Health Summary"
  echo "══════════════════════════════════════════════"
  echo "$summary_header"
  echo "--------------------------------------------------------------"
  echo -ne "$summary"
  echo "--------------------------------------------------------------"
  echo "Overall status: ${worst}"
  echo "Thời gian: $(date +'%Y-%m-%d %H:%M:%S')"

  # Gửi Telegram nếu có cảnh báo
  nodehealth_telegram_notify "$worst" "$summary"
}

# -----------------------------
# Gửi báo cáo sang Telegram
# -----------------------------
nodehealth_telegram_notify() {
  local worst="$1"
  local summary="$2"

  # Nếu không có plugin telegram thì bỏ qua
  if [[ "$(type -t telegram_send_message)" != "function" ]]; then
    return 0
  fi

  # Chỉ gửi khi có WARN/CRIT để tránh spam
  if [[ "$worst" == "OK" ]]; then
    return 0
  fi

  local emoji="⚠️"
  [[ "$worst" == "CRIT" ]] && emoji="🚨"

  local msg="${emoji} *Node Apps Health* (overall: ${worst})

\`\`\`
App        Domain               PM2      HTTP  Time  Level   Reason
----------------------------------------------------------------
$(echo "$summary")
\`\`\`

Time: $(date +'%Y-%m-%d %H:%M:%S')
"

  telegram_send_message "$msg" || true
}

# -----------------------------
# Menu
# -----------------------------
nodehealth_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "        Node Health & Alert (Plugin)"
    echo "                nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "1) Chạy health check tất cả Node app"
    echo "2) Xem raw NODE_APPS_CONF"
    echo "0) Quay lại"
    echo
    read -rp "Chọn: " c
    case "$c" in
      1) nodehealth_run_all; read -rp 'Nhấn Enter để tiếp tục...' ;;
      2) nodehealth_list_apps_raw | sed 's/|/ | /g'; read -rp 'Nhấn Enter...' ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# -----------------------------
# CLI: ./nguyendc-ols.sh nodehealth run
# -----------------------------
nodehealth_cli() {
  case "$1" in
    run|"")
      nodehealth_run_all
      ;;
    *)
      echo "NodeHealth CLI:"
      echo "  nodehealth run   - check tất cả Node app & gửi Telegram nếu có lỗi"
      ;;
  esac
}

ndc_register_plugin \
  "nodehealth" \
  "Node Health & Alert" \
  "NODE" \
  "Kiểm tra PM2 + HTTP health cho Node apps, gửi cảnh báo Telegram" \
  "nodehealth_menu"
