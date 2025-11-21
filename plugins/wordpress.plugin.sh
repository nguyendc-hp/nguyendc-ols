#!/usr/bin/env bash

# ======================================
# Plugin: WordPress Manager
# Project: nguyendc-ols
# ID: wordpress
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

wp_random_prefix() {
  tr -dc 'a-z' </dev/urandom | head -c 4
}

wp_new_site() {
  echo "══════════════════════════════════════════════"
  echo "         Tạo site WordPress mới"
  echo "══════════════════════════════════════════════"

  if ! php_is_installed 2>/dev/null; then
    if [[ "$(type -t php_install)" == "function" ]]; then
      log_info "PHP chưa cài, tiến hành cài qua plugin PHP..."
      php_install || log_error "Cài PHP lỗi."
    else
      log_warn "Không tìm thấy plugin PHP. Bạn cần tự cài PHP trước."
    fi
  fi

  local domain webroot
  read -r -p "Domain chính (VD: example.com): " domain
  if [[ -z "$domain" ]]; then
    log_error "Domain không được để trống."
    return 1
  fi

  webroot="${WP_BASE_DIR}/${domain}"
  read -r -p "Thư mục web root (mặc định: ${webroot}): " webroot_input
  webroot="${webroot_input:-$webroot}"

  mkdir -p "$webroot"
  cd "$webroot" || {
    log_error "Không thể cd vào ${webroot}."
    return 1
  }

  if [[ -f wp-config.php ]]; then
    log_warn "Thư mục này đã có wp-config.php, có vẻ là site WordPress. Dừng lại."
    return 1
  fi

  # Thông tin DB
  local db_name db_user db_pass
  read -r -p "Tên database (VD: wp_${domain//./_}): " db_name
  db_name="${db_name:-wp_${domain//./_}}"

  read -r -p "User DB (VD: wpuser): " db_user
  db_user="${db_user:-wpuser}"

  read -r -p "Mật khẩu DB: " db_pass
  if [[ -z "$db_pass" ]]; then
    log_error "Mật khẩu DB không được để trống."
    return 1
  fi

  # Tạo DB + user (yêu cầu có mysql client & quyền root)
  log_info "Tạo database & user..."
  mysql -uroot <<EOF 2>/tmp/wp-new-db.log
CREATE DATABASE IF NOT EXISTS \`${db_name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';
GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO '${db_user}'@'localhost';
FLUSH PRIVILEGES;
EOF

  if [[ $? -ne 0 ]]; then
    log_warn "Có lỗi khi tạo DB/user (xem /tmp/wp-new-db.log). Bạn cần kiểm tra lại."
  fi

  # Tải WordPress
  log_info "Tải WordPress mới nhất..."
  wget -q https://wordpress.org/latest.tar.gz -O latest.tar.gz || {
    log_error "Tải WordPress thất bại."
    return 1
  }

  tar -xzf latest.tar.gz --strip-components=1
  rm -f latest.tar.gz

  cp wp-config-sample.php wp-config.php

  # Sinh prefix ngẫu nhiên
  local prefix="wp_$(wp_random_prefix)_"

  # Cập nhật wp-config.php
  sed -i "s/database_name_here/${db_name}/" wp-config.php
  sed -i "s/username_here/${db_user}/" wp-config.php
  sed -i "s/password_here/${db_pass}/" wp-config.php
  sed -i "s/^\$table_prefix = 'wp_';/\$table_prefix = '${prefix}';/" wp-config.php

  # Thêm vài constant hữu ích mặc định (cache, limit, security)
  cat >> wp-config.php <<'EOF'

// === nguyendc-ols defaults ===
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '256M');
define('WP_POST_REVISIONS', 5);
define('AUTOSAVE_INTERVAL', 120);
define('EMPTY_TRASH_DAYS', 7);
// Khuyến nghị bật cron server thật, không dùng WP cron giả
define('DISABLE_WP_CRON', true);
// Tắt edit file trong admin (tăng bảo mật)
define('DISALLOW_FILE_EDIT', true);
EOF

  # Phân quyền
  chown -R www-data:www-data "$webroot" 2>/dev/null || true
  find "$webroot" -type d -exec chmod 755 {} \; 2>/dev/null || true
  find "$webroot" -type f -exec chmod 644 {} \; 2>/dev/null || true
  chmod 600 wp-config.php 2>/dev/null || true

  log_info "Đã tạo site WordPress mới ở ${webroot} với DB ${db_name}."

  echo
  echo "Gợi ý: dùng plugin vhost / setupwizard để cấu hình Nginx vhost + SSL cho domain: ${domain}"
}

wp_optimize_performance() {
  read -r -p "Nhập đường dẫn thư mục WordPress (webroot, VD: /var/www/example.com): " dir
  if [[ -z "$dir" || ! -d "$dir" ]]; then
    log_error "Thư mục không hợp lệ."
    return 1
  fi

  if ! wp_is_wp_dir "$dir"; then
    log_error "Không thấy wp-config.php + wp-includes trong thư mục này, có vẻ không phải WordPress."
    return 1
  fi

  local cfg="${dir}/wp-config.php"
  log_info "Tối ưu hiệu năng WordPress tại: ${dir}"

  # Backup
  cp "$cfg" "${cfg}.bak.$(date +%Y%m%d-%H%M%S)"
  log_info "Đã backup wp-config.php."

  # Thêm/ghi đè các constant hiệu năng
  # Nếu đã có, dùng sed thay; nếu chưa có, thêm cuối file.
  if grep -q "WP_MEMORY_LIMIT" "$cfg"; then
    sed -i "s/define('WP_MEMORY_LIMIT'.*/define('WP_MEMORY_LIMIT', '256M');/" "$cfg"
  else
    echo "define('WP_MEMORY_LIMIT', '256M');" >> "$cfg"
  fi

  if grep -q "WP_MAX_MEMORY_LIMIT" "$cfg"; then
    sed -i "s/define('WP_MAX_MEMORY_LIMIT'.*/define('WP_MAX_MEMORY_LIMIT', '256M');/" "$cfg"
  else
    echo "define('WP_MAX_MEMORY_LIMIT', '256M');" >> "$cfg"
  fi

  if grep -q "WP_POST_REVISIONS" "$cfg"; then
    sed -i "s/define('WP_POST_REVISIONS'.*/define('WP_POST_REVISIONS', 5);/" "$cfg"
  else
    echo "define('WP_POST_REVISIONS', 5);" >> "$cfg"
  fi

  if grep -q "AUTOSAVE_INTERVAL" "$cfg"; then
    sed -i "s/define('AUTOSAVE_INTERVAL'.*/define('AUTOSAVE_INTERVAL', 120);/" "$cfg"
  else
    echo "define('AUTOSAVE_INTERVAL', 120);" >> "$cfg"
  fi

  if grep -q "EMPTY_TRASH_DAYS" "$cfg"; then
    sed -i "s/define('EMPTY_TRASH_DAYS'.*/define('EMPTY_TRASH_DAYS', 7);/" "$cfg"
  else
    echo "define('EMPTY_TRASH_DAYS', 7);" >> "$cfg"
  fi

  # Kích hoạt cache (sau này cài plugin cache sẽ dùng)
  if grep -q "WP_CACHE" "$cfg"; then
    sed -i "s/define('WP_CACHE'.*/define('WP_CACHE', true);/" "$cfg"
  else
    echo "define('WP_CACHE', true);" >> "$cfg"
  fi

  # Tắt WP Cron giả, khuyến nghị cron thật
  if grep -q "DISABLE_WP_CRON" "$cfg"; then
    sed -i "s/define('DISABLE_WP_CRON'.*/define('DISABLE_WP_CRON', true);/" "$cfg"
  else
    echo "define('DISABLE_WP_CRON', true);" >> "$cfg"
  fi

  # Phân quyền
  chown -R www-data:www-data "$dir" 2>/dev/null || true
  find "$dir" -type d -exec chmod 755 {} \; 2>/dev/null || true
  find "$dir" -type f -exec chmod 644 {} \; 2>/dev/null || true
  chmod 600 "$cfg" 2>/dev/null || true

  log_info "Đã áp dụng tối ưu hiệu năng & phân quyền chuẩn cho WordPress."
  echo
  echo "Gợi ý thêm:"
  echo " - Cài plugin cache (WP Rocket, LiteSpeed Cache, W3TC, ...)"
  echo " - Bật object cache (Redis/Memcached) nếu server có."
}

wp_security_hardening() {
  read -r -p "Nhập thư mục WordPress cần harden (VD: /var/www/example.com): " dir
  if [[ -z "$dir" || ! -d "$dir" ]]; then
    log_error "Thư mục không hợp lệ."
    return 1
  fi

  if ! wp_is_wp_dir "$dir"; then
    log_error "Không thấy wp-config.php + wp-includes trong thư mục này."
    return 1
  fi

  local cfg="${dir}/wp-config.php"
  cp "$cfg" "${cfg}.security.bak.$(date +%Y%m%d-%H%M%S)"
  log_info "Đã backup wp-config.php trước khi harden."

  # 1) Tắt edit file trong admin
  if grep -q "DISALLOW_FILE_EDIT" "$cfg"; then
    sed -i "s/define('DISALLOW_FILE_EDIT'.*/define('DISALLOW_FILE_EDIT', true);/" "$cfg"
  else
    echo "define('DISALLOW_FILE_EDIT', true);" >> "$cfg"
  fi

  # 2) (Tuỳ chọn) ép admin dùng HTTPS
  read -r -p "Site này đã dùng HTTPS chưa? Bật FORCE_SSL_ADMIN? (y/N): " ssl_choice
  if [[ "$ssl_choice" == "y" || "$ssl_choice" == "Y" ]]; then
    if grep -q "FORCE_SSL_ADMIN" "$cfg"; then
      sed -i "s/define('FORCE_SSL_ADMIN'.*/define('FORCE_SSL_ADMIN', true);/" "$cfg"
    else
      echo "define('FORCE_SSL_ADMIN', true);" >> "$cfg"
    fi
  fi

  # 3) Tạo mu-plugin disable XML-RPC
  local mu_dir="${dir}/wp-content/mu-plugins"
  mkdir -p "$mu_dir"
  cat > "${mu_dir}/disable-xmlrpc.php" <<'EOF'
<?php
/*
Plugin Name: Disable XML-RPC (nguyendc-ols)
Description: Disable XML-RPC to reduce attack surface.
*/
add_filter('xmlrpc_enabled', '__return_false');
EOF

  # 4) Tuỳ chọn chặn REST user enumeration (basic)
  cat > "${mu_dir}/security-rest-users.php" <<'EOF'
<?php
/*
Plugin Name: Security REST Users (nguyendc-ols)
Description: Prevent REST API user enumeration.
*/
add_filter('rest_endpoints', function ($endpoints) {
    unset($endpoints['/wp/v2/users']);
    unset($endpoints['/wp/v2/users/(?P<id>[\d]+)']);
    return $endpoints;
});
EOF

  # 5) Phân quyền chặt hơn config
  chmod 600 "$cfg" 2>/dev/null || true

  log_info "Đã áp dụng hardening cơ bản cho WordPress:"
  echo " - Tắt chỉnh sửa theme/plugin trong admin"
  echo " - Disable XML-RPC qua mu-plugin"
  echo " - Hạn chế REST API user enumeration"
  echo " - Siết quyền wp-config.php"
}

wp_list_sites() {
  echo "Scan WordPress trong ${WP_BASE_DIR} (tối đa 4 cấp thư mục):"
  echo "--------------------------------------"
  local sites
  sites=$(wp_detect_sites)
  if [[ -z "$sites" ]]; then
    echo "Không tìm thấy site WordPress nào (wp-config.php)."
  else
    echo "$sites"
  fi
  echo "--------------------------------------"
}

wp_show_status_line() {
  local count
  count=$(wp_detect_sites | wc -l 2>/dev/null || echo 0)
  echo "Số site WordPress phát hiện trong ${WP_BASE_DIR}: ${count}"
}

wp_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "           WordPress Manager (Plugin)"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    wp_show_status_line
    echo
    echo "1) Tạo site WordPress mới"
    echo "2) Tối ưu hiệu năng cho site hiện có"
    echo "3) Hardening bảo mật site hiện có"
    echo "4) Liệt kê tất cả site WordPress (scan /var/www)"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) wp_new_site;              read -rp "Nhấn Enter để tiếp tục..." ;;
      2) wp_optimize_performance;  read -rp "Nhấn Enter để tiếp tục..." ;;
      3) wp_security_hardening;    read -rp "Nhấn Enter để tiếp tục..." ;;
      4) wp_list_sites;            read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh wordpress new|optimize|secure|list
wordpress_cli() {
  local subcmd="$1"
  case "$subcmd" in
    new)
      wp_new_site
      ;;
    optimize)
      wp_optimize_performance
      ;;
    secure|security|harden)
      wp_security_hardening
      ;;
    list|"")
      wp_list_sites
      ;;
    *)
      echo "WordPress CLI:"
      echo "  wordpress new        - tạo site WordPress mới"
      echo "  wordpress optimize   - tối ưu hiệu năng (hỏi path)"
      echo "  wordpress secure     - hardening bảo mật (hỏi path)"
      echo "  wordpress list       - liệt kê các site WordPress"
      return 1
      ;;
  esac
}

ndc_register_plugin \
  "wordpress" \
  "WordPress Manager" \
  "WORDPRESS" \
  "Tạo & tối ưu WordPress (tốc độ + bảo mật)" \
  "wp_menu"
