#!/usr/bin/env bash

# ======================================
# Plugin: Sao lưu & phục hồi dự án
# Category: PROJECT_BACKUP
# ======================================

BACKUP_DIR="/backup/projects"

backup_wordpress_site() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Backup site WordPress"
  echo "══════════════════════════════════════════════"
  
  read -rp "Nhập thư mục WordPress: " wp_dir
  read -rp "Nhập database name: " db_name
  
  if [[ ! -d "$wp_dir" ]]; then
    log_error "Thư mục không tồn tại."
    return 1
  fi
  
  local timestamp=$(date +%Y%m%d-%H%M%S)
  local backup_name="wp-$(basename "$wp_dir")-${timestamp}"
  
  mkdir -p "$BACKUP_DIR"
  
  # Backup files
  tar -czf "${BACKUP_DIR}/${backup_name}-files.tar.gz" -C "$(dirname "$wp_dir")" "$(basename "$wp_dir")"
  
  # Backup database
  mysqldump -uroot "$db_name" | gzip > "${BACKUP_DIR}/${backup_name}-db.sql.gz"
  
  log_success "Đã backup WordPress tại: $BACKUP_DIR/${backup_name}-*"
}

backup_node_app() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Backup app Node"
  echo "══════════════════════════════════════════════"
  
  read -rp "Nhập thư mục Node app: " app_dir
  
  if [[ ! -d "$app_dir" ]]; then
    log_error "Thư mục không tồn tại."
    return 1
  fi
  
  local timestamp=$(date +%Y%m%d-%H%M%S)
  local backup_name="node-$(basename "$app_dir")-${timestamp}"
  
  mkdir -p "$BACKUP_DIR"
  
  tar -czf "${BACKUP_DIR}/${backup_name}.tar.gz" \
    --exclude=node_modules \
    --exclude=.git \
    -C "$(dirname "$app_dir")" "$(basename "$app_dir")"
  
  log_success "Đã backup Node app tại: $BACKUP_DIR/${backup_name}.tar.gz"
}

backup_database() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Backup DB"
  echo "══════════════════════════════════════════════"
  
  echo "Chọn loại database:"
  echo " 1) MySQL/MariaDB"
  echo " 2) MongoDB"
  echo " 3) PostgreSQL"
  echo " 0) Quay lại"
  
  read -rp "Chọn: " choice
  
  case "$choice" in
    1)
      read -rp "Database name: " db_name
      mysqldump -uroot "$db_name" | gzip > "${BACKUP_DIR}/mysql-${db_name}-$(date +%Y%m%d).sql.gz"
      log_success "Đã backup MySQL database."
      ;;
    2)
      read -rp "Database name: " db_name
      mongodump --db="$db_name" --out="${BACKUP_DIR}/mongo-$(date +%Y%m%d)"
      log_success "Đã backup MongoDB database."
      ;;
    3)
      read -rp "Database name: " db_name
      sudo -u postgres pg_dump "$db_name" | gzip > "${BACKUP_DIR}/pg-${db_name}-$(date +%Y%m%d).sql.gz"
      log_success "Đã backup PostgreSQL database."
      ;;
  esac
}

restore_from_backup() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Restore từ backup"
  echo "══════════════════════════════════════════════"
  
  echo "Danh sách backup:"
  ls -lh "$BACKUP_DIR"
  echo ""
  
  read -rp "Nhập tên file backup: " backup_file
  read -rp "Nhập thư mục đích restore: " dest_dir
  
  if [[ ! -f "${BACKUP_DIR}/${backup_file}" ]]; then
    log_error "File backup không tồn tại."
    return 1
  fi
  
  mkdir -p "$dest_dir"
  tar -xzf "${BACKUP_DIR}/${backup_file}" -C "$dest_dir"
  
  log_success "Đã restore từ backup."
}

list_backups() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Quản lý danh sách backup theo dự án"
  echo "══════════════════════════════════════════════"
  
  if [[ -d "$BACKUP_DIR" ]]; then
    ls -lh "$BACKUP_DIR"
  else
    echo "Chưa có backup nào."
  fi
  echo ""
}

project_backup_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "      Sao lưu & phục hồi dự án"
    echo "══════════════════════════════════════════════"
    echo " 1) Backup site WordPress"
    echo " 2) Backup app Node"
    echo " 3) Backup DB"
    echo " 4) Restore từ backup"
    echo " 5) Quản lý danh sách backup"
    echo " 0) Quay lại"
    echo
    read -rp "Chọn chức năng: " choice
    
    case "$choice" in
      1) backup_wordpress_site; read -rp "Nhấn Enter..." ;;
      2) backup_node_app; read -rp "Nhấn Enter..." ;;
      3) backup_database; read -rp "Nhấn Enter..." ;;
      4) restore_from_backup; read -rp "Nhấn Enter..." ;;
      5) list_backups; read -rp "Nhấn Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "project-backup" \
  "Sao lưu & phục hồi dự án" \
  "PROJECT_BACKUP" \
  "" \
  "project_backup_menu"
