#!/usr/bin/env bash

# ======================================
# Plugin: Sao lưu & phục hồi hệ thống
# Category: SYSTEM_BACKUP
# ======================================

SYSTEM_BACKUP_DIR="/backup/system"

system_backup_full() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Backup toàn server"
  echo "══════════════════════════════════════════════"
  
  local timestamp=$(date +%Y%m%d-%H%M%S)
  mkdir -p "$SYSTEM_BACKUP_DIR"
  
  log_info "Đang backup cấu hình hệ thống..."
  
  tar -czf "${SYSTEM_BACKUP_DIR}/system-config-${timestamp}.tar.gz" \
    /etc/nginx \
    /etc/nguyendc-ols \
    /etc/php \
    /etc/mysql \
    /etc/mongod.conf \
    /etc/postgresql 2>/dev/null || true
  
  log_info "Đang backup danh sách packages..."
  dpkg --get-selections > "${SYSTEM_BACKUP_DIR}/packages-${timestamp}.txt"
  
  log_info "Đang backup PM2 processes..."
  pm2 save 2>/dev/null || true
  cp ~/.pm2/dump.pm2 "${SYSTEM_BACKUP_DIR}/pm2-dump-${timestamp}.pm2" 2>/dev/null || true
  
  log_success "Đã backup toàn hệ thống tại: $SYSTEM_BACKUP_DIR"
}

system_restore() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Restore toàn server từ snapshot"
  echo "══════════════════════════════════════════════"
  
  log_warn "Chức năng này cần được thực hiện cẩn thận!"
  
  echo "Danh sách backup:"
  ls -lh "$SYSTEM_BACKUP_DIR"
  echo ""
  
  read -rp "Nhập tên file backup config: " backup_file
  
  if [[ ! -f "${SYSTEM_BACKUP_DIR}/${backup_file}" ]]; then
    log_error "File backup không tồn tại."
    return 1
  fi
  
  log_warn "Restore sẽ ghi đè cấu hình hiện tại!"
  read -rp "Gõ YES_RESTORE để xác nhận: " confirm
  
  if [[ "$confirm" == "YES_RESTORE" ]]; then
    tar -xzf "${SYSTEM_BACKUP_DIR}/${backup_file}" -C /
    log_success "Đã restore từ backup. Khởi động lại các service."
  fi
}

system_backup_cron() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Lập lịch backup tự động (cron)"
  echo "══════════════════════════════════════════════"
  
  echo "Gợi ý cron job cho backup tự động:"
  echo "0 2 * * * /path/to/nguyendc-ols.sh system-backup full"
  echo ""
  echo "Thêm vào: crontab -e"
}

system_backup_manage() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Quản lý thư mục backup / dung lượng"
  echo "══════════════════════════════════════════════"
  
  if [[ -d "$SYSTEM_BACKUP_DIR" ]]; then
    echo "Thư mục backup: $SYSTEM_BACKUP_DIR"
    echo ""
    du -sh "$SYSTEM_BACKUP_DIR"
    echo ""
    ls -lh "$SYSTEM_BACKUP_DIR"
  else
    echo "Chưa có backup nào."
  fi
  echo ""
}

system_backup_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "      Sao lưu & phục hồi hệ thống"
    echo "══════════════════════════════════════════════"
    echo " 1) Backup toàn server"
    echo " 2) Restore toàn server từ snapshot"
    echo " 3) Lập lịch backup tự động (cron)"
    echo " 4) Quản lý thư mục backup / dung lượng"
    echo " 0) Quay lại"
    echo
    read -rp "Chọn chức năng: " choice
    
    case "$choice" in
      1) system_backup_full; read -rp "Nhấn Enter..." ;;
      2) system_restore; read -rp "Nhấn Enter..." ;;
      3) system_backup_cron; read -rp "Nhấn Enter..." ;;
      4) system_backup_manage; read -rp "Nhấn Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "system-backup" \
  "Sao lưu & phục hồi hệ thống" \
  "SYSTEM_BACKUP" \
  "" \
  "system_backup_menu"
