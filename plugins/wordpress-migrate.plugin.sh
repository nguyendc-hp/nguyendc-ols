#!/usr/bin/env bash
#
# ======================================
# Plugin: WordPress Migration
# Project: nguyendc-ols
# ID: wpmigrate
# Category: WORDPRESS
# ======================================

WP_BASE_DIR="/var/www"

wpm_is_wp_dir() {
  local dir="$1"
  [[ -f "$dir/wp-config.php" && -d "$dir/wp-includes" ]]
}

wpm_parse_db_info() {
  local cfg="$1"
  WPM_DB_NAME=$(grep "DB_NAME" "$cfg" | head -n1 | sed "s/.*'DB_NAME'.*'\(.*\)'.*/\1/")
  WPM_DB_USER=$(grep "DB_USER" "$cfg" | head -n1 | sed "s/.*'DB_USER'.*'\(.*\)'.*/\1/")
  WPM_DB_PASS=$(grep "DB_PASSWORD" "$cfg" | head -n1 | sed "s/.*'DB_PASSWORD'.*'\(.*\)'.*/\1/")
  WPM_DB_HOST=$(grep "DB_HOST" "$cfg" | head -n1 | sed "s/.*'DB_HOST'.*'\(.*\)'.*/\1/")
  [[ -z "$WPM_DB_HOST" ]] && WPM_DB_HOST="localhost"
}

wpm_copy_files() {
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  rsync -a "$src"/ "$dst"/
}

wpm_create_new_db() {
  local new_db new_user new_pass
  new_db="$1"
  new_user="$2"
  new_pass="$3"

  mysql -uroot <<EOF
CREATE DATABASE IF NOT EXISTS \`${new_db}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${new_user}'@'localhost' IDENTIFIED BY '${new_pass}';
GRANT ALL PRIVILEGES ON \`${new_db}\`.* TO '${new_user}'@'localhost';
FLUSH PRIVILEGES;
EOF
}

wpm_update_wpconfig() {
  local cfg="$1"
  local new_db="$2"
  local new_user="$3"
  local new_pass="$4"
  local new_host="$5"

  cp "$cfg" "${cfg}.migrate.bak.$(date +%Y%m%d-%H%M%S)"

  sed -i "s/define('DB_NAME'.*/define('DB_NAME', '${new_db}');/" "$cfg"
  sed -i "s/define('DB_USER'.*/define('DB_USER', '${new_user}');/" "$cfg"
  sed -i "s/define('DB_PASSWORD'.*/define('DB_PASSWORD', '${new_pass}');/" "$cfg"
  sed -i "s/define('DB_HOST'.*/define('DB_HOST', '${new_host}');/" "$cfg"

  chmod 600 "$cfg"
}

wpm_db_clone_with_replace() {
  # Cảnh báo: cách này string replace domain trong SQL có thể ảnh hưởng serialized data,
  # nhưng đa số case vẫn dùng được. Nếu có wp-cli, nên ưu tiên wp search-replace.
  local src_db="$1"
  local dst_db="$2"
  local src_host="$3"
  local user="$4"
  local pass="$5"
  local old_domain="$6"
  local new_domain="$7"

  # Dump
  mysqldump -h"$src_host" -u"$user" -p"$pass" "$src_db" > /tmp/wpmigrate_src.sql || {
    log_error "mysqldump từ DB nguồn thất bại."
    return 1
  }

  if command -v wp >/dev/null 2>&1; then
    log_info "Phát hiện wp-cli, khuyến nghị dùng wp search-replace sau khi import."
  fi

  # Replace domain trong SQL (cơ bản)
  sed -i "s/${old_domain//\//\\/}/${new_domain//\//\\/}/g" /tmp/wpmigrate_src.sql

  # Import vào DB đích
  mysql -h"$src_host" -u"$user" -p"$pass" "$dst_db" < /tmp/wpmigrate_src.sql || {
    log_error "Import vào DB đích thất bại."
    return 1
  }

  rm -f /tmp/wpmigrate_src.sql
}

wpm_try_wp_cli_replace() {
  local dst_dir="$1"
  local old_domain="$2"
  local new_domain="$3"

  if ! command -v wp >/dev/null 2>&1; then
    log_warn "wp-cli chưa cài. Bỏ qua bước wp search-replace."
    return
  fi

  pushd "$dst_dir" >/dev/null || return
  wp search-replace "$old_domain" "$new_domain" --skip-columns=guid || {
    log_warn "wp search-replace thất bại. Bạn cần kiểm tra dữ liệu."
  }
  popd >/dev/null || true
}

wpm_migrate_flow() {
  echo "══════════════════════════════════════════════"
  echo "          WordPress Migration Tool"
  echo "══════════════════════════════════════════════"

  read -r -p "Path source WP (VD: /var/www/old.com): " src_dir
  [[ ! -d "$src_dir" ]] && { log_error "Source dir không tồn tại."; return 1; }
  wpm_is_wp_dir "$src_dir" || { log_error "Source không phải WordPress."; return 1; }

  read -r -p "Domain cũ (VD: old.com): " old_domain
  read -r -p "Domain mới (VD: new.com): " new_domain
  [[ -z "$old_domain" || -z "$new_domain" ]] && { log_error "Domain không được trống."; return 1; }

  local dst_dir="${WP_BASE_DIR}/${new_domain}"
  read -r -p "Path đích (default: ${dst_dir}): " dst_input
  [[ -n "$dst_input" ]] && dst_dir="$dst_input"

  # DB info nguồn
  local src_cfg="${src_dir}/wp-config.php"
  wpm_parse_db_info "$src_cfg"

  echo "DB nguồn:"
  echo " - Name: ${WPM_DB_NAME}"
  echo " - User: ${WPM_DB_USER}"
  echo " - Host: ${WPM_DB_HOST}"

  # DB đích
  local new_db new_user new_pass
  read -r -p "Tên DB mới (mặc định: ${WPM_DB_NAME}_${new_domain//./_}): " new_db
  new_db="${new_db:-${WPM_DB_NAME}_${new_domain//./_}}"

  read -r -p "User DB mới (mặc định: ${WPM_DB_USER}_${new_domain//./_}): " new_user
  new_user="${new_user:-${WPM_DB_USER}_${new_domain//./_}}"

  read -r -p "Mật khẩu DB mới: " new_pass
  [[ -z "$new_pass" ]] && { log_error "Mật khẩu DB mới không được trống."; return 1; }

  log_info "Bắt đầu copy files..."
  wpm_copy_files "$src_dir" "$dst_dir"

  log_info "Tạo DB & user mới..."
  wpm_create_new_db "$new_db" "$new_user" "$new_pass"

  log_info "Clone DB với domain replace (basic)..."
  wpm_db_clone_with_replace "$WPM_DB_NAME" "$new_db" "$WPM_DB_HOST" "$WPM_DB_USER" "$WPM_DB_PASS" "$old_domain" "$new_domain"

  log_info "Cập nhật wp-config.php ở site mới..."
  wpm_update_wpconfig "${dst_dir}/wp-config.php" "$new_db" "$new_user" "$new_pass" "$WPM_DB_HOST"

  # Thử search-replace bằng wp-cli nếu có
  wpm_try_wp_cli_replace "$dst_dir" "$old_domain" "$new_domain"

  # Phân quyền
  chown -R www-data:www-data "$dst_dir"
  find "$dst_dir" -type d -exec chmod 755 {} \;
  find "$dst_dir" -type f -exec chmod 644 {} \;
  chmod 600 "${dst_dir}/wp-config.php"

  echo
  echo "✅ Đã clone site WordPress:"
  echo " - Source: ${src_dir} (${old_domain})"
  echo " - Target: ${dst_dir} (${new_domain})"
  echo
  echo "Bạn hãy:"
  echo " - Tạo Nginx vhost cho ${new_domain} (dùng plugin vhost hoặc setupwizard)"
  echo " - Cấp SSL (nếu cần) bằng Certbot plugin"
}

wpm_list_sites() {
  echo "Các site WordPress phát hiện:"
  find "$WP_BASE_DIR" -maxdepth 4 -type f -name "wp-config.php" 2>/dev/null
}

wpm_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "          WordPress Migration (Plugin)"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "1) Clone/migrate 1 site WP sang domain khác"
    echo "2) Liệt kê site WordPress"
    echo "0) Quay lại"
    echo
    read -rp "Chọn: " c
    case "$c" in
      1) wpm_migrate_flow; read -rp "Enter..." ;;
      2) wpm_list_sites;   read -rp "Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh wpmigrate run|list
wpmigrate_cli() {
  case "$1" in
    run)  wpm_migrate_flow ;;
    list) wpm_list_sites ;;
    *)
      echo "WP Migrate CLI:"
      echo "  wpmigrate run   - chạy wizard migrate"
      echo "  wpmigrate list  - liệt kê site"
      ;;
  esac
}

ndc_register_plugin \
  "wpmigrate" \
  "WordPress Migration" \
  "WORDPRESS" \
  "Clone / migrate WordPress sang domain khác (files + DB)" \
  "wpm_menu"
