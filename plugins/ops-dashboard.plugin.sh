#!/usr/bin/env bash
#
# ======================================
# Plugin: Ops Dashboard (HTML)
# Project: nguyendc-ols
# ID: opsdash
# Category: OPS
# ======================================

NODE_APPS_CONF="/etc/nguyendc-ols/node-apps.conf"
WP_SITES_CONF="/etc/nguyendc-ols/wp-sites.conf"
WP_BASE_DIR="/var/www"
OPSDASH_DIR="/var/www/ndc-ols-dashboard"

# ----------------------------------------
# Helper: Node Apps
# ----------------------------------------

opsdash_has_node_conf() {
  [[ -f "$NODE_APPS_CONF" ]] && [[ -s "$NODE_APPS_CONF" ]]
}

opsdash_node_apps_raw() {
  opsdash_has_node_conf || return 1
  grep -v '^[[:space:]]*$' "$NODE_APPS_CONF"
}

opsdash_pm2_status() {
  local name="$1"
  if ! command -v pm2 >/dev/null 2>&1; then
    echo "NO_PM2"
    return
  fi

  if command -v jq >/dev/null 2>&1; then
    local s
    s=$(pm2 jlist 2>/dev/null | jq -r ".[] | select(.name==\"${name}\") | .pm2_env.status" 2>/dev/null)
    [[ -z "$s" || "$s" == "null" ]] && s="NOT_FOUND"
    echo "$s"
  else
    pm2 ls | awk -v n="$name" '$0 ~ n {print $10}' | head -n1
  fi
}

opsdash_http_check() {
  local url="$1"
  if ! command -v curl >/dev/null 2>&1; then
    echo "000 0"
    return
  fi
  local out code t time_ms
  out=$(curl -o /dev/null -s -w "%{http_code} %{time_total}" --max-time 8 "$url" || echo "000 9.999")
  code=$(echo "$out" | awk '{print $1}')
  t=$(echo "$out" | awk '{print $2}')
  time_ms=$(awk -v x="$t" 'BEGIN{printf "%.0f", x*1000}')
  echo "${code} ${time_ms}"
}

opsdash_error_count() {
  local name="$1"
  local lines=200
  if ! command -v pm2 >/dev/null 2>&1; then
    echo "0"
    return
  fi

  local tmp
  tmp=$(mktemp)
  pm2 logs "$name" --lines "$lines" --raw > "$tmp" 2>/dev/null &
  sleep 2
  pkill -f "pm2 logs $name" 2>/dev/null || true

  local cnt
  cnt=$(grep -Ei "error|exception|unhandled" "$tmp" | wc -l || echo 0)
  rm -f "$tmp"
  echo "$cnt"
}

opsdash_eval_node_level() {
  local pm2s="$1" code="$2" time_ms="$3" errors="$4"
  local level="OK"

  # PM2
  if [[ "$pm2s" != "online" ]]; then
    level="CRIT"
  fi

  # HTTP
  if [[ "$code" == "000" || "$code" == "500" || "$code" == "502" || "$code" == "503" ]]; then
    level="CRIT"
  elif [[ "$code" != "200" && "$code" != "301" && "$code" != "302" ]]; then
    [[ "$level" != "CRIT" ]] && level="WARN"
  fi

  # Time
  if (( time_ms > 4000 )); then
    level="CRIT"
  elif (( time_ms > 2000 )); then
    [[ "$level" == "OK" ]] && level="WARN"
  fi

  # Errors
  if (( errors >= 10 )); then
    level="CRIT"
  elif (( errors >= 3 )); then
    [[ "$level" == "OK" ]] && level="WARN"
  fi

  echo "$level"
}

# ----------------------------------------
# Helper: WordPress Sites
# ----------------------------------------

opsdash_wp_sites_raw() {
  # Ưu tiên đọc từ WP_SITES_CONF (domain|dir)
  if [[ -f "$WP_SITES_CONF" && -s "$WP_SITES_CONF" ]]; then
    grep -v '^[[:space:]]*$' "$WP_SITES_CONF"
    return 0
  fi

  # Nếu chưa có file cấu hình, auto scan /var/www tìm wp-config.php
  if [[ ! -d "$WP_BASE_DIR" ]]; then
    return 1
  fi

  # format: domain|dir
  find "$WP_BASE_DIR" -maxdepth 3 -type f -name "wp-config.php" 2>/dev/null | while read -r cfg; do
    local dir domain
    dir=$(dirname "$cfg")
    domain=$(basename "$dir")
    echo "${domain}|${dir}"
  done
}

opsdash_eval_wp_level() {
  local code="$1" time_ms="$2"
  local level="OK"

  if [[ "$code" == "000" || "$code" == "500" || "$code" == "502" || "$code" == "503" ]]; then
    level="CRIT"
  elif [[ "$code" != "200" && "$code" != "301" && "$code" != "302" ]]; then
    level="WARN"
  fi

  if (( time_ms > 4000 )); then
    level="CRIT"
  elif (( time_ms > 2000 )); then
    [[ "$level" == "OK" ]] && level="WARN"
  fi

  echo "$level"
}

# ----------------------------------------
# Helper: Server Info (load + memory)
# ----------------------------------------

opsdash_server_info() {
  local load cpu_str mem_str
  if command -v uptime >/dev/null 2>&1; then
    load=$(uptime | sed 's/.*load average: //')
  else
    load="N/A"
  fi

  if command -v free >/dev/null 2>&1; then
    mem_str=$(free -m | awk 'NR==2{printf "%s/%s MB (%.0f%%)", $3, $2, $3*100/$2}')
  else
    mem_str="N/A"
  fi

  echo "${load}|${mem_str}"
}

# ----------------------------------------
# Build Dashboard HTML (Node + WP)
# ----------------------------------------

opsdash_build_html() {
  mkdir -p "$OPSDASH_DIR"
  local outfile="${OPSDASH_DIR}/index.html"

  local node_rows=""
  local wp_rows=""
  local worst="OK"

  # Node apps section
  if opsdash_has_node_conf; then
    while IFS='|' read -r name domain dir port; do
      [[ -z "$name" ]] && continue
      local url="http://${domain}/"

      local pm2s http_res code time_ms errors level
      pm2s=$(opsdash_pm2_status "$name")
      http_res=$(opsdash_http_check "$url")
      code=$(echo "$http_res" | awk '{print $1}')
      time_ms=$(echo "$http_res" | awk '{print $2}')
      errors=$(opsdash_error_count "$name")
      level=$(opsdash_eval_node_level "$pm2s" "$code" "$time_ms" "$errors")

      case "$level" in
        CRIT) worst="CRIT" ;;
        WARN) [[ "$worst" == "OK" ]] && worst="WARN" ;;
      esac

      local cls=""
      case "$level" in
        OK)   cls="ok" ;;
        WARN) cls="warn" ;;
        CRIT) cls="crit" ;;
      esac

      node_rows+="<tr class=\"${cls}\">"
      node_rows+="<td>${name}</td>"
      node_rows+="<td>${domain}</td>"
      node_rows+="<td>${pm2s}</td>"
      node_rows+="<td>${code}</td>"
      node_rows+="<td>${time_ms}</td>"
      node_rows+="<td>${errors}</td>"
      node_rows+="<td>${level}</td>"
      node_rows+="</tr>"
    done < <(opsdash_node_apps_raw)
  fi

  # WordPress section
  local wp_any=false
  while IFS='|' read -r domain dir; do
    [[ -z "$domain" ]] && continue
    wp_any=true

    local url="http://${domain}/"
    local http_res code time_ms level
    http_res=$(opsdash_http_check "$url")
    code=$(echo "$http_res" | awk '{print $1}')
    time_ms=$(echo "$http_res" | awk '{print $2}')
    level=$(opsdash_eval_wp_level "$code" "$time_ms")

    case "$level" in
      CRIT) worst="CRIT" ;;
      WARN) [[ "$worst" == "OK" ]] && worst="WARN" ;;
    esac

    local cls=""
    case "$level" in
      OK)   cls="ok" ;;
      WARN) cls="warn" ;;
      CRIT) cls="crit" ;;
    esac

    wp_rows+="<tr class=\"${cls}\">"
    wp_rows+="<td>${domain}</td>"
    wp_rows+="<td>${dir}</td>"
    wp_rows+="<td>${code}</td>"
    wp_rows+="<td>${time_ms}</td>"
    wp_rows+="<td>${level}</td>"
    wp_rows+="</tr>"
  done < <(opsdash_wp_sites_raw || true)

  local ts
  ts=$(date +'%Y-%m-%d %H:%M:%S')
  local load mem
  IFS='|' read -r load mem <<< "$(opsdash_server_info)"

  cat > "$outfile" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>nguyendc-ols Ops Dashboard</title>
<meta http-equiv="refresh" content="30">
<style>
body { font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background:#020617; color:#e5e7eb; margin:0; padding:20px; }
h1 { margin-bottom:4px; }
small { color:#9ca3af; }
section { margin-top:20px; }
table { width:100%; border-collapse:collapse; margin-top:8px; font-size:14px; }
th, td { padding:8px 10px; text-align:left; }
th { background:#0b1120; border-bottom:1px solid #1f2937; position:sticky; top:0; z-index:1; }
tr:nth-child(even) { background:#020617; }
tr:nth-child(odd) { background:#020617; }
tr.ok { background:#022c22; }
tr.warn { background:#451a03; }
tr.crit { background:#7f1d1d; }
.badge { display:inline-block; padding:2px 8px; border-radius:999px; font-size:11px; text-transform:uppercase; }
.badge-ok { background:#16a34a; color:#022c22; }
.badge-warn { background:#facc15; color:#451a03; }
.badge-crit { background:#ef4444; color:#7f1d1d; }
.footer { margin-top:16px; font-size:12px; color:#6b7280; display:flex; justify-content:space-between; align-items:center; }
.cards { display:flex; gap:12px; flex-wrap:wrap; margin-top:12px; }
.card { background:#020617; border:1px solid #1f2937; border-radius:12px; padding:10px 14px; min-width:180px; }
.card-title { font-size:12px; text-transform:uppercase; color:#9ca3af; margin-bottom:4px; }
.card-value { font-size:14px; }
.section-title { display:flex; justify-content:space-between; align-items:center; }
.section-title h2 { margin:0; font-size:16px; }
.section-title small { font-size:12px; }
</style>
</head>
<body>
  <h1>nguyendc-ols &mdash; Ops Dashboard</h1>
  <small>Node apps + WordPress sites + Server metrics. Auto-refresh mỗi 30s.</small>

  <div class="cards">
    <div class="card">
      <div class="card-title">Server Load</div>
      <div class="card-value">${load}</div>
    </div>
    <div class="card">
      <div class="card-title">Memory Used</div>
      <div class="card-value">${mem}</div>
    </div>
    <div class="card">
      <div class="card-title">Overall Status</div>
      <div class="card-value">
EOF

  case "$worst" in
    OK)
      echo '        <span class="badge badge-ok">OK</span>' >> "$outfile"
      ;;
    WARN)
      echo '        <span class="badge badge-warn">WARN</span>' >> "$outfile"
      ;;
    CRIT)
      echo '        <span class="badge badge-crit">CRIT</span>' >> "$outfile"
      ;;
    *)
      echo '        <span class="badge">UNKNOWN</span>' >> "$outfile"
      ;;
  esac

  cat >> "$outfile" <<EOF
      </div>
    </div>
  </div>

  <section>
    <div class="section-title">
      <h2>Node Apps</h2>
      <small>Đọc từ ${NODE_APPS_CONF}</small>
    </div>
    <table>
      <thead>
        <tr>
          <th>App</th>
          <th>Domain</th>
          <th>PM2</th>
          <th>HTTP</th>
          <th>Time (ms)</th>
          <th>Errors (recent)</th>
          <th>Level</th>
        </tr>
      </thead>
      <tbody>
EOF

  if [[ -n "$node_rows" ]]; then
    echo "      ${node_rows}" >> "$outfile"
  else
    echo '      <tr><td colspan="7" style="color:#6b7280;">Không có Node app nào trong cấu hình.</td></tr>' >> "$outfile"
  fi

  cat >> "$outfile" <<EOF
      </tbody>
    </table>
  </section>

  <section>
    <div class="section-title">
      <h2>WordPress Sites</h2>
      <small>
EOF

  if [[ -f "$WP_SITES_CONF" && -s "$WP_SITES_CONF" ]]; then
    echo "Đọc từ ${WP_SITES_CONF}" >> "$outfile"
  else
    echo "Auto scan trong ${WP_BASE_DIR} (wp-config.php)" >> "$outfile"
  fi

  cat >> "$outfile" <<EOF
      </small>
    </div>
    <table>
      <thead>
        <tr>
          <th>Domain</th>
          <th>Path</th>
          <th>HTTP</th>
          <th>Time (ms)</th>
          <th>Level</th>
        </tr>
      </thead>
      <tbody>
EOF

  if [[ -n "$wp_rows" ]]; then
    echo "      ${wp_rows}" >> "$outfile"
  else
    echo '      <tr><td colspan="5" style="color:#6b7280;">Không phát hiện site WordPress nào.</td></tr>' >> "$outfile"
  fi

  cat >> "$outfile" <<EOF
      </tbody>
    </table>
  </section>

  <div class="footer">
    <div>Generated at: ${ts}</div>
    <div>nguyendc-ols Ops Dashboard (Node + WordPress)</div>
  </div>
</body>
</html>
EOF

  log_info "Đã build dashboard HTML tại: ${outfile}"
}

# ----------------------------------------
# Nginx vhost cho dashboard
# ----------------------------------------

opsdash_setup_nginx() {
  mkdir -p "$OPSDASH_DIR"

  echo "Chọn chế độ cấu hình Nginx cho dashboard:"
  echo "1) Local-only (listen 127.0.0.1, truy cập qua SSH tunnel) [Khuyến nghị]"
  echo "2) Public domain (listen 0.0.0.0:80, dùng domain, cần tự bảo mật thêm)"
  read -rp "Chọn (1/2, mặc định 1): " mode
  mode="${mode:-1}"

  if [[ "$mode" == "2" ]]; then
    # --- Chế độ PUBLIC (giữ cho trường hợp đặc biệt) ---
    local domain
    read -r -p "Domain để xem dashboard (VD: ops.example.com): " domain
    [[ -z "$domain" ]] && { log_error "Domain không được trống."; return 1; }

    local file="/etc/nginx/sites-available/${domain}.conf"
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

    cat > "$file" <<EOF
server {
    listen 80;
    server_name ${domain};

    root ${OPSDASH_DIR};
    index index.html;

    access_log /var/log/nginx/${domain}_access.log;
    error_log  /var/log/nginx/${domain}_error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

    ln -sf "$file" "/etc/nginx/sites-enabled/${domain}.conf"
    if ! grep -q "/etc/nginx/sites-enabled" /etc/nginx/nginx.conf 2>/dev/null; then
      sed -i "/http {/a \    include /etc/nginx/sites-enabled/*;" /etc/nginx/nginx.conf
    fi

    nginx -t && systemctl reload nginx
    log_warn "Đã tạo Nginx vhost PUBLIC cho dashboard: http://${domain}"
    log_warn "👉 Hãy cấu hình thêm HTTPS + auth_basic + hạn chế IP để an toàn hơn."
    return 0
  fi

  # --- Chế độ LOCAL-ONLY + SSH tunnel (mặc định, khuyến nghị) ---
  local port
  read -r -p "Port nội bộ trên VPS cho dashboard (mặc định 9001): " port
  port="${port:-9001}"

  local file="/etc/nginx/sites-available/ndc-ols-dashboard.local.conf"
  mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

  cat > "$file" <<EOF
server {
    listen 127.0.0.1:${port};
    server_name _;

    root ${OPSDASH_DIR};
    index index.html;

    access_log /var/log/nginx/ndc-ols-dashboard_access.log;
    error_log  /var/log/nginx/ndc-ols-dashboard_error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

  ln -sf "$file" "/etc/nginx/sites-enabled/ndc-ols-dashboard.local.conf"

  if ! grep -q "/etc/nginx/sites-enabled" /etc/nginx/nginx.conf 2>/dev/null; then
    sed -i "/http {/a \    include /etc/nginx/sites-enabled/*;" /etc/nginx/nginx.conf
  fi

  nginx -t && systemctl reload nginx

  # Gợi ý lệnh SSH tunnel
  local user ip local_port
  user="$(whoami 2>/dev/null || echo root)"
  ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
  read -r -p "Port LOCAL trên máy của bạn để forward (mặc định 9001): " local_port
  local_port="${local_port:-9001}"

  cat <<EOM
✅ Đã cấu hình dashboard ở chế độ LOCAL-ONLY:

  - Nginx listen: 127.0.0.1:${port} (trên VPS)
  - Dashboard root: ${OPSDASH_DIR}

Để truy cập từ máy cá nhân, chạy lệnh SSH tunnel:

  ssh -L ${local_port}:127.0.0.1:${port} ${user}@${ip}

Sau đó mở trình duyệt trên máy của bạn:

  http://localhost:${local_port}

Gợi ý: có thể lưu alias trong ~/.bashrc, ví dụ:
  alias ndc-ops="ssh -L ${local_port}:127.0.0.1:${port} ${user}@${ip}"
EOM
}

# ----------------------------------------
# MENU & CLI
# ----------------------------------------

opsdash_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "        Ops Dashboard (Node + WordPress)"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "Dashboard path: ${OPSDASH_DIR}/index.html"
    echo
    echo "1) Build/Update dashboard HTML"
    echo "2) Thiết lập Nginx cho dashboard"
    echo "   - Mặc định: listen 127.0.0.1 + SSH tunnel (an toàn)"
    echo "   - Tuỳ chọn: public domain (tự bảo mật thêm)"
    echo "0) Quay lại"
    echo
    read -rp "Chọn: " c
    case "$c" in
      1) opsdash_build_html;   read -rp "Enter..." ;;
      2) opsdash_setup_nginx;  read -rp "Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}


# CLI: ./nguyendc-ols.sh opsdash build|nginx
opsdash_cli() {
  case "$1" in
    build|"") opsdash_build_html ;;
    nginx)    opsdash_setup_nginx ;;
    *)
      echo "OpsDashboard CLI:"
      echo "  opsdash build   - build/update dashboard HTML"
      echo "  opsdash nginx   - tạo vhost Nginx cho dashboard"
      ;;
  esac
}

ndc_register_plugin \
  "opsdash" \
  "Ops Dashboard (Node + WordPress)" \
  "OPS" \
  "Sinh dashboard HTML xem health Node apps + WordPress sites + server metrics" \
  "opsdash_menu"
