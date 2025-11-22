#!/usr/bin/env bash
#
# ======================================
# Plugin: WordPress SpeedPack (WP Booster)
# Project: nguyendc-ols
# ID: wpspeed
# Category: WORDPRESS
# ======================================

WP_BASE_DIR="/var/www"

# ————————————————————————————
# Helper: Kiểm tra thư mục có phải WP không
# ————————————————————————————
wps_is_wp_dir() {
  local dir="$1"
  [[ -f "$dir/wp-config.php" && -d "$dir/wp-includes" ]]
}

wps_detect_sites() {
  find "$WP_BASE_DIR" -maxdepth 4 -type f -name "wp-config.php" 2>/dev/null
}

# ————————————————————————————
# Tự tạo MU-plugin tối ưu WordPress
# ————————————————————————————
wps_create_mu_plugin() {
  local dir="$1/wp-content/mu-plugins"
  mkdir -p "$dir"

  cat > "${dir}/nguyendc-ols-speedpack.php" <<'EOF'
<?php
/*
Plugin Name: SpeedPack Booster (nguyendc-ols)
Description: Speed optimizations for WordPress (disable emojis, embeds, heartbeat, etc.)
Author: nguyendc-ols
*/

add_action('init', function() {
    // Disable emojis
    remove_action('wp_head', 'print_emoji_detection_script', 7);
    remove_action('wp_print_styles', 'print_emoji_styles');

    // Disable embeds
    remove_action('wp_head', 'wp_oembed_add_discovery_links');
    remove_action('wp_head', 'wp_oembed_add_host_js');

    // Disable REST API links
    remove_action('wp_head', 'rest_output_link_wp_head');

    // Disable shortlink
    remove_action('wp_head', 'wp_shortlink_wp_head');

    // Disable generator meta tag
    remove_action('wp_head', 'wp_generator');
});

// Disable Heartbeat (reduce CPU)
add_filter( 'heartbeat_settings', function( $settings ) {
    $settings['interval'] = 60; // giảm tần suất
    return $settings;
});
EOF
}

# ————————————————————————————
# Tối ưu wp-config.php
# ————————————————————————————
wps_optimize_wpconfig() {
  local cfg="$1/wp-config.php"
  [[ ! -f "$cfg" ]] && return

  cp "$cfg" "${cfg}.bak.$(date +%Y%m%d-%H%M%S)"

  # Bật cache
  if grep -q "WP_CACHE" "$cfg"; then
    sed -i "s/define('WP_CACHE'.*/define('WP_CACHE', true);/" "$cfg"
  else
    echo "define('WP_CACHE', true);" >> "$cfg"
  fi

  # Tối ưu hạn mức
  sed -i "s/define('WP_MEMORY_LIMIT'.*/define('WP_MEMORY_LIMIT','256M');/" "$cfg" 2>/dev/null
  sed -i "s/define('WP_MAX_MEMORY_LIMIT'.*/define('WP_MAX_MEMORY_LIMIT','256M');/" "$cfg" 2>/dev/null

  # Revisions
  if ! grep -q "WP_POST_REVISIONS" "$cfg"; then
    echo "define('WP_POST_REVISIONS', 5);" >> "$cfg"
  fi

  echo "define('AUTOSAVE_INTERVAL', 120);" >> "$cfg"
  echo "define('EMPTY_TRASH_DAYS', 7);" >> "$cfg"

  chmod 600 "$cfg"
}

# ————————————————————————————
# Tạo file cấu hình Nginx cache tối ưu
# ————————————————————————————
wps_nginx_cache_config() {
  local domain="$1"
  local file="/etc/nginx/conf.d/${domain}_cache.conf"

  cat > "$file" <<EOF
# =============================
# Nginx Cache for WordPress
# Created by nguyendc-ols SpeedPack
# =============================

fastcgi_cache_path /var/cache/nginx/${domain} levels=1:2 keys_zone=${domain}cache:100m inactive=60m use_temp_path=off;

map \$request_method \$wp_is_cacheable {
    GET 1;
    HEAD 1;
    POST 0;
}

server {
    set \$skip_cache 0;

    if (\$request_uri ~* "/wp-admin/|/xmlrpc.php|/wp-login.php") {
        set \$skip_cache 1;
    }

    if (\$http_cookie ~* "comment_author|wordpress_[a-z0-9]+|wp-postpass") {
        set \$skip_cache 1;
    }

    location ~ \.php\$ {
        fastcgi_pass unix:/run/php/php-fpm.sock;
        include fastcgi_params;

        fastcgi_cache_bypass \$skip_cache;
        fastcgi_no_cache \$skip_cache;
        fastcgi_cache ${domain}cache;
        fastcgi_cache_valid 200 60m;
    }
}
EOF

  systemctl reload nginx
  log_info "Đã tạo Nginx cache config: ${file}"
}

# ————————————————————————————
# Kích hoạt Redis Object Cache (nếu có Redis)
# ————————————————————————————
wps_enable_redis_cache() {
  local dir="$1"
  local plugin_dir="${dir}/wp-content/plugins/redis-cache"

  if [[ ! -d "$plugin_dir" ]]; then
    read -r -p "Plugin Redis Cache chưa có. Tải & cài đặt? (y/N): " a
    [[ "$a" != "y" && "$a" != "Y" ]] && return 0

    mkdir -p "$plugin_dir"
    wget -q https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip -O /tmp/redis.zip
    unzip -q /tmp/redis.zip -d "${dir}/wp-content/plugins/"
  fi

  # Tạo mu-plugin auto enable Redis
  cat > "${dir}/wp-content/mu-plugins/redis-enable.php" <<'EOF'
<?php
/*
Plugin Name: Redis Auto Enable (nguyendc-ols)
*/

if (function_exists('wp_cache_supports') && wp_cache_supports('redis')) {
    if (function_exists('wp_cache_enable')) {
        wp_cache_enable();
    }
}
EOF

  log_info "Đã kích hoạt Redis Object Cache (mức hệ thống)."
}

# ————————————————————————————
# Tối ưu quyền và folder
# ————————————————————————————
wps_fix_permissions() {
  local dir="$1"
  chown -R www-data:www-data "$dir"
  find "$dir" -type d -exec chmod 755 {} \;
  find "$dir" -type f -exec chmod 644 {} \;
  chmod 600 "$dir/wp-config.php"
}

# ————————————————————————————
# Benchmark tốc độ trang
# ————————————————————————————
wps_benchmark() {
  local url="$1"
  echo "Running speed test for ${url}..."
  curl -o /dev/null -s -w "DNS Lookup: %{time_namelookup}\nConnect: %{time_connect}\nStart Transfer: %{time_starttransfer}\nTotal: %{time_total}\n" "$url"
}

# ————————————————————————————
# Quy trình tối ưu full cho 1 site WordPress
# ————————————————————————————
wps_optimize_site() {
  read -r -p "Nhập đường dẫn site WP (VD: /var/www/example.com): " dir
  [[ ! -d "$dir" ]] && { log_error "Sai thư mục."; return; }

  wps_is_wp_dir "$dir" || { log_error "Không phải WordPress."; return; }

  # lấy domain
  local domain
  domain=$(basename "$dir")

  echo "💨 Benchmark BEFORE:"
  wps_benchmark "http://${domain}"

  wps_create_mu_plugin "$dir"
  wps_optimize_wpconfig "$dir"
  wps_fix_permissions "$dir"
  wps_nginx_cache_config "$domain"

  read -r -p "Có kích hoạt Redis Object Cache không? (y/N): " rr
  [[ "$rr" == "y" || "$rr" == "Y" ]] && wps_enable_redis_cache "$dir"

  echo "💨 Benchmark AFTER:"
  wps_benchmark "http://${domain}"

  log_info "Hoàn tất SpeedPack cho WordPress: ${domain}"
}

wps_list_sites() {
  echo "Các site WordPress phát hiện:"
  wps_detect_sites
}

# ————————————————————————————
# MENU
# ————————————————————————————
wps_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "         WordPress SpeedPack (Plugin)"
    echo "              nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "1) Tối ưu tốc độ cho 1 site WordPress"
    echo "2) Kích hoạt Redis Object Cache"
    echo "3) Tạo MU-plugin SpeedPack"
    echo "4) Liệt kê các site WordPress"
    echo "0) Quay lại"
    echo
    read -rp "Chọn: " c

    case "$c" in
      1) wps_optimize_site;        read -rp "Enter để tiếp tục..." ;;
      2) wps_enable_redis_cache;   read -rp "Enter..." ;;
      3) 
         read -rp "Path WP: " p
         wps_create_mu_plugin "$p"
         ;;
      4) wps_list_sites;           read -rp "Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ." ;;
    esac
  done
}

# ————————————————————————————
# CLI SUPPORT
# ————————————————————————————
wpspeed_cli() {
  case "$1" in
    optimize) wps_optimize_site ;;
    list)     wps_list_sites ;;
    *)
      echo "WP SpeedPack CLI:"
      echo "  wpspeed optimize - tối ưu WP"
      echo "  wpspeed list     - liệt kê site"
      ;;
  esac
}

ndc_register_plugin \
  "wpspeed" \
  "WordPress SpeedPack" \
  "WP_OPTIMIZE" \
  "" \
  "wps_menu"
