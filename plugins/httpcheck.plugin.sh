#!/usr/bin/env bash

# ======================================
# Plugin: HTTP Check
# Project: nguyendc-ols
# ID: httpcheck
# Category: OPS
# ======================================

HTTPCHECK_CONF="/etc/nguyendc-ols/httpcheck.conf"

httpcheck_ensure_conf() {
  if [[ ! -f "$HTTPCHECK_CONF" ]]; then
    mkdir -p "$(dirname "$HTTPCHECK_CONF")"
    cat > "$HTTPCHECK_CONF" <<EOF
# Định dạng mỗi dòng:
# name|url|max_ms
# Ví dụ:
# homepage|https://example.com|2000
EOF
  fi
}

httpcheck_list() {
  httpcheck_ensure_conf
  echo "Danh sách endpoint trong $HTTPCHECK_CONF:"
  echo "--------------------------------------"
  grep -v '^[# ]' "$HTTPCHECK_CONF" || echo "  (Không có)"
  echo "--------------------------------------"
}

httpcheck_add() {
  httpcheck_ensure_conf
  read -r -p "Tên endpoint (VD: homepage): " name
  read -r -p "URL (VD: https://example.com): " url
  read -r -p "Timeout tối đa (ms, VD: 2000): " max_ms

  if [[ -z "$name" || -z "$url" || -z "$max_ms" ]]; then
    log_error "Không được để trống."
    return 1
  fi

  echo "${name}|${url}|${max_ms}" >> "$HTTPCHECK_CONF"
  log_info "Đã thêm endpoint: ${name} -> ${url} (max ${max_ms}ms)"
}

httpcheck_delete() {
  httpcheck_ensure_conf
  httpcheck_list
  read -r -p "Nhập tên endpoint cần xoá: " name
  if [[ -z "$name" ]]; then
    log_error "Tên không được để trống."
    return 1
  fi

  grep -v "^${name}|" "$HTTPCHECK_CONF" > "${HTTPCHECK_CONF}.tmp" || true
  mv "${HTTPCHECK_CONF}.tmp" "$HTTPCHECK_CONF"
  log_info "Đã xoá endpoint '${name}'."
}

httpcheck_run_once() {
  httpcheck_ensure_conf
  if ! command -v curl >/dev/null 2>&1; then
    log_error "Thiếu curl. Hãy cài curl trước."
    return 1
  fi

  echo "Chạy HTTP check theo cấu hình trong ${HTTPCHECK_CONF}"
  echo

  local alerts=""
  while IFS='|' read -r name url max_ms; do
    [[ -z "$name" || "$name" =~ ^# ]] && continue

    echo "→ Check ${name}: ${url} (timeout ${max_ms}ms)"
    # dùng curl: time_total (s), http_code
    local result
    result=$(curl -o /dev/null -s -w "%{http_code} %{time_total}" --max-time 10 "$url" || echo "ERR 10")
    local code time
    code=$(echo "$result" | awk '{print $1}')
    time=$(echo "$result" | awk '{print $2}')

    # đổi thời gian sang ms
    local time_ms
    time_ms=$(awk -v t="$time" 'BEGIN{printf "%.0f\n", t*1000}')

    echo "  HTTP code: $code, time: ${time_ms}ms"

    local err=0
    if [[ "$code" != "200" && "$code" != "301" && "$code" != "302" ]]; then
      err=1
    fi
    if (( time_ms > max_ms )); then
      err=1
    fi

    if [[ "$err" -eq 1 ]]; then
      alerts+=$'\n'
      alerts+="• ${name} (${url}) - code=${code}, time=${time_ms}ms (max=${max_ms}ms)"
    fi
  done < "$HTTPCHECK_CONF"

  if [[ -n "$alerts" ]]; then
    echo
    echo ">>> Có endpoint lỗi / vượt timeout:"
    echo "$alerts"
    if [[ "$(type -t telegram_send_message)" == "function" ]]; then
      local msg="⚠️ *HTTP Check Alert*:
${alerts}"
      telegram_send_message "$msg" || true
    else
      echo "(Chưa có plugin Telegram hoặc chưa cấu hình)"
    fi
  else
    echo
    echo "Tất cả endpoint đều OK."
  fi
}

httpcheck_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "              HTTP Check (Plugin)"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "Config file: ${HTTPCHECK_CONF}"
    echo
    echo "1) Chạy HTTP check ngay"
    echo "2) Thêm endpoint cần theo dõi"
    echo "3) Xoá endpoint"
    echo "4) Xem danh sách endpoint"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) httpcheck_run_once; read -rp "Nhấn Enter để tiếp tục..." ;;
      2) httpcheck_add;      read -rp "Nhấn Enter để tiếp tục..." ;;
      3) httpcheck_delete;   read -rp "Nhấn Enter để tiếp tục..." ;;
      4) httpcheck_list;     read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh httpcheck run
httpcheck_cli() {
  local subcmd="$1"
  case "$subcmd" in
    run|"")
      httpcheck_run_once
      ;;
    *)
      echo "HTTP Check CLI:"
      echo "  httpcheck run   - chạy HTTP check theo config"
      return 1
      ;;
  esac
}

ndc_register_plugin \
  "httpcheck" \
  "HTTP Check" \
  "MONITORING" \
  "" \
  "httpcheck_menu"
