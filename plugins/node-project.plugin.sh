#!/usr/bin/env bash
#
# ======================================
# Plugin: Node Project Tools
# Project: nguyendc-ols
# ID: nodeproj
# Category: NODE
# ======================================

NODE_APPS_CONF="/etc/nguyendc-ols/node-apps.conf"
NODE_BACKUP_DIR="/opt/nguyendc-ols/node-backups"

nodeproj_ensure_conf() {
  if [[ ! -f "$NODE_APPS_CONF" ]]; then
    log_warn "Chưa có ${NODE_APPS_CONF}. Hãy dùng Node App Manager để tạo app trước."
    return 1
  fi
  return 0
}

nodeproj_list_apps() {
  nodeproj_ensure_conf || return 1
  echo "Danh sách app Node:"
  echo "name | domain | dir | port"
  cat "$NODE_APPS_CONF"
}

nodeproj_select_app() {
  nodeproj_ensure_conf || return 1
  local name="$1"
  [[ -z "$name" ]] && read -r -p "Tên app (pm2 name): " name
  local line
  line=$(grep "^${name}|" "$NODE_APPS_CONF" || true)
  if [[ -z "$line" ]]; then
    log_error "Không tìm thấy app '${name}' trong ${NODE_APPS_CONF}"
    return 1
  fi
  echo "$line"
}

nodeproj_backup_app() {
  nodeproj_ensure_conf || return 1
  local name line domain dir port
  read -r -p "Tên app cần backup: " name
  line=$(nodeproj_select_app "$name") || return 1
  IFS='|' read -r n domain dir port <<< "$line"

  mkdir -p "$NODE_BACKUP_DIR"
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  local tarfile="${NODE_BACKUP_DIR}/${n}_${ts}.tar.gz"

  log_info "Backup app ${n} (dir=${dir}) -> ${tarfile}"
  tar -czf "$tarfile" -C "$(dirname "$dir")" "$(basename "$dir")"

  log_info "Đã backup xong."
}

nodeproj_list_backups() {
  mkdir -p "$NODE_BACKUP_DIR"
  echo "Node backups trong ${NODE_BACKUP_DIR}:"
  ls -lh "$NODE_BACKUP_DIR"
}

nodeproj_create_or_update_vhost() {
  local domain="$1"
  local port="$2"

  mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
  local file="/etc/nginx/sites-available/${domain}.conf"

  cat > "$file" <<EOF
server {
    listen 80;
    server_name ${domain};

    access_log /var/log/nginx/${domain}_access.log;
    error_log  /var/log/nginx/${domain}_error.log;

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

  ln -sf "$file" "/etc/nginx/sites-enabled/${domain}.conf"
  if ! grep -q "/etc/nginx/sites-enabled" /etc/nginx/nginx.conf 2>/dev/null; then
    sed -i "/http {/a \    include /etc/nginx/sites-enabled/*;" /etc/nginx/nginx.conf
  fi

  nginx -t && systemctl reload nginx
  log_info "Đã tạo/cập nhật vhost cho domain ${domain} -> port ${port}"
}

nodeproj_attach_domain() {
  nodeproj_ensure_conf || return 1
  local name line domain dir port
  read -r -p "Tên app: " name
  line=$(nodeproj_select_app "$name") || return 1
  IFS='|' read -r n old_domain dir port <<< "$line"

  read -r -p "Domain mới để gắn vào app này: " domain
  [[ -z "$domain" ]] && { log_error "Domain không được trống."; return 1; }

  # Cập nhật Nginx
  nodeproj_create_or_update_vhost "$domain" "$port"

  # Cập nhật NODE_APPS_CONF
  tmp=$(mktemp)
  awk -F'|' -v app="$name" -v nd="$domain" 'BEGIN{OFS="|"} $1==app {$2=nd} {print}' "$NODE_APPS_CONF" > "$tmp"
  mv "$tmp" "$NODE_APPS_CONF"

  log_info "Đã gắn domain ${domain} cho app ${name}."
}

nodeproj_change_domain() {
  nodeproj_ensure_conf || return 1
  local name line old_domain dir port
  read -r -p "Tên app: " name
  line=$(nodeproj_select_app "$name") || return 1
  IFS='|' read -r n old_domain dir port <<< "$line"

  echo "Domain cũ: ${old_domain}"
  read -r -p "Domain mới: " new_domain
  [[ -z "$new_domain" ]] && { log_error "Domain mới không được trống."; return 1; }

  # Cập nhật vhost (tạo mới cho domain mới, domain cũ bạn có thể xoá file thủ công nếu không dùng nữa)
  nodeproj_create_or_update_vhost "$new_domain" "$port"

  # Cập nhật NODE_APPS_CONF
  tmp=$(mktemp)
  awk -F'|' -v app="$name" -v nd="$new_domain" 'BEGIN{OFS="|"} $1==app {$2=nd} {print}' "$NODE_APPS_CONF" > "$tmp"
  mv "$tmp" "$NODE_APPS_CONF"

  log_info "Đã đổi domain ${old_domain} -> ${new_domain} cho app ${name}."
}

nodeproj_clone_app() {
  nodeproj_ensure_conf || return 1
  if ! command -v pm2 >/dev/null 2>&1; then
    log_error "PM2 chưa cài."
    return 1
  fi

  local src_name line src_domain src_dir src_port
  read -r -p "Tên app nguồn (pm2 name): " src_name
  line=$(nodeproj_select_app "$src_name") || return 1
  IFS='|' read -r n src_domain src_dir src_port <<< "$line"

  echo "App nguồn: ${src_name} (domain=${src_domain}, dir=${src_dir}, port=${src_port})"

  local new_name new_domain new_dir new_port
  read -r -p "Tên app mới (pm2 name mới): " new_name
  read -r -p "Domain mới: " new_domain
  read -r -p "Port nội bộ mới (VD: 3100): " new_port
  read -r -p "Path app mới (VD: /var/www/node/${new_name}): " new_dir

  [[ -z "$new_name" || -z "$new_domain" || -z "$new_port" || -z "$new_dir" ]] && {
    log_error "Thông tin không được trống."
    return 1
  }

  # Copy code
  log_info "Copy code từ ${src_dir} -> ${new_dir}"
  mkdir -p "$(dirname "$new_dir")"
  rsync -a "$src_dir"/ "$new_dir"/

  # Cập nhật PORT trong .env nếu có
  if [[ -f "${new_dir}/.env" ]]; then
    sed -i "s/^PORT=.*/PORT=${new_port}/" "${new_dir}/.env" || true
  fi

  # Tạo PM2 process mới
  cd "$new_dir" || return 1
  pm2 start index.js --name "$new_name" --cwd "$new_dir" --env production
  pm2 save

  # Tạo vhost mới
  nodeproj_create_or_update_vhost "$new_domain" "$new_port"

  # Thêm dòng mới vào NODE_APPS_CONF
  echo "${new_name}|${new_domain}|${new_dir}|${new_port}" >> "$NODE_APPS_CONF"

  log_info "Đã clone app ${src_name} -> ${new_name} (domain=${new_domain}, port=${new_port})."
}

nodeproj_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "            Node Project Tools (Plugin)"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "1) Liệt kê app Node"
    echo "2) Backup 1 app (tar.gz code)"
    echo "3) Xem danh sách backup"
    echo "4) Gắn domain vào app (tạo vhost)"
    echo "5) Đổi domain app"
    echo "6) Clone app sang domain khác (new port + new pm2)"
    echo "0) Quay lại"
    echo
    read -rp "Chọn: " c
    case "$c" in
      1) nodeproj_list_apps;      read -rp "Enter..." ;;
      2) nodeproj_backup_app;     read -rp "Enter..." ;;
      3) nodeproj_list_backups;   read -rp "Enter..." ;;
      4) nodeproj_attach_domain;  read -rp "Enter..." ;;
      5) nodeproj_change_domain;  read -rp "Enter..." ;;
      6) nodeproj_clone_app;      read -rp "Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh nodeproj backup|clone|attach|changedomain
nodeproj_cli() {
  case "$1" in
    backup)       nodeproj_backup_app ;;
    clone)        nodeproj_clone_app ;;
    attach)       nodeproj_attach_domain ;;
    changedomain) nodeproj_change_domain ;;
    list|"")      nodeproj_list_apps ;;
    *)
      echo "Node Project CLI:"
      echo "  nodeproj list          - liệt kê app"
      echo "  nodeproj backup        - backup 1 app"
      echo "  nodeproj clone         - clone app sang domain mới"
      echo "  nodeproj attach        - gắn domain"
      echo "  nodeproj changedomain  - đổi domain"
      ;;
  esac
}

ndc_register_plugin \
  "nodeproj" \
  "Node Project Tools" \
  "NODE" \
  "Backup app Node, gắn/đổi/copy domain, clone app sang domain mới" \
  "nodeproj_menu"
