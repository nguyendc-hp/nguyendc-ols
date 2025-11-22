#!/usr/bin/env bash

# ======================================
# Plugin: Quản lý ứng dụng Node.js
# Category: NODE
# ======================================

node_create_app() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Tạo app Node mới"
  echo "══════════════════════════════════════════════"
  
  echo "Chọn template:"
  echo " 1) Express"
  echo " 2) Next.js"
  echo " 3) Nuxt.js"
  echo " 0) Quay lại"
  
  read -rp "Lựa chọn: " choice
  
  case "$choice" in
    1) log_info "Tạo Express app..." ;;
    2) log_info "Tạo Next.js app..." ;;
    3) log_info "Tạo Nuxt.js app..." ;;
  esac
}

node_list_apps() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Danh sách app Node"
  echo "══════════════════════════════════════════════"
  
  if command -v pm2 >/dev/null 2>&1; then
    pm2 list
  else
    log_error "PM2 chưa được cài."
  fi
}

node_manage_pm2() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Start/Stop/Restart app (PM2)"
  echo "══════════════════════════════════════════════"
  
  echo " 1) Start app"
  echo " 2) Stop app"
  echo " 3) Restart app"
  echo " 4) Reload app"
  echo " 0) Quay lại"
  
  read -rp "Lựa chọn: " choice
  
  case "$choice" in
    1)
      read -rp "Nhập tên app: " app_name
      pm2 start "$app_name"
      ;;
    2)
      read -rp "Nhập tên app: " app_name
      pm2 stop "$app_name"
      ;;
    3)
      read -rp "Nhập tên app: " app_name
      pm2 restart "$app_name"
      ;;
    4)
      read -rp "Nhập tên app: " app_name
      pm2 reload "$app_name"
      ;;
  esac
}

node_assign_domain() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Gán / đổi domain cho app Node"
  echo "══════════════════════════════════════════════"
  
  read -rp "Nhập domain: " domain
  read -rp "Nhập port app: " port
  
  cat > "/etc/nginx/sites-available/${domain}.conf" <<EOF
server {
    listen 80;
    server_name ${domain};
    
    location / {
        proxy_pass http://127.0.0.1:${port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
  
  ln -sf "/etc/nginx/sites-available/${domain}.conf" "/etc/nginx/sites-enabled/${domain}.conf"
  nginx -t && systemctl reload nginx
  
  log_success "Đã gán domain $domain cho app port $port"
}

node_config_env() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Cấu hình port, env (dev/stage/prod)"
  echo "══════════════════════════════════════════════"
  
  read -rp "Nhập đường dẫn app: " app_dir
  
  if [[ ! -d "$app_dir" ]]; then
    log_error "Thư mục không tồn tại."
    return 1
  fi
  
  read -rp "Nhập NODE_ENV (development/staging/production): " node_env
  read -rp "Nhập PORT: " port
  
  cat > "${app_dir}/.env" <<EOF
NODE_ENV=${node_env}
PORT=${port}
EOF
  
  log_success "Đã cấu hình .env cho app."
}

node_bluegreen_deploy() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Blue/Green deploy (zero downtime)"
  echo "══════════════════════════════════════════════"
  
  log_info "Tính năng Blue/Green deploy - đang phát triển."
}

node_app_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "      Quản lý ứng dụng Node.js"
    echo "══════════════════════════════════════════════"
    echo " 1) Tạo app Node mới"
    echo " 2) Danh sách app Node"
    echo " 3) Start/Stop/Restart/Reload app (PM2)"
    echo " 4) Gán / đổi domain cho app Node"
    echo " 5) Cấu hình port, env (dev/stage/prod)"
    echo " 6) Blue/Green deploy (zero downtime)"
    echo " 0) Quay lại"
    echo
    read -rp "Chọn chức năng: " choice
    
    case "$choice" in
      1) node_create_app; read -rp "Nhấn Enter..." ;;
      2) node_list_apps; read -rp "Nhấn Enter..." ;;
      3) node_manage_pm2; read -rp "Nhấn Enter..." ;;
      4) node_assign_domain; read -rp "Nhấn Enter..." ;;
      5) node_config_env; read -rp "Nhấn Enter..." ;;
      6) node_bluegreen_deploy; read -rp "Nhấn Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "node-app" \
  "Quản lý ứng dụng Node.js" \
  "NODE" \
  "" \
  "node_app_menu"
