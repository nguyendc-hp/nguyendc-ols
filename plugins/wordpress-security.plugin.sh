#!/usr/bin/env bash
#
# ======================================
# Plugin: WordPress Security Firewall
# Project: nguyendc-ols
# ID: wpsec
# Category: SEC
# ======================================

WP_BASE_DIR="/var/www"

wpsec_is_wp_dir() {
  local dir="$1"
  [[ -f "$dir/wp-config.php" && -d "$dir/wp-includes" ]]
}

wpsec_nginx_security_snippet() {
  local domain="$1"
  local file="/etc/nginx/conf.d/${domain}_security.conf"

  cat > "$file" <<EOF
# ======================================
# WordPress Security (nguyendc-ols)
# Domain: ${domain}
# ======================================

# Chặn truy cập trực tiếp vào xmlrpc.php (hoặc bạn có thể đổi thành rate limit)
location = /xmlrpc.php {
    deny all;
    access_log off;
    log_not_found off;
}

# Hạn chế brute force wp-login.php
limit_req_zone \$binary_remote_addr zone=wp_login_limit:10m rate=10r/m;

location = /wp-login.php {
    limit_req zone=wp_login_limit burst=20 nodelay;
    include fastcgi_params;
    # fastcgi_pass phải trùng với config PHP-FPM hiện tại của bạn
    fastcgi_pass unix:/run/php/php-fpm.sock;
}

# Chặn truy cập file nhạy cảm
location ~* /(wp-config.php|readme.html|license.txt|.htaccess)$ {
    deny all;
    access_log off;
    log_not_found off;
}

# Tắt liệt kê thư mục
autoindex off;

EOF

  nginx -t && systemctl reload nginx
  log_info "Đã tạo/cập nhật Nginx security config: ${file}"
}

wpsec_fail2ban_filter_file="/etc/fail2ban/filter.d/nguyendc-wp-login.conf"
wpsec_fail2ban_jail_file="/etc/fail2ban/jail.d/nguyendc-wp-login.conf"

wpsec_setup_fail2ban() {
  if ! command -v fail2ban-server >/dev/null 2>&1; then
    log_warn "Fail2ban chưa cài. Hãy dùng plugin firewall/fail2ban (nếu có) để cài trước."
    return 1
  fi

  cat > "$wpsec_fail2ban_filter_file" <<'EOF'
[Definition]
failregex = <HOST> - .* "POST /wp-login\.php HTTP/.*" 200
ignoreregex =
EOF

  cat > "$wpsec_fail2ban_jail_file" <<'EOF'
[nguyendc-wp-login]
enabled  = true
port     = http,https
filter   = nguyendc-wp-login
logpath  = /var/log/nginx/*access.log
maxretry = 10
findtime = 600
bantime  = 3600
EOF

  systemctl restart fail2ban
  log_info "Đã thêm Fail2ban rule cho wp-login.php (nguyendc-wp-login jail)."
}

wpsec_harden_wp_config() {
  local dir="$1"
  local cfg="${dir}/wp-config.php"
  [[ ! -f "$cfg" ]] && { log_error "Không tìm thấy wp-config.php"; return 1; }

  cp "$cfg" "${cfg}.sec.bak.$(date +%Y%m%d-%H%M%S)"

  # Tắt edit file
  if grep -q "DISALLOW_FILE_EDIT" "$cfg"; then
    sed -i "s/define('DISALLOW_FILE_EDIT'.*/define('DISALLOW_FILE_EDIT', true);/" "$cfg"
  else
    echo "define('DISALLOW_FILE_EDIT', true);" >> "$cfg"
  fi

  # Bật FORCE_SSL_ADMIN khi có HTTPS
  read -r -p "Site này đã chạy HTTPS chưa? Bật FORCE_SSL_ADMIN? (y/N): " sslc
  if [[ "$sslc" == "y" || "$sslc" == "Y" ]]; then
    if grep -q "FORCE_SSL_ADMIN" "$cfg"; then
      sed -i "s/define('FORCE_SSL_ADMIN'.*/define('FORCE_SSL_ADMIN', true);/" "$cfg"
    else
      echo "define('FORCE_SSL_ADMIN', true);" >> "$cfg"
    fi
  fi

  chmod 600 "$cfg"
  log_info "Đã harden wp-config.php (DISALLOW_FILE_EDIT, FORCE_SSL_ADMIN tuỳ chọn)."
}

wpsec_create_mu_security_plugins() {
  local dir="$1/wp-content/mu-plugins"
  mkdir -p "$dir"

  # Disable XMLRPC (nếu chưa)
  cat > "${dir}/disable-xmlrpc-nguyendc.php" <<'EOF'
<?php
/*
Plugin Name: Disable XML-RPC (nguyendc-ols)
*/
add_filter('xmlrpc_enabled', '__return_false');
EOF

  # Block REST user enumeration
  cat > "${dir}/block-rest-users-nguyendc.php" <<'EOF'
<?php
/*
Plugin Name: Block REST Users (nguyendc-ols)
*/
add_filter('rest_endpoints', function ($endpoints) {
    unset($endpoints['/wp/v2/users']);
    unset($endpoints['/wp/v2/users/(?P<id>[\d]+)']);
    return $endpoints;
});
EOF

  # Hide WP version
  cat > "${dir}/hide-wp-version-nguyendc.php" <<'EOF'
<?php
/*
Plugin Name: Hide WP Version (nguyendc-ols)
*/
remove_action('wp_head', 'wp_generator');
add_filter('the_generator', '__return_empty_string');
EOF

  log_info "Đã tạo MU-plugins security (disable XMLRPC, block REST users, hide version)."
}

wpsec_fix_permissions() {
  local dir="$1"
  chown -R www-data:www-data "$dir"
  find "$dir" -type d -exec chmod 755 {} \;
  find "$dir" -type f -exec chmod 644 {} \;
  [[ -f "$dir/wp-config.php" ]] && chmod 600 "$dir/wp-config.php"
  log_info "Đã siết quyền file cho site."
}

wpsec_list_sites() {
  echo "Các site WordPress phát hiện trong ${WP_BASE_DIR}:"
  find "$WP_BASE_DIR" -maxdepth 4 -type f -name "wp-config.php" 2>/dev/null
}

wpsec_secure_site_flow() {
  read -r -p "Nhập path thư mục WordPress (VD: /var/www/example.com): " dir
  [[ ! -d "$dir" ]] && { log_error "Thư mục không tồn tại."; return 1; }
  wpsec_is_wp_dir "$dir" || { log_error "Thư mục không phải WordPress."; return 1; }

  local domain
  read -r -p "Nhập domain (VD: example.com): " domain
  [[ -z "$domain" ]] && domain="$(basename "$dir")"

  wpsec_harden_wp_config "$dir"
  wpsec_create_mu_security_plugins "$dir"
  wpsec_fix_permissions "$dir"
  wpsec_nginx_security_snippet "$domain"

  read -r -p "Thiết lập Fail2ban cho wp-login.php? (y/N): " fa
  [[ "$fa" == "y" || "$fa" == "Y" ]] && wpsec_setup_fail2ban

  log_info "Hoàn tất hardening & firewall cho site WordPress: ${domain}"
}

wpsec_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "      WordPress Security Firewall (Plugin)"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "1) Harden & firewall cho 1 site WordPress"
    echo "2) Tạo/cập nhật Nginx security snippet cho domain"
    echo "3) Thiết lập Fail2ban cho wp-login.php"
    echo "4) Liệt kê site WordPress"
    echo "0) Quay lại"
    echo
    read -rp "Chọn: " c
    case "$c" in
      1) wpsec_secure_site_flow; read -rp "Enter để tiếp tục..." ;;
      2) read -rp "Domain: " d; wpsec_nginx_security_snippet "$d"; read -rp "Enter..." ;;
      3) wpsec_setup_fail2ban; read -rp "Enter..." ;;
      4) wpsec_list_sites; read -rp "Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh wpsec secure|list
wpsec_cli() {
  case "$1" in
    secure) wpsec_secure_site_flow ;;
    list)   wpsec_list_sites ;;
    *) 
      echo "WP Security CLI:"
      echo "  wpsec secure  - harden + firewall 1 site"
      echo "  wpsec list    - liệt kê site"
      ;;
  esac
}

ndc_register_plugin \
  "wpsec" \
  "WordPress Security Firewall" \
  "SEC" \
  "Hardening + Nginx rules + Fail2ban cho WordPress" \
  "wpsec_menu"
