#!/usr/bin/env bash
#
# ======================================
# Plugin: Node App Manager
# Project: nguyendc-ols
# ID: nodeapp
# Category: NODE
# ======================================

NODE_APPS_CONF="/etc/nguyendc-ols/node-apps.conf"

nodeapp_require_pm2() {
  if ! command -v pm2 >/dev/null 2>&1; then
    log_error "PM2 chưa được cài. Hãy cài Node.js + PM2 trước (plugin nodejs)."
    return 1
  fi
}

nodeapp_ensure_conf() {
  mkdir -p "$(dirname "$NODE_APPS_CONF")"
  [[ -f "$NODE_APPS_CONF" ]] || touch "$NODE_APPS_CONF"
}

nodeapp_generate_express_template() {
  local dir="$1"
  local port="$2"

  mkdir -p "$dir"
  cd "$dir" || return 1

  cat > package.json <<EOF
{
  "name": "ndc-express-api",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "cors": "^2.8.5",
    "dotenv": "^16.4.0",
    "express": "^4.19.0"
  }
}
EOF

  cat > index.js <<EOF
require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || ${port};

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    app: 'ndc-express-api',
    status: 'ok',
    time: new Date().toISOString()
  });
});

app.listen(PORT, () => {
  console.log(\`Server listening on port \${PORT}\`);
});
EOF

  cat > .env.example <<EOF
PORT=${port}
NODE_ENV=production
EOF

  npm install --production
}

nodeapp_create_nginx_vhost() {
  local domain="$1"
  local port="$2"
  local file="/etc/nginx/sites-available/${domain}.conf"

  mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

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
  log_info "Đã tạo Nginx vhost cho ${domain} -> 127.0.0.1:${port}"
}

nodeapp_register() {
  nodeapp_ensure_conf
  local name="$1"
  local domain="$2"
  local dir="$3"
  local port="$4"
  echo "${name}|${domain}|${dir}|${port}" >> "$NODE_APPS_CONF"
  log_info "Đã ghi thông tin app vào ${NODE_APPS_CONF}"
}

nodeapp_list() {
  nodeapp_ensure_conf
  echo "Danh sách app Node đang quản lý:"
  echo "----------------------------------------------"
  if [[ ! -s "$NODE_APPS_CONF" ]]; then
    echo "(Chưa có app nào)"
  else
    awk -F'|' '{printf "- %-15s domain=%-20s dir=%-30s port=%s\n", $1,$2,$3,$4}' "$NODE_APPS_CONF"
  fi
  echo "----------------------------------------------"
}

nodeapp_new_express() {
  nodeapp_require_pm2 || return 1

  read -r -p "Tên app (pm2 name, VD: api-mivn): " name
  read -r -p "Domain public (VD: api.example.com): " domain
  read -r -p "Port nội bộ (VD: 3000): " port
  read -r -p "Path app (VD: /var/www/node/${name}): " app_dir

  [[ -z "$name" || -z "$domain" || -z "$port" || -z "$app_dir" ]] && {
    log_error "Không được để trống."
    return 1
  }

  mkdir -p "$app_dir"
  nodeapp_generate_express_template "$app_dir" "$port"

  cp "$app_dir/.env.example" "$app_dir/.env"

  pm2 start index.js --name "$name" --cwd "$app_dir" --env production
  pm2 save

  nodeapp_create_nginx_vhost "$domain" "$port"
  nodeapp_register "$name" "$domain" "$app_dir" "$port"

  log_info "Đã tạo app Express API + PM2 + Nginx: ${name} (${domain})"
}

nodeapp_register_existing() {
  nodeapp_require_pm2 || return 1

  read -r -p "Tên app (pm2 name, VD: web-mivn): " name
  read -r -p "Domain (VD: app.example.com): " domain
  read -r -p "Port nội bộ app lắng nghe (VD: 3000): " port
  read -r -p "Path app (VD: /var/www/node/${name}): " app_dir
  read -r -p "Lệnh start (default: npm start): " start_cmd
  start_cmd="${start_cmd:-npm start}"

  [[ -z "$name" || -z "$domain" || -z "$port" || -z "$app_dir" ]] && {
    log_error "Không được để trống."
    return 1
  }

  cd "$app_dir" || {
    log_error "Không cd vào ${app_dir} được."
    return 1
  }

  pm2 start "$start_cmd" --name "$name" --cwd "$app_dir" --env production
  pm2 save

  nodeapp_create_nginx_vhost "$domain" "$port"
  nodeapp_register "$name" "$domain" "$app_dir" "$port"

  log_info "Đã đăng ký app Node sẵn có + PM2 + Nginx."
}

nodeapp_show_detail() {
  nodeapp_ensure_conf
  read -r -p "Nhập tên app (pm2 name): " name
  [[ -z "$name" ]] && return 1

  local line
  line=$(grep "^${name}|" "$NODE_APPS_CONF" || true)
  if [[ -z "$line" ]]; then
    echo "Không tìm thấy app '${name}' trong ${NODE_APPS_CONF}."
    return 1
  fi

  IFS='|' read -r n d p port <<< "$line"
  echo "App: $n"
  echo "Domain: $d"
  echo "Dir: $p"
  echo "Port: $port"
  echo
  echo "PM2 status:"
  pm2 status "$n" || true
}

nodeapp_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "            Node App Manager (Plugin)"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "1) Tạo app Express mới (API + PM2 + Nginx)"
    echo "2) Đăng ký app Node/React/Next đã có (PM2 + Nginx)"
    echo "3) Xem danh sách app Node"
    echo "4) Xem chi tiết 1 app (pm2 + config)"
    echo "0) Quay lại"
    echo
    read -rp "Chọn: " c
    case "$c" in
      1) nodeapp_new_express;        read -rp "Enter..." ;;
      2) nodeapp_register_existing;  read -rp "Enter..." ;;
      3) nodeapp_list;               read -rp "Enter..." ;;
      4) nodeapp_show_detail;        read -rp "Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh nodeapp new|register|list
nodeapp_cli() {
  case "$1" in
    new)       nodeapp_new_express ;;
    register)  nodeapp_register_existing ;;
    list|"")   nodeapp_list ;;
    *)
      echo "NodeApp CLI:"
      echo "  nodeapp new       - tạo app Express mới"
      echo "  nodeapp register  - đăng ký app Node sẵn có"
      echo "  nodeapp list      - liệt kê app"
      ;;
  esac
}

ndc_register_plugin \
  "nodeapp" \
  "Node App Manager" \
  "NODE" \
  "Tạo & quản lý app Node/Express/React/Next với PM2 + Nginx" \
  "nodeapp_menu"
