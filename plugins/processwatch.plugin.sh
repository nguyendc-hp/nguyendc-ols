#!/usr/bin/env bash

# ======================================
# Plugin: Process Watch
# Project: nguyendc-ols
# ID: processwatch
# Category: OPS
# ======================================

PROCESSWATCH_CONF="/etc/nguyendc-ols/processwatch.conf"

processwatch_ensure_conf() {
  if [[ ! -f "$PROCESSWATCH_CONF" ]]; then
    mkdir -p "$(dirname "$PROCESSWATCH_CONF")"
    cat > "$PROCESSWATCH_CONF" <<EOF
# Định dạng mỗi dòng:
# type|name|desc
# type:
#   service - dùng systemctl is-active name
#   process - tìm theo pgrep name
#
# ví dụ:
# service|nginx|Web server Nginx
# service|mariadb|Database MariaDB
# process|node|Node.js apps
EOF
  fi
}

processwatch_list() {
  processwatch_ensure_conf
  echo "Danh sách theo dõi trong $PROCESSWATCH_CONF:"
  echo "--------------------------------------"
  grep -v '^[# ]' "$PROCESSWATCH_CONF" || echo "  (Không có)"
  echo "--------------------------------------"
}

processwatch_add() {
  processwatch_ensure_conf
  echo "Loại type: service hoặc process"
  read -r -p "Type (service/process): " type
  read -r -p "Tên (VD: nginx hoặc node): " name
  read -r -p "Mô tả (VD: Web server): " desc

  if [[ -z "$type" || -z "$name" ]]; then
    log_error "Type và name không được để trống."
    return 1
  fi

  echo "${type}|${name}|${desc}" >> "$PROCESSWATCH_CONF"
  log_info "Đã thêm: ${type}|${name}|${desc}"
}

processwatch_delete() {
  processwatch_ensure_conf
  processwatch_list
  read -r -p "Nhập name cần xoá: " name
  if [[ -z "$name" ]]; then
    log_error "Name không được để trống."
    return 1
  fi

  grep -v "|${name}|" "$PROCESSWATCH_CONF" > "${PROCESSWATCH_CONF}.tmp" || true
  mv "${PROCESSWATCH_CONF}.tmp" "$PROCESSWATCH_CONF"
  log_info "Đã xoá tất cả dòng có name='${name}'."
}

processwatch_run_once() {
  processwatch_ensure_conf

  echo "Chạy process/service watch:"
  echo

  local alerts=""
  while IFS='|' read -r type name desc; do
    [[ -z "$type" || "$type" =~ ^# ]] && continue

    local ok=1
    if [[ "$type" == "service" ]]; then
      systemctl is-active "$name" >/dev/null 2>&1 || ok=0
    elif [[ "$type" == "process" ]]; then
      pgrep -f "$name" >/dev/null 2>&1 || ok=0
    else
      continue
    fi

    if [[ "$ok" -eq 1 ]]; then
      echo "✅ ${type} ${name} (${desc}) OK"
    else
      echo "❌ ${type} ${name} (${desc}) DOWN"
      alerts+=$'\n'
      alerts+="• ${type} ${name} (${desc}) DOWN"
    fi
  done < "$PROCESSWATCH_CONF"

  if [[ -n "$alerts" ]]; then
    echo
    echo ">>> Có service/process bị down:"
    echo "$alerts"
    if [[ "$(type -t telegram_send_message)" == "function" ]]; then
      local msg="⚠️ *Process Watch Alert*:
${alerts}"
      telegram_send_message "$msg" || true
    else
      echo "(Chưa có plugin Telegram hoặc chưa cấu hình)"
    fi
  else
    echo
    echo "Tất cả service/process trong danh sách đều đang chạy."
  fi
}

processwatch_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "             Process Watch (Plugin)"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "Config file: ${PROCESSWATCH_CONF}"
    echo
    echo "1) Chạy kiểm tra ngay"
    echo "2) Thêm service/process cần theo dõi"
    echo "3) Xoá theo name"
    echo "4) Xem danh sách theo dõi"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) processwatch_run_once; read -rp "Nhấn Enter để tiếp tục..." ;;
      2) processwatch_add;      read -rp "Nhấn Enter để tiếp tục..." ;;
      3) processwatch_delete;   read -rp "Nhấn Enter để tiếp tục..." ;;
      4) processwatch_list;     read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh processwatch run
processwatch_cli() {
  local subcmd="$1"
  case "$subcmd" in
    run|"")
      processwatch_run_once
      ;;
    *)
      echo "Processwatch CLI:"
      echo "  processwatch run   - chạy kiểm tra process/service theo config"
      return 1
      ;;
  esac
}

ndc_register_plugin \
  "processwatch" \
  "Process Watch" \
  "OPS" \
  "Theo dõi service/process quan trọng, báo Telegram khi down" \
  "processwatch_menu"
