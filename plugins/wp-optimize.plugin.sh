#!/usr/bin/env bash

# ======================================
# Plugin: Tối ưu & bảo mật WordPress
# Category: WP_OPTIMIZE  
# ======================================

wp_optimize_speed() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Tối ưu tốc độ WordPress"
  echo "══════════════════════════════════════════════"
  echo " 1) Cache/page cache"
  echo " 2) Object cache (Redis)"
  echo " 3) Gzip/Brotli"
  echo " 4) Tối ưu ảnh"
  echo " 0) Quay lại"
  
  read -rp "Chọn: " choice
  case "$choice" in
    1) log_info "Cài plugin cache (thủ công qua WordPress admin)" ;;
    2) log_info "Cấu hình Redis object cache..." ;;
    3) log_info "Bật Gzip/Brotli trong Nginx..." ;;
    4) log_info "Tối ưu ảnh (cài plugin image optimizer)" ;;
  esac
}

wp_optimize_db() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Tối ưu DB WordPress"
  echo "══════════════════════════════════════════════"
  
  read -rp "Nhập database name: " db_name
  
  if [[ -z "$db_name" ]]; then
    log_error "Database name không được để trống."
    return 1
  fi
  
  log_info "Đang cleanup revisions, trash, transients..."
  
  mysql -uroot "$db_name" <<'EOF'
DELETE FROM wp_posts WHERE post_type = 'revision';
DELETE FROM wp_posts WHERE post_status = 'trash';
DELETE FROM wp_options WHERE option_name LIKE '%_transient_%';
OPTIMIZE TABLE wp_posts;
OPTIMIZE TABLE wp_options;
EOF
  
  log_success "Đã tối ưu database WordPress."
}

wp_install_plugins() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Cài plugin đề xuất"
  echo "══════════════════════════════════════════════"
  
  echo "Plugin đề xuất:"
  echo " - Performance: WP Rocket, LiteSpeed Cache, W3 Total Cache"
  echo " - Security: Wordfence, iThemes Security, All In One WP Security"
  echo " - Backup: UpdraftPlus, BackWPup"
  echo " - SEO: Yoast SEO, Rank Math"
  echo
  echo "Vui lòng cài thủ công qua WordPress admin."
}

wp_security_config() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Cấu hình bảo mật WordPress"
  echo "══════════════════════════════════════════════"
  
  read -rp "Nhập thư mục WordPress: " wp_dir
  
  if [[ ! -d "$wp_dir" ]]; then
    log_error "Thư mục không tồn tại."
    return 1
  fi
  
  local cfg="${wp_dir}/wp-config.php"
  
  # Disable XML-RPC
  mkdir -p "${wp_dir}/wp-content/mu-plugins"
  cat > "${wp_dir}/wp-content/mu-plugins/disable-xmlrpc.php" <<'EOF'
<?php
add_filter('xmlrpc_enabled', '__return_false');
EOF
  
  # Disable file edit
  if ! grep -q "DISALLOW_FILE_EDIT" "$cfg"; then
    echo "define('DISALLOW_FILE_EDIT', true);" >> "$cfg"
  fi
  
  # Hide version
  cat > "${wp_dir}/wp-content/mu-plugins/hide-version.php" <<'EOF'
<?php
remove_action('wp_head', 'wp_generator');
EOF
  
  chmod 600 "$cfg"
  
  log_success "Đã cấu hình bảo mật WordPress."
}

wp_optimize_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "      Tối ưu & bảo mật WordPress"
    echo "══════════════════════════════════════════════"
    echo " 1) Tối ưu tốc độ"
    echo " 2) Tối ưu DB WordPress"
    echo " 3) Cài plugin đề xuất (performance/security)"
    echo " 4) Cấu hình bảo mật WordPress"
    echo " 0) Quay lại"
    echo
    read -rp "Chọn chức năng: " choice
    
    case "$choice" in
      1) wp_optimize_speed; read -rp "Nhấn Enter..." ;;
      2) wp_optimize_db; read -rp "Nhấn Enter..." ;;
      3) wp_install_plugins; read -rp "Nhấn Enter..." ;;
      4) wp_security_config; read -rp "Nhấn Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "wp-optimize" \
  "Tối ưu & bảo mật WordPress" \
  "WP_OPTIMIZE" \
  "" \
  "wp_optimize_menu"
