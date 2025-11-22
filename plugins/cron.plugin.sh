#!/usr/bin/env bash

# ======================================
# Plugin: Cron Manager
# Project: nguyendc-ols
# ID: cron
# Category: SYSTEM
# ======================================

CRON_STATE_KEY="CRON_ENABLED"
CRON_FILE="/etc/cron.d/nguyendc-ols"

cron_ensure_root() {
  if [[ "$EUID" -ne 0 ]]; then
    log_error "Plugin Cron cần chạy với quyền root."
    return 1
  fi
  return 0
}

cron_show_file() {
  if [[ -f "$CRON_FILE" ]]; then
    echo "Nội dung $CRON_FILE:"
    echo "--------------------------------------"
    cat "$CRON_FILE"
    echo "--------------------------------------"
  else
    echo "$CRON_FILE chưa tồn tại."
  fi
}

cron_add_daily_backup() {
  cron_ensure_root || return 1

  local bak_cmd="/usr/bin/env bash -lc '/usr/bin/ndc_backup_run 2>>/var/log/nguyendc-ols-backup.log'"
  # Bạn có thể map ndc_backup_run -> gọi script nguyendc-ols.sh backup CLI sau này.
  # Tạm thời: ta gọi trực tiếp backup_run qua nguyendc-ols.sh nếu sau này có CLI.

  read -r -p "Chạy backup mỗi ngày lúc mấy giờ? (HH:MM, mặc định: 03:00): " time_str
  time_str="${time_str:-03:00}"

  local hh="${time_str%:*}"
  local mm="${time_str#*:}"

  if ! [[ "$hh" =~ ^[0-9]{1,2}$ && "$mm" =~ ^[0-9]{1,2}$ ]]; then
    log_error "Thời gian không hợp lệ."
    return 1
  fi

  mkdir -p "$(dirname "$CRON_FILE")"

  # Đơn giản: ghi 1 job daily gọi script backup. Sau này có CLI riêng thì sửa sau.
  cat > "$CRON_FILE" <<EOF
# Cron jobs for nguyendc-ols
# Backup daily
${mm} ${hh} * * * root /usr/local/bin/nguyendc-ols-backup.sh >/dev/null 2>&1
EOF

  chmod 644 "$CRON_FILE"

  log_info "Đã cấu hình cron backup mỗi ngày lúc ${hh}:${mm}. Hãy đảm bảo script /usr/local/bin/nguyendc-ols-backup.sh tồn tại."
  state_set "$CRON_STATE_KEY" "1"
}

cron_remove_file() {
  cron_ensure_root || return 1

  if [[ -f "$CRON_FILE" ]]; then
    rm -f "$CRON_FILE"
    log_info "Đã xoá file cron: $CRON_FILE"
  else
    log_info "Không có file cron để xoá."
  fi

  state_set "$CRON_STATE_KEY" "0"
}

cron_show_status_line() {
  if [[ -f "$CRON_FILE" ]]; then
    echo "✅ Đã cấu hình cron file: ${CRON_FILE}"
  else
    echo "❌ Chưa có cron file cho nguyendc-ols"
  fi
}

cron_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "            Quản lý Cron (Plugin)"
    echo "                nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    cron_show_status_line
    echo
    echo "1) Tạo cron backup hằng ngày (03:00 mặc định)"
    echo "2) Xem nội dung cron file"
    echo "3) Xoá cron file của nguyendc-ols"
    echo "4) Xem cron của user root (crontab -l)"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) cron_add_daily_backup; read -rp "Nhấn Enter để tiếp tục..." ;;
      2) cron_show_file;        read -rp "Nhấn Enter để tiếp tục..." ;;
      3) cron_remove_file;      read -rp "Nhấn Enter để tiếp tục..." ;;
      4) crontab -l;            read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "cron" \
  "Cron Manager" \
  "UTILITIES" \
  "" \
  "cron_menu"
