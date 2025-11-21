#!/usr/bin/env bash
#
# ======================================
# Plugin: SSH Tunnel Helper
# Project: nguyendc-ols
# ID: sshhelper
# Category: OPS
# ======================================

SSH_HELPER_USER_KEY="SSH_HELPER_USER"
SSH_HELPER_HOST_KEY="SSH_HELPER_HOST"

sshhelper_get_user() {
  local u
  u="$(state_get "$SSH_HELPER_USER_KEY")"
  if [[ -z "$u" ]]; then
    u="$(whoami 2>/dev/null || echo root)"
  fi
  echo "$u"
}

sshhelper_get_host() {
  local h
  h="$(state_get "$SSH_HELPER_HOST_KEY")"
  if [[ -z "$h" ]]; then
    # lấy IP đầu tiên của server
    h="$(hostname -I 2>/dev/null | awk '{print $1}')"
    # fallback nếu không có
    [[ -z "$h" ]] && h="your-vps-ip"
  fi
  echo "$h"
}

sshhelper_set_defaults() {
  local cur_user cur_host
  cur_user="$(sshhelper_get_user)"
  cur_host="$(sshhelper_get_host)"

  echo "Giá trị hiện tại:"
  echo "  SSH user: ${cur_user}"
  echo "  SSH host: ${cur_host}"
  echo

  read -r -p "SSH user (mặc định: ${cur_user}): " new_user
  read -r -p "SSH host/IP (mặc định: ${cur_host}): " new_host

  new_user="${new_user:-$cur_user}"
  new_host="${new_host:-$cur_host}"

  state_set "$SSH_HELPER_USER_KEY" "$new_user"
  state_set "$SSH_HELPER_HOST_KEY" "$new_host"

  log_info "Đã lưu SSH user=${new_user}, host=${new_host}"
}

sshhelper_print_tunnel() {
  local local_port="$1"
  local remote_host="$2"
  local remote_port="$3"
  local label="$4"

  local user host
  user="$(sshhelper_get_user)"
  host="$(sshhelper_get_host)"

  cat <<EOM

══════════════════════════════════════════════
${label}
══════════════════════════════════════════════
SSH tunnel command:

  ssh -L ${local_port}:${remote_host}:${remote_port} ${user}@${host}

Sau khi chạy lệnh này trên MÁY CÁ NHÂN của bạn, truy cập dịch vụ qua:

  Host:     localhost
  Port:     ${local_port}

EOM
}

sshhelper_dashboard_tunnel() {
  echo "👉 Dùng cho Ops Dashboard (đã cấu hình listen 127.0.0.1:PORT trên VPS)."
  read -r -p "Port DASHBOARD trên VPS (mặc định 9001): " rport
  rport="${rport:-9001}"

  read -r -p "Port LOCAL trên máy bạn (mặc định 9001): " lport
  lport="${lport:-9001}"

  sshhelper_print_tunnel "$lport" "127.0.0.1" "$rport" "Ops Dashboard Tunnel"

  echo "Mở trình duyệt trên máy cá nhân:"
  echo
  echo "  http://localhost:${lport}"
  echo
}

sshhelper_mongo_tunnel() {
  echo "👉 Dùng cho MongoDB GUI (Mongo Compass, DBeaver...)."
  read -r -p "Port MongoDB trên VPS (mặc định 27017): " rport
  rport="${rport:-27017}"

  read -r -p "Port LOCAL trên máy bạn (VD: 27018 – tránh trùng 27017 local): " lport
  lport="${lport:-27018}"

  sshhelper_print_tunnel "$lport" "127.0.0.1" "$rport" "MongoDB Tunnel"

  cat <<EOM
Mongo Compass ví dụ:

  Connection string:
    mongodb://localhost:${lport}

  Hoặc điền như sau:
    Host: localhost
    Port: ${lport}

Nếu MongoDB trên VPS có user/password:
  mongodb://USERNAME:PASSWORD@localhost:${lport}/?authSource=admin

EOM
}

sshhelper_mysql_tunnel() {
  echo "👉 Dùng cho MariaDB/MySQL (DBeaver, TablePlus, DataGrip...)."
  read -r -p "Port MySQL/MariaDB trên VPS (mặc định 3306): " rport
  rport="${rport:-3306}"

  read -r -p "Port LOCAL trên máy bạn (VD: 3307): " lport
  lport="${lport:-3307}"

  sshhelper_print_tunnel "$lport" "127.0.0.1" "$rport" "MySQL/MariaDB Tunnel"

  cat <<EOM
Client kết nối (DBeaver, TablePlus...):

  Host:     localhost
  Port:     ${lport}
  Username: <user MySQL trên VPS>
  Password: <password tương ứng>

EOM
}

sshhelper_postgres_tunnel() {
  echo "👉 Dùng cho PostgreSQL (pgAdmin, DBeaver, TablePlus...)."
  read -r -p "Port PostgreSQL trên VPS (mặc định 5432): " rport
  rport="${rport:-5432}"

  read -r -p "Port LOCAL trên máy bạn (VD: 5433): " lport
  lport="${lport:-5433}"

  sshhelper_print_tunnel "$lport" "127.0.0.1" "$rport" "PostgreSQL Tunnel"

  cat <<EOM
Client kết nối (pgAdmin, DBeaver...):

  Host:     localhost
  Port:     ${lport}
  Username: <user postgres trên VPS>
  Password: <password tương ứng>

EOM
}

sshhelper_custom_tunnel() {
  echo "👉 Tuỳ chọn, dùng được cho bất kỳ dịch vụ nào (Redis, Node app riêng...)."
  read -r -p "Remote host trên VPS (mặc định 127.0.0.1): " rhost
  rhost="${rhost:-127.0.0.1}"

  read -r -p "Remote port trên VPS (VD: 6379 cho Redis, 3000 cho Node app): " rport
  [[ -z "$rport" ]] && { log_error "Remote port không được trống."; return 1; }

  read -r -p "Port LOCAL trên máy bạn (VD: 6379, 3000...): " lport
  [[ -z "$lport" ]] && { log_error "Local port không được trống."; return 1; }

  read -r -p "Mô tả ngắn cho tunnel này: " label
  label="${label:-Custom Tunnel}"

  sshhelper_print_tunnel "$lport" "$rhost" "$rport" "$label"
}

sshhelper_alias_suggestions() {
  local user host
  user="$(sshhelper_get_user)"
  host="$(sshhelper_get_host)"

  cat <<EOM

Gợi ý alias (copy vào ~/.bashrc hoặc ~/.zshrc trên MÁY CÁ NHÂN):

  # Ops Dashboard
  alias ndc-ops="ssh -L 9001:127.0.0.1:9001 ${user}@${host}"

  # Mongo Compass
  alias ndc-mongo="ssh -L 27018:127.0.0.1:27017 ${user}@${host}"

  # MySQL/MariaDB
  alias ndc-mysql="ssh -L 3307:127.0.0.1:3306 ${user}@${host}"

  # PostgreSQL
  alias ndc-pg="ssh -L 5433:127.0.0.1:5432 ${user}@${host}"

Sau khi thêm alias, hãy reload shell:

  source ~/.bashrc
  # hoặc
  source ~/.zshrc

EOM
}

sshhelper_menu() {
  while true; do
    clear
    local cur_user cur_host
    cur_user="$(sshhelper_get_user)"
    cur_host="$(sshhelper_get_host)"

    echo "══════════════════════════════════════════════"
    echo "              SSH Tunnel Helper"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "SSH mặc định: ${cur_user}@${cur_host}"
    echo
    echo "1) Thiết lập SSH user/host mặc định"
    echo "2) Tạo lệnh tunnel cho Ops Dashboard"
    echo "3) Tạo lệnh tunnel cho MongoDB (Compass...)"
    echo "4) Tạo lệnh tunnel cho MySQL/MariaDB"
    echo "5) Tạo lệnh tunnel cho PostgreSQL"
    echo "6) Tạo tunnel custom (Redis/Node app...)"
    echo "7) Gợi ý alias (ndc-ops, ndc-mongo, ...)"
    echo "0) Quay lại"
    echo
    read -rp "Chọn: " c
    case "$c" in
      1) sshhelper_set_defaults;        read -rp "Enter..." ;;
      2) sshhelper_dashboard_tunnel;    read -rp "Enter..." ;;
      3) sshhelper_mongo_tunnel;        read -rp "Enter..." ;;
      4) sshhelper_mysql_tunnel;        read -rp "Enter..." ;;
      5) sshhelper_postgres_tunnel;     read -rp "Enter..." ;;
      6) sshhelper_custom_tunnel;       read -rp "Enter..." ;;
      7) sshhelper_alias_suggestions;   read -rp "Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh sshhelper <subcommand>
sshhelper_cli() {
  case "$1" in
    mongo)   sshhelper_mongo_tunnel ;;
    mysql)   sshhelper_mysql_tunnel ;;
    pg|pgdb) sshhelper_postgres_tunnel ;;
    dash)    sshhelper_dashboard_tunnel ;;
    custom)  sshhelper_custom_tunnel ;;
    alias)   sshhelper_alias_suggestions ;;
    config)  sshhelper_set_defaults ;;
    ""|menu) sshhelper_menu ;;
    *)
      echo "SSH Helper CLI:"
      echo "  sshhelper config        - thiết lập SSH user/host"
      echo "  sshhelper dash          - tunnel cho dashboard"
      echo "  sshhelper mongo         - tunnel cho MongoDB (Compass)"
      echo "  sshhelper mysql         - tunnel cho MySQL/MariaDB"
      echo "  sshhelper pg            - tunnel cho PostgreSQL"
      echo "  sshhelper custom        - tunnel custom"
      echo "  sshhelper alias         - in gợi ý alias"
      ;;
  esac
}

ndc_register_plugin \
  "sshhelper" \
  "SSH Tunnel Helper" \
  "OPS" \
  "Sinh lệnh SSH tunnel (dashboard, MongoDB, MySQL, PostgreSQL, custom) + gợi ý alias" \
  "sshhelper_menu"
