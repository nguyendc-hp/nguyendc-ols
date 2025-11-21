#!/usr/bin/env bash
#
# ======================================
# Plugin: WordPress Backup
# Project: nguyendc-ols
# ID: wpbackup
# Category: WORDPRESS
# ======================================

WP_BASE_DIR="/var/www"
WP_BACKUP_DIR="/opt/nguyendc-ols/wp-backups"
WP_BACKUP_RETENTION_KEY="WP_BACKUP_KEEP_DAYS"

wpb_is_wp_dir() {
  local dir="$1"
  [[ -f "$dir/wp-config.php" && -d "$dir/wp-includes" ]]
}

wpb_parse_db_info() {
  # $1 = wp-config.php
  local cfg="$1"
  WPB_DB_NAME=$(grep "DB_NAME" "$cfg" | head -n1 | sed "s/.*'DB_NAME'.*'\(.*\)'.*/\1/")
  WPB_DB_USER=$(grep "DB_USER" "$cfg" | head -n1 | sed "s/.*'DB_USER'.*'\(.*\)'.*/\1/")
  WPB_DB_PASS=$(grep "DB_PASSWORD" "$cfg" | head -n1 | sed "s/.*'DB_PASSWORD'.*'\(.*\)'.*/\1/")
  WPB_DB_HOST=$(grep "DB_HOST" "$cfg" | head -n1 | sed "s/.*'DB_HOST'.*'\(.*\)'.*/\1/")
  [[ -z "$WPB_DB_HOST" ]] && WPB_DB_HOST="localhost"
}

wpb_get_retention_days() {
  local d
  d="$(state_get "$WP_BACKUP_RETENTION_KEY")"
  [[ -z "$d" ]] && d=7
  echo "$d"
}

wpb_set_retention_days() {
  read -r -p "Giữ backup trong bao nhiêu ngày? (mặc định 7): " d
  d="${d:-7}"
  state_set "$WP_BACKUP_RETENTION_KEY" "$d"
  log_info "Đã đặt retention = ${d} ngày."
}

wpb_backup_one_site() {
  read -r -p "Path thư mục WordPress (VD: /var/www/example.com): " dir
  [[ ! -d "$dir" ]] && { log_error "Thư mục không tồn tại."; return 1; }
  wpb_is_wp_dir "$dir" || { log_error "Không phải site WordPress."; return 1; }

  local cfg="${dir}/wp-config.php"
  wpb_parse_db_info "$cfg"

  if [[ -z "$WPB_DB_NAME" || -z "$WPB_DB_USER" ]]; then
    log_error "Không parse được DB_NAME / DB_USER từ wp-config.php"
    return 1
  fi

  mkdir -p "$WP_BACKUP_DIR"

  local domain
  domain=$(basename "$dir")
  local ts
  ts="$(date +%Y%m%d-%H%M%S)"
  local tmp_dir="${WP_BACKUP_DIR}/${domain}_${ts}"
  mkdir -p "$tmp_dir"

  log_info "Backup DB: ${WPB_DB_NAME}"
  mysqldump -h"$WPB_DB_HOST" -u"$WPB_DB_USER" -p"$WPB_DB_PASS" "$WPB_DB_NAME" > "${tmp_dir}/db.sql" 2>"${tmp_dir}/db_dump.log" || {
    log_warn "mysqldump có lỗi (xem ${tmp_dir}/db_dump.log)."
  }

  log_info "Backup files: ${dir}"
  rsync -a --delete "$dir"/ "${tmp_dir}/files/" >/dev/null 2>&1

  local tar_file="${WP_BACKUP_DIR}/${domain}_${ts}.tar.gz"
  tar -czf "$tar_file" -C "$WP_BACKUP_DIR" "$(basename "$tmp_dir")"
  rm -rf "$tmp_dir"

  log_info "Đã tạo backup: ${tar_file}"
}

wpb_list_backups() {
  mkdir -p "$WP_BACKUP_DIR"
  echo "Backup dir: ${WP_BACKUP_DIR}"
  ls -lh "$WP_BACKUP_DIR"
}

wpb_prune_old_backups() {
  local days
  days="$(wpb_get_retention_days)"
  mkdir -p "$WP_BACKUP_DIR"
  find "$WP_BACKUP_DIR" -type f -name "*.tar.gz" -mtime +"${days}" -print -delete
  log_info "Đã xoá các backup cũ hơn ${days} ngày."
}

wpb_push_to_rclone() {
  if ! command -v rclone >/dev/null 2>&1; then
    log_error "rclone chưa cài. Hãy dùng plugin rclone để cài."
    return 1
  fi

  read -r -p "Tên remote rclone (VD: gdrive): " remote
  read -r -p "Thư mục trên remote (VD: wp-backups): " path
  [[ -z "$remote" ]] && { log_error "Remote không được trống."; return 1; }
  [[ -z "$path" ]] && path="wp-backups"

  local dest="${remote}:${path}"
  log_info "Sync ${WP_BACKUP_DIR} -> ${dest}"
  rclone sync "$WP_BACKUP_DIR" "$dest" --progress
}

wpb_list_sites() {
  echo "Các site WordPress trong ${WP_BASE_DIR}:"
  find "$WP_BASE_DIR" -maxdepth 4 -type f -name "wp-config.php" 2>/dev/null
}

wpb_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "          WordPress Backup (Plugin)"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "Backup dir: ${WP_BACKUP_DIR}"
    echo "Retention : $(wpb_get_retention_days) ngày"
    echo
    echo "1) Backup 1 site WordPress (files + DB)"
    echo "2) Liệt kê file backup"
    echo "3) Xoá backup cũ (theo retention)"
    echo "4) Thiết lập số ngày giữ backup"
    echo "5) Đẩy backup lên rclone remote (GDrive / S3 ...)"
    echo "6) Liệt kê site WordPress"
    echo "0) Quay lại"
    echo
    read -rp "Chọn: " c
    case "$c" in
      1) wpb_backup_one_site;   read -rp "Enter..." ;;
      2) wpb_list_backups;      read -rp "Enter..." ;;
      3) wpb_prune_old_backups; read -rp "Enter..." ;;
      4) wpb_set_retention_days; read -rp "Enter..." ;;
      5) wpb_push_to_rclone;    read -rp "Enter..." ;;
      6) wpb_list_sites;        read -rp "Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh wpbackup backup|list|prune
wpbackup_cli() {
  case "$1" in
    backup) wpb_backup_one_site ;;
    list)   wpb_list_backups ;;
    prune)  wpb_prune_old_backups ;;
    *)
      echo "WP Backup CLI:"
      echo "  wpbackup backup  - backup 1 site"
      echo "  wpbackup list    - liệt kê backup"
      echo "  wpbackup prune   - xoá backup cũ"
      ;;
  esac
}

ndc_register_plugin \
  "wpbackup" \
  "WordPress Backup" \
  "WORDPRESS" \
  "Backup WordPress (files + DB) + retention + rclone" \
  "wpb_menu"
