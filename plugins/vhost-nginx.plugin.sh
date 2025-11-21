#!/usr/bin/env bash

# ======================================
# Plugin: Nginx VHost Manager
# Project: nguyendc-ols
# ID: vhost
# Category: WEB
# ======================================

VHOST_STATE_KEY="VHOST_MANAGER_ENABLED"

VHOST_SITES_AVAILABLE="/etc/nginx/sites-available"
VHOST_SITES_ENABLED="/etc/nginx/sites-enabled"
VHOST_WEBROOT_BASE="/var/www"

vhost_nginx_check_nginx() {
  if ! command -v nginx >/dev/null 2>&1; then
    log_error "Nginx chưa được cài. Hãy cài plugin 'nginx' trước."
    return 1
  fi
  return 0
}

vhost_create() {
  vhost_nginx_check_nginx || return 1

  read -r -p "Nhập domain (VD: example.com): " domain
  if [[ -z "$domain" ]]; then
    log_error "Domain không được để trống."
    return 1
  fi

  read -r -p "Nhập đường dẫn web root (mặc định: ${VHOST_WEBROOT_BASE}/${domain}): " webroot
  webroot="${webroot:-${VHOST_WEBROOT_BASE}/${domain}}"

  mkdir -p "$webroot"
  chown -R www-data:www-data "$webroot" 2>/dev/null || true

  local conf="${VHOST_SITES_AVAILABLE}/${domain}.conf"
  mkdir -p "$VHOST_SITES_AVAILABLE" "$VHOST_SITES_ENABLED"

  cat > "$conf" <<EOF
server {
    listen 80;
    server_name ${domain};

    root ${webroot};
    index index.html index.htm index.php;

    access_log /var/log/nginx/${domain}_access.log;
    error_log  /var/log/nginx/${domain}_error.log;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

  ln -sf "$conf" "${VHOST_SITES_ENABLED}/${domain}.conf"

  # Thêm include vào nginx.conf nếu chưa có
  if ! grep -q "$VHOST_SITES_ENABLED" /etc/nginx/nginx.conf 2>/dev/null; then
    log_info "Thêm include sites-enabled vào /etc/nginx/nginx.conf"
    sed -i "/http {/a \    include ${VHOST_SITES_ENABLED}/*;" /etc/nginx/nginx.conf
  fi

  nginx -t || {
    log_error "Cấu hình Nginx lỗi. Huỷ kích hoạt vhost này."
    rm -f "${VHOST_SITES_ENABLED}/${domain}.conf"
    return 1
  }

  systemctl reload nginx
  log_info "Đã tạo vhost cho domain ${domain}, webroot: ${webroot}"
}

vhost_delete() {
  vhost_nginx_check_nginx || return 1

  read -r -p "Nhập domain cần xoá vhost: " domain
  if [[ -z "$domain" ]]; then
    log_error "Domain không được để trống."
    return 1
  fi

  local conf_a="${VHOST_SITES_AVAILABLE}/${domain}.conf"
  local conf_e="${VHOST_SITES_ENABLED}/${domain}.conf"

  if [[ ! -f "$conf_a" && ! -f "$conf_e" ]]; then
    log_error "Không tìm thấy file cấu hình cho domain này."
    return 1
  fi

  rm -f "$conf_a" "$conf_e"

  nginx -t && systemctl reload nginx

  log_info "Đã xoá vhost cho domain ${domain}."
}

vhost_list() {
  echo "Danh sách vhost (sites-available):"
  ls -1 "${VHOST_SITES_AVAILABLE}" 2>/dev/null || echo "  (Không có)"
  echo
  echo "Danh sách vhost (sites-enabled):"
  ls -1 "${VHOST_SITES_ENABLED}" 2>/dev/null || echo "  (Không có)"
}

vhost_show_status_line() {
  if command -v nginx >/dev/null 2>&1; then
    echo "✅ Nginx đã cài - Vhost manager sẵn sàng"
  else
    echo "❌ Nginx chưa cài"
  fi
}

vhost_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "         Quản lý Nginx VHost (Plugin)"
    echo "                nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    vhost_show_status_line
    echo
    echo "1) Tạo vhost mới (domain → webroot)"
    echo "2) Xoá vhost"
    echo "3) Liệt kê vhost"
    echo "4) Kiểm tra cấu hình Nginx (nginx -t)"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) vhost_create; read -rp "Nhấn Enter để tiếp tục..." ;;
      2) vhost_delete; read -rp "Nhấn Enter để tiếp tục..." ;;
      3) vhost_list;   read -rp "Nhấn Enter để tiếp tục..." ;;
      4) nginx -t;     read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "vhost" \
  "Nginx VHost" \
  "WEB" \
  "Tạo/Xoá/Quản lý Nginx virtual hosts (domain → webroot)" \
  "vhost_menu"
