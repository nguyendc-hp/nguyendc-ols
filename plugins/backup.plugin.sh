#!/usr/bin/env bash

# ======================================
# Plugin: Simple Backup
# Project: nguyendc-ols
# ID: backup
# Category: BKP
# ======================================

BACKUP_STATE_KEY="BACKUP_ENABLED"
BACKUP_BASE_DIR="/opt/nguyendc-ols/backups"

backup_run() {
  mkdir -p "$BACKUP_BASE_DIR"

  local ts
  ts="$(date +%Y%m%d-%H%M%S)"

  local backup_file="${BACKUP_BASE_DIR}/backup-${ts}.tar.gz"

  echo "Thư mục sẽ được backup:"
  echo " - /etc/nginx"
  echo " - /var/www"
  echo

  read -r -p "Xác nhận chạy backup bây giờ? (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    log_info "Đã huỷ backup."
    return 0
  fi

  tar -czf "$backup_file" /etc/nginx /var/www 2>/dev/null || {
    log_error "Backup thất bại."
    return 1
  }

  log_info "Đã tạo file backup: ${backup_file}"
}

backup_list() {
  mkdir -p "$BACKUP_BASE_DIR"
  echo "Danh sách file backup trong ${BACKUP_BASE_DIR}:"
  ls -lh "${BACKUP_BASE_DIR}" 2>/dev/null || echo "  (Không có)"
}

backup_delete() {
  mkdir -p "$BACKUP_BASE_DIR"
  backup_list
  echo
  read -r -p "Nhập tên file backup cần xoá (chỉ tên file, không kèm path): " filename
  if [[ -z "$filename" ]]; then
    log_error "Tên file không được để trống."
    return 1
  fi

  local full="${BACKUP_BASE_DIR}/${filename}"
  if [[ ! -f "$full" ]]; then
    log_error "Không tìm thấy file backup: ${full}"
    return 1
  fi

  rm -f "$full"
  log_info "Đã xoá file backup: ${filename}"
}

backup_show_status_line() {
  mkdir -p "$BACKUP_BASE_DIR"
  local count
  count="$(ls -1 "${BACKUP_BASE_DIR}" 2>/dev/null | wc -l || echo 0)"
  echo "Backup dir: ${BACKUP_BASE_DIR} - Số file: ${count}"
}

backup_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "          Quản lý Backup (Simple)"
    echo "               nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    backup_show_status_line
    echo
    echo "1) Chạy backup ngay (tar.gz /etc/nginx + /var/www)"
    echo "2) Liệt kê file backup"
    echo "3) Xoá file backup"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) backup_run;    read -rp "Nhấn Enter để tiếp tục..." ;;
      2) backup_list;   read -rp "Nhấn Enter để tiếp tục..." ;;
      3) backup_delete; read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "backup" \
  "Simple Backup" \
  "BKP" \
  "Backup nhanh /etc/nginx và /var/www vào /opt/nguyendc-ols/backups" \
  "backup_menu"
