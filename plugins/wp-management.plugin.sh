#!/usr/bin/env bash

# ======================================
# Plugin: Quản lý WordPress  
# Category: WORDPRESS
# ======================================

WP_BASE_DIR="/var/www"

wp_detect_sites() {
  find "$WP_BASE_DIR" -maxdepth 4 -type f -name "wp-config.php" 2>/dev/null
}

wp_is_wp_dir() {
  local dir="$1"
  [[ -f "$dir/wp-config.php" && -f "$dir/wp-includes/version.php" ]]
}

wp_new_site() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Tạo site WordPress mới"
  echo "══════════════════════════════════════════════"
  
  read -rp "Domain: " domain
  read -rp "Webroot (mặc định /var/www/${domain}): " webroot
  webroot="${webroot:-/var/www/$domain}"
  
  read -rp "Database name: " db_name
  read -rp "Database user: " db_user
  read -rp "Database password: " db_pass
  
  if [[ -z "$domain" || -z "$db_name" || -z "$db_user" || -z "$db_pass" ]]; then
    log_error "Các thông tin không được để trống."
    return 1
  fi
  
  # Tạo DB
  mysql -uroot <<EOF
CREATE DATABASE IF NOT EXISTS \`${db_name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';
GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO '${db_user}'@'localhost';
FLUSH PRIVILEGES;
EOF
  
  # Tải WordPress
  mkdir -p "$webroot"
  cd "$webroot" || return 1
  wget -q https://wordpress.org/latest.tar.gz -O latest.tar.gz
  tar -xzf latest.tar.gz --strip-components=1
  rm -f latest.tar.gz
  
  cp wp-config-sample.php wp-config.php
  sed -i "s/database_name_here/${db_name}/" wp-config.php
  sed -i "s/username_here/${db_user}/" wp-config.php
  sed -i "s/password_here/${db_pass}/" wp-config.php
  
  chown -R www-data:www-data "$webroot"
  find "$webroot" -type d -exec chmod 755 {} \;
  find "$webroot" -type f -exec chmod 644 {} \;
  
  log_success "Đã tạo site WordPress mới tại $webroot"
}

wp_import_site() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Import site WordPress (file + DB)"
  echo "══════════════════════════════════════════════"
  
  read -rp "Nhập đường dẫn file backup (.zip/.tar.gz): " backup_file
  read -rp "Nhập đường dẫn thư mục đích: " dest_dir
  
  if [[ ! -f "$backup_file" ]]; then
    log_error "File backup không tồn tại."
    return 1
  fi
  
  mkdir -p "$dest_dir"
  
  if [[ "$backup_file" == *.zip ]]; then
    unzip -q "$backup_file" -d "$dest_dir"
  elif [[ "$backup_file" == *.tar.gz ]]; then
    tar -xzf "$backup_file" -C "$dest_dir"
  fi
  
  log_success "Đã giải nén file backup. Vui lòng import database thủ công."
}

wp_list_sites() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Danh sách site WordPress đang chạy"
  echo "══════════════════════════════════════════════"
  
  local sites
  sites=$(wp_detect_sites)
  
  if [[ -z "$sites" ]]; then
    echo "Không tìm thấy site WordPress nào."
  else
    echo "$sites"
  fi
  echo
}

wp_assign_domain() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Gán / đổi domain cho site WordPress"
  echo "══════════════════════════════════════════════"
  
  read -rp "Nhập domain mới: " domain
  read -rp "Nhập webroot WordPress: " webroot
  
  if [[ -z "$domain" || -z "$webroot" ]]; then
    log_error "Domain và webroot không được để trống."
    return 1
  fi
  
  # Tạo Nginx vhost
  cat > "/etc/nginx/sites-available/${domain}.conf" <<EOF
server {
    listen 80;
    server_name ${domain};
    root ${webroot};
    index index.php index.html;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
EOF
  
  ln -sf "/etc/nginx/sites-available/${domain}.conf" "/etc/nginx/sites-enabled/${domain}.conf"
  nginx -t && systemctl reload nginx
  
  log_success "Đã gán domain $domain cho WordPress tại $webroot"
}

wp_delete_site() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Xóa site WordPress"
  echo "══════════════════════════════════════════════"
  
  read -rp "Nhập thư mục WordPress cần xóa: " webroot
  
  if [[ -z "$webroot" || ! -d "$webroot" ]]; then
    log_error "Thư mục không hợp lệ."
    return 1
  fi
  
  log_warn "BẠN SẮP XÓA VĨNH VIỄN: $webroot"
  read -rp "Gõ YES_DELETE để xác nhận: " confirm
  
  if [[ "$confirm" == "YES_DELETE" ]]; then
    rm -rf "$webroot"
    log_success "Đã xóa site WordPress."
  else
    log_info "Đã hủy xóa."
  fi
}

wp_management_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "          Quản lý WordPress"
    echo "══════════════════════════════════════════════"
    echo " 1) Tạo site WordPress mới"
    echo " 2) Import site WordPress (file + DB)"
    echo " 3) Danh sách site WordPress đang chạy"
    echo " 4) Gán / đổi domain cho site WordPress"
    echo " 5) Xóa site WordPress"
    echo " 0) Quay lại"
    echo
    read -rp "Chọn chức năng: " choice
    
    case "$choice" in
      1) wp_new_site; read -rp "Nhấn Enter..." ;;
      2) wp_import_site; read -rp "Nhấn Enter..." ;;
      3) wp_list_sites; read -rp "Nhấn Enter..." ;;
      4) wp_assign_domain; read -rp "Nhấn Enter..." ;;
      5) wp_delete_site; read -rp "Nhấn Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "wp-management" \
  "Quản lý WordPress" \
  "WORDPRESS" \
  "" \
  "wp_management_menu"
