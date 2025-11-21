#!/usr/bin/env bash

# ======================================
# Plugin: PHP Manager
# Project: nguyendc-ols
# ID: php
# Category: RUNTIME
# ======================================

PHP_STATE_KEY="PHP_INSTALLED"

php_is_installed() {
  command -v php >/dev/null 2>&1
}

php_detect_fpm_service() {
  # Thử tìm service php-fpm hoặc phpX.Y-fpm
  local svc
  svc="$(systemctl list-unit-files | awk '/php.*fpm\.service/ {print $1}' | head -n1)"
  if [[ -n "$svc" ]]; then
    echo "$svc"
  else
    echo "php-fpm.service"
  fi
}

php_detect_version_short() {
  if ! php_is_installed; then
    echo ""
    return
  fi
  php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || php -v | head -n1 | awk '{print $2}' | cut -d'.' -f1-2
}

php_paths_init() {
  PHP_VER_SHORT="$(php_detect_version_short)"
  if [[ -z "$PHP_VER_SHORT" ]]; then
    PHP_FPM_INI=""
    PHP_CLI_INI=""
    PHP_FPM_POOL_DIR=""
    PHP_FPM_SERVICE="$(php_detect_fpm_service)"
    return
  fi

  if [[ -d "/etc/php/${PHP_VER_SHORT}" ]]; then
    PHP_FPM_INI="/etc/php/${PHP_VER_SHORT}/fpm/php.ini"
    PHP_CLI_INI="/etc/php/${PHP_VER_SHORT}/cli/php.ini"
    PHP_FPM_POOL_DIR="/etc/php/${PHP_VER_SHORT}/fpm/pool.d"
  else
    # fallback
    PHP_FPM_INI="/etc/php-fpm.d/php.ini"
    PHP_CLI_INI="/etc/php.ini"
    PHP_FPM_POOL_DIR="/etc/php-fpm.d"
  fi
  PHP_FPM_SERVICE="$(php_detect_fpm_service)"
}

php_install() {
  if php_is_installed; then
    log_info "PHP đã được cài đặt, bỏ qua bước cài."
    state_set "$PHP_STATE_KEY" "1"
    php_paths_init
    return 0
  fi

  log_info "Bắt đầu cài đặt PHP + extension cơ bản (WordPress / app PHP)..."

  if is_debian_like; then
    apt update
    apt install -y php php-fpm php-cli php-mysql php-xml php-curl php-gd php-mbstring php-zip php-intl php-bcmath
  elif is_rhel_like; then
    dnf install -y php php-fpm php-cli php-mysqlnd php-xml php-curl php-gd php-mbstring php-zip php-intl php-bcmath
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ cài PHP tự động."
    return 1
  fi

  if php_is_installed; then
    php_paths_init
    systemctl enable "$PHP_FPM_SERVICE" --now 2>/dev/null || true
    log_info "Cài đặt PHP thành công. Phiên bản: $(php -v | head -n1)"
    state_set "$PHP_STATE_KEY" "1"
  else
    log_error "PHP cài xong nhưng không chạy được."
    return 1
  fi
}

php_uninstall() {
  log_warn "Bạn sắp gỡ PHP. Thao tác này ảnh hưởng đến toàn bộ website/app PHP."
  read -r -p "Xác nhận (gõ YES_TO_REMOVE_PHP): " confirm
  if [[ "$confirm" != "YES_TO_REMOVE_PHP" ]]; then
    log_info "Đã huỷ thao tác gỡ PHP."
    return 0
  fi

  if is_debian_like; then
    apt purge -y "php*" php php-fpm php-cli php-mysql php-xml php-curl php-gd php-mbstring php-zip php-intl php-bcmath || true
    apt autoremove -y || true
  elif is_rhel_like; then
    dnf remove -y "php*" php php-fpm php-cli php-mysqlnd php-xml php-curl php-gd php-mbstring php-zip php-intl php-bcmath || true
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ gỡ PHP tự động."
    return 1
  fi

  state_set "$PHP_STATE_KEY" "0"
  log_info "Đã gỡ PHP (cần kiểm tra lại website/app PHP)."
}

php_show_info() {
  if ! php_is_installed; then
    echo "PHP chưa cài."
    return
  fi

  php_paths_init
  echo "===== PHP Info ====="
  php -v
  echo
  echo "PHP binary  : $(command -v php)"
  echo "PHP-FPM svc : ${PHP_FPM_SERVICE}"
  echo "php.ini CLI : ${PHP_CLI_INI}"
  echo "php.ini FPM : ${PHP_FPM_INI}"
  echo "FPM pool dir: ${PHP_FPM_POOL_DIR}"
  echo
  echo "Module nổi bật:"
  php -m | grep -E 'pdo|mysql|mysqli|curl|gd|mbstring|xml|intl|bcmath|zip' || true
}

php_backup_ini() {
  local ini="$1"
  if [[ -f "$ini" ]]; then
    cp "$ini" "${ini}.bak.$(date +%Y%m%d-%H%M%S)"
    log_info "Đã backup $ini."
  fi
}

php_optimize_php_ini() {
  php_paths_init
  if [[ -z "$PHP_FPM_INI" || ! -f "$PHP_FPM_INI" ]]; then
    log_error "Không tìm thấy php.ini FPM."
    return 1
  fi

  php_backup_ini "$PHP_FPM_INI"

  log_info "Áp dụng tối ưu cơ bản cho PHP (php.ini FPM)..."

  # Các giá trị an toàn/bền cho WordPress & app vừa
  local ini="$PHP_FPM_INI"

  # memory_limit, upload_max_filesize, post_max_size, max_execution_time
  sed -i 's/^memory_limit\s*=.*/memory_limit = 256M/' "$ini"
  sed -i 's/^upload_max_filesize\s*=.*/upload_max_filesize = 64M/' "$ini"
  sed -i 's/^post_max_size\s*=.*/post_max_size = 64M/' "$ini"
  sed -i 's/^max_execution_time\s*=.*/max_execution_time = 120/' "$ini"
  sed -i 's/^max_input_time\s*=.*/max_input_time = 120/' "$ini"

  # opcache bật
  if ! grep -q "^zend_extension=opcache" "$ini"; then
    cat >> "$ini" <<'EOF'

; === nguyendc-ols: OPcache optimize ===
zend_extension=opcache
opcache.enable=1
opcache.enable_cli=0
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=20000
opcache.validate_timestamps=1
opcache.revalidate_freq=2
opcache.fast_shutdown=1
EOF
  fi

  systemctl restart "$PHP_FPM_SERVICE" 2>/dev/null || true
  log_info "Đã tối ưu php.ini FPM và restart PHP-FPM."
}

php_optimize_fpm_pool() {
  php_paths_init
  if [[ -z "$PHP_FPM_POOL_DIR" || ! -d "$PHP_FPM_POOL_DIR" ]]; then
    log_error "Không tìm thấy thư mục FPM pool."
    return 1
  fi

  local pool="${PHP_FPM_POOL_DIR}/www.conf"
  if [[ ! -f "$pool" ]]; then
    log_error "Không tìm thấy pool www.conf."
    return 1
  fi

  php_backup_ini "$pool"

  # Tính sơ bộ theo RAM để gợi ý
  local mem_total_kb
  mem_total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  local mem_total_mb=$((mem_total_kb / 1024))
  local max_children

  if (( mem_total_mb <= 2048 )); then
    max_children=10
  elif (( mem_total_mb <= 4096 )); then
    max_children=20
  else
    max_children=40
  fi

  log_info "Tối ưu FPM pool (www.conf) theo RAM ~${mem_total_mb}MB, max_children ~${max_children}."

  sed -i 's/^pm\s*=.*/pm = dynamic/' "$pool"
  sed -i "s/^pm.max_children\s*=.*/pm.max_children = ${max_children}/" "$pool"
  sed -i "s/^pm.start_servers\s*=.*/pm.start_servers = $((max_children/4))/" "$pool"
  sed -i "s/^pm.min_spare_servers\s*=.*/pm.min_spare_servers = $((max_children/4))/" "$pool"
  sed -i "s/^pm.max_spare_servers\s*=.*/pm.max_spare_servers = $((max_children/2))/" "$pool"

  systemctl restart "$PHP_FPM_SERVICE" 2>/dev/null || true
  log_info "Đã tối ưu FPM pool & restart PHP-FPM."
}

php_show_status_line() {
  if php_is_installed; then
    echo "✅ PHP $(php_detect_version_short) (FPM: $(php_detect_fpm_service))"
  else
    echo "❌ PHP chưa cài"
  fi
}

php_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "             PHP Manager (Plugin)"
    echo "                nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    php_show_status_line
    echo
    echo "1) Cài đặt PHP + extension cơ bản"
    echo "2) Gỡ PHP"
    echo "3) Xem thông tin PHP / FPM"
    echo "4) Tối ưu php.ini (FPM) + OPcache"
    echo "5) Tối ưu PHP-FPM pool (www.conf)"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) php_install;             read -rp "Nhấn Enter để tiếp tục..." ;;
      2) php_uninstall;           read -rp "Nhấn Enter để tiếp tục..." ;;
      3) php_show_info;           read -rp "Nhấn Enter để tiếp tục..." ;;
      4) php_optimize_php_ini;    read -rp "Nhấn Enter để tiếp tục..." ;;
      5) php_optimize_fpm_pool;   read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh php info|optimize
php_cli() {
  local subcmd="$1"
  case "$subcmd" in
    info|"")
      php_show_info
      ;;
    optimize)
      php_optimize_php_ini
      php_optimize_fpm_pool
      ;;
    *)
      echo "PHP CLI:"
      echo "  php info       - hiển thị thông tin PHP"
      echo "  php optimize   - tối ưu php.ini + FPM pool"
      return 1
      ;;
  esac
}

ndc_register_plugin \
  "php" \
  "PHP Manager" \
  "RUNTIME" \
  "Cài đặt & tối ưu PHP-FPM cho WordPress/app PHP" \
  "php_menu"
