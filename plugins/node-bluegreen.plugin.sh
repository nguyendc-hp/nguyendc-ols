#!/usr/bin/env bash
#
# ======================================
# Plugin: Node Blue-Green Deploy
# Project: nguyendc-ols
# ID: nodebg
# Category: NODE
# ======================================

NODE_BG_CONF="/etc/nguyendc-ols/node-bluegreen.conf"

nodebg_ensure_conf() {
  mkdir -p "$(dirname "$NODE_BG_CONF")"
  [[ -f "$NODE_BG_CONF" ]] || touch "$NODE_BG_CONF"
}

nodebg_require_pm2() {
  if ! command -v pm2 >/dev/null 2>&1; then
    log_error "PM2 chưa cài."
    return 1
  fi
}

nodebg_add_config() {
  nodebg_ensure_conf
  local name domain dir blue_port green_port active
  read -r -p "Tên logical app (VD: api-mivn): " name
  read -r -p "Domain: " domain
  read -r -p "Path app (VD: /var/www/node/api-mivn): " dir
  read -r -p "Blue port (VD: 3000): " blue_port
  read -r -p "Green port (VD: 4000): " green_port

  active="blue"

  echo "${name}|${domain}|${dir}|${blue_port}|${green_port}|${active}" >> "$NODE_BG_CONF"
  log_info "Đã thêm cấu hình blue/green cho ${name}."
}

nodebg_find() {
  local name="$1"
  nodebg_ensure_conf
  grep "^${name}|" "$NODE_BG_CONF" || true
}

nodebg_list() {
  nodebg_ensure_conf
  echo "Danh sách cấu hình blue/green:"
  echo "name | domain | dir | blue | green | active"
  cat "$NODE_BG_CONF"
}

nodebg_nginx_config() {
  local name="$1" domain="$2" blue_port="$3" green_port="$4" active="$5"
  local file="/etc/nginx/sites-available/${domain}.conf"

  mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

  cat > "$file" <<EOF
# Blue-Green config cho ${name}
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''      close;
}

upstream ${name}_blue {
    server 127.0.0.1:${blue_port};
}

upstream ${name}_green {
    server 127.0.0.1:${green_port};
}

# Chọn upstream active qua variable
map \$bg_upstream \$node_upstream {
    default ${name}_${active};
}

server {
    listen 80;
    server_name ${domain};

    access_log /var/log/nginx/${domain}_access.log;
    error_log  /var/log/nginx/${domain}_error.log;

    location / {
        proxy_pass http://\$node_upstream;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header Host \$host;
    }
}
EOF

  ln -sf "$file" "/etc/nginx/sites-enabled/${domain}.conf"
  if ! grep -q "/etc/nginx/sites-enabled" /etc/nginx/nginx.conf 2>/dev/null; then
    sed -i "/http {/a \    include /etc/nginx/sites-enabled/*;" /etc/nginx/nginx.conf
  fi

  nginx -t && systemctl reload nginx
  log_info "Đã cập nhật Nginx blue/green cho ${domain} (active=${active})."
}

nodebg_start_processes() {
  nodebg_require_pm2 || return 1
  local name="$1" dir="$2" blue_port="$3" green_port="$4"

  cd "$dir" || return 1
  # app-blue
  PORT="$blue_port" pm2 start index.js --name "${name}-blue" --cwd "$dir" --env production
  # app-green
  PORT="$green_port" pm2 start index.js --name "${name}-green" --cwd "$dir" --env production

  pm2 save
}

nodebg_init() {
  nodebg_require_pm2 || return 1
  nodebg_add_config

  # Lấy dòng vừa thêm (cuối file)
  line=$(tail -n1 "$NODE_BG_CONF")
  IFS='|' read -r name domain dir blue_port green_port active <<< "$line"

  nodebg_start_processes "$name" "$dir" "$blue_port" "$green_port"
  nodebg_nginx_config "$name" "$domain" "$blue_port" "$green_port" "$active"

  log_info "Khởi tạo blue/green cho ${name} xong. Đang dùng BLUE."
}

nodebg_switch() {
  nodebg_require_pm2 || return 1

  read -r -p "Tên logical app (VD: api-mivn): " name
  line=$(nodebg_find "$name")
  [[ -z "$line" ]] && { log_error "Không tìm thấy cấu hình."; return 1; }

  IFS='|' read -r oname domain dir blue_port green_port active <<< "$line"
  local new_active
  if [[ "$active" == "blue" ]]; then
    new_active="green"
  else
    new_active="blue"
  fi

  # Update file conf
  tmp=$(mktemp)
  awk -F'|' -v n="$name" -v na="$new_active" \
    'BEGIN{OFS="|"} $1==n {$6=na} {print}' \
    "$NODE_BG_CONF" > "$tmp"
  mv "$tmp" "$NODE_BG_CONF"

  nodebg_nginx_config "$name" "$domain" "$blue_port" "$green_port" "$new_active"

  log_info "Đã switch ${name}: ${active} -> ${new_active}"
}

nodebg_status() {
  nodebg_require_pm2 || return 1
  nodebg_list
  echo
  echo "PM2 process:"
  pm2 ls | grep -E "blue|green" || true
}

nodebg_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "         Node Blue-Green Deploy (Plugin)"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "1) Khởi tạo blue/green cho 1 app (blue+green port)"
    echo "2) Switch BLUE <-> GREEN"
    echo "3) Xem status"
    echo "0) Quay lại"
    echo
    read -rp "Chọn: " c
    case "$c" in
      1) nodebg_init;   read -rp "Enter..." ;;
      2) nodebg_switch; read -rp "Enter..." ;;
      3) nodebg_status; read -rp "Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh nodebg init|switch|status
nodebg_cli() {
  case "$1" in
    init)   nodebg_init ;;
    switch) nodebg_switch ;;
    status|"") nodebg_status ;;
    *)
      echo "Node BlueGreen CLI:"
      echo "  nodebg init      - tạo cấu hình blue/green"
      echo "  nodebg switch    - chuyển blue <-> green"
      echo "  nodebg status    - xem status"
      ;;
  esac
}

ndc_register_plugin \
  "nodebg" \
  "Node Blue-Green Deploy" \
  "NODE" \
  "Triển khai blue/green cho Node app, switch không downtime" \
  "nodebg_menu"
