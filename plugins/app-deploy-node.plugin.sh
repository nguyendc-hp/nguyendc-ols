#!/usr/bin/env bash

# ======================================
# Plugin: Node/React App Deploy
# Project: nguyendc-ols
# ID: appnode
# Category: APP
# ======================================

APP_BASE_DIR="/var/www/apps"

appnode_check_prereq() {
  if ! command -v node >/dev/null 2>&1; then
    log_error "Node.js chưa được cài. Hãy dùng plugin 'nodejs' để cài Node.js + PM2."
    return 1
  fi

  if ! command -v pm2 >/dev/null 2>&1; then
    log_error "PM2 chưa được cài. Hãy dùng plugin 'nodejs' để cài."
    return 1
  fi

  if ! command -v nginx >/dev/null 2>&1; then
    log_error "Nginx chưa được cài. Hãy dùng plugin 'nginx' để cài đặt web server."
    return 1
  fi

  return 0
}

appnode_deploy() {
  appnode_check_prereq || return 1

  mkdir -p "$APP_BASE_DIR"

  read -r -p "Nhập tên app (VD: myapp): " app_name
  if [[ -z "$app_name" ]]; then
    log_error "Tên app không được để trống."
    return 1
  fi

  read -r -p "Nhập git repo URL (VD: https://github.com/user/repo.git): " git_url
  if [[ -z "$git_url" ]]; then
    log_error "Git repo URL không được để trống."
    return 1
  fi

  read -r -p "Nhập domain cho app (VD: app.example.com): " domain
  if [[ -z "$domain" ]]; then
    log_error "Domain không được để trống."
    return 1
  fi

  local app_dir="${APP_BASE_DIR}/${app_name}"

  if [[ -d "$app_dir" ]]; then
    log_warn "Thư mục app đã tồn tại: ${app_dir}. Sẽ dùng lại thư mục này."
  else
    git clone "$git_url" "$app_dir" || {
      log_error "Git clone thất bại."
      return 1
    }
  fi

  cd "$app_dir" || {
    log_error "Không thể cd vào thư mục app: ${app_dir}"
    return 1
  }

  # Cài dependencies
  if [[ -f package.json ]]; then
    log_info "Cài đặt npm dependencies..."
    npm install || {
      log_error "npm install thất bại."
      return 1
    }
  else
    log_warn "Không tìm thấy package.json. Bạn cần cấu hình app Node/React thủ công."
  fi

  # Hỏi file entry cho PM2
  read -r -p "Nhập file entry cho PM2 (mặc định: server.js): " entry
  entry="${entry:-server.js}"

  if [[ ! -f "$entry" ]]; then
    log_warn "Không tìm thấy file ${entry}. Bạn sẽ cần tự cấu hình PM2 sau."
  else
    pm2 start "$entry" --name "$app_name"
    pm2 save
    log_info "Đã start app bằng PM2 với name: ${app_name}"
  fi

  # Tạo vhost Nginx đơn giản proxy tới app Node (giả sử app chạy port 3000)
  read -r -p "Nhập port app Node đang listen (mặc định: 3000): " app_port
  app_port="${app_port:-3000}"

  local conf="/etc/nginx/sites-available/${domain}.conf"
  mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

  cat > "$conf" <<EOF
server {
    listen 80;
    server_name ${domain};

    access_log /var/log/nginx/${domain}_access.log;
    error_log  /var/log/nginx/${domain}_error.log;

    location / {
        proxy_pass http://127.0.0.1:${app_port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

  ln -sf "$conf" "/etc/nginx/sites-enabled/${domain}.conf"

  # Ensure include sites-enabled in nginx.conf
  if ! grep -q "/etc/nginx/sites-enabled" /etc/nginx/nginx.conf 2>/dev/null; then
    log_info "Thêm include sites-enabled vào /etc/nginx/nginx.conf"
    sed -i "/http {/a \    include /etc/nginx/sites-enabled/*;" /etc/nginx/nginx.conf
  fi

  nginx -t || {
    log_error "Cấu hình Nginx lỗi. Huỷ kích hoạt vhost này."
    rm -f "/etc/nginx/sites-enabled/${domain}.conf"
    return 1
  }

  systemctl reload nginx
  log_info "Deploy app Node/React hoàn tất:"
  log_info " - App name: ${app_name}"
  log_info " - Thư mục: ${app_dir}"
  log_info " - Domain : http://${domain}"
}

appnode_list() {
  mkdir -p "$APP_BASE_DIR"
  echo "Danh sách app trong ${APP_BASE_DIR}:"
  ls -1 "$APP_BASE_DIR" 2>/dev/null || echo "  (Không có)"
  echo
  echo "Danh sách process PM2:"
  pm2 list || true
}

appnode_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "       Deploy App Node/React (Plugin)"
    echo "                nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "Base dir: ${APP_BASE_DIR}"
    echo
    echo "1) Deploy app mới (git clone + PM2 + Nginx)"
    echo "2) Xem danh sách app / PM2"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) appnode_deploy; read -rp "Nhấn Enter để tiếp tục..." ;;
      2) appnode_list;   read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "appnode" \
  "Deploy Node/React App" \
  "APP" \
  "Triển khai app Node/React với PM2 + Nginx (git clone → chạy)" \
  "appnode_menu"
