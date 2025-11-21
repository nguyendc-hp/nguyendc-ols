#!/usr/bin/env bash
#
# ======================================
# Plugin: DB GUI Profiles
# Project: nguyendc-ols
# ID: dbgui
# Category: DB
# ======================================

DBG_MONGO_PORT_KEY="DBG_MONGO_LOCAL_PORT"
DBG_MYSQL_PORT_KEY="DBG_MYSQL_LOCAL_PORT"
DBG_PG_PORT_KEY="DBG_PG_LOCAL_PORT"
DBG_REDIS_PORT_KEY="DBG_REDIS_LOCAL_PORT"

dbg_get_or_default() {
  local key="$1" def="$2"
  local v
  v="$(state_get "$key")"
  [[ -z "$v" ]] && v="$def"
  echo "$v"
}

dbg_set_ports() {
  local cur_m cur_my cur_pg cur_r
  cur_m="$(dbg_get_or_default "$DBG_MONGO_PORT_KEY" "27018")"
  cur_my="$(dbg_get_or_default "$DBG_MYSQL_PORT_KEY" "3307")"
  cur_pg="$(dbg_get_or_default "$DBG_PG_PORT_KEY" "5433")"
  cur_r="$(dbg_get_or_default "$DBG_REDIS_PORT_KEY" "6379")"

  echo "Port hiện tại (LOCAL trên máy bạn, sau SSH tunnel):"
  echo "  MongoDB : ${cur_m}"
  echo "  MySQL   : ${cur_my}"
  echo "  Postgres: ${cur_pg}"
  echo "  Redis   : ${cur_r}"
  echo

  read -r -p "MongoDB local port (mặc định ${cur_m}): " nm
  read -r -p "MySQL/MariaDB local port (mặc định ${cur_my}): " nmy
  read -r -p "PostgreSQL local port (mặc định ${cur_pg}): " npg
  read -r -p "Redis local port (mặc định ${cur_r}): " nr

  nm="${nm:-$cur_m}"
  nmy="${nmy:-$cur_my}"
  npg="${npg:-$cur_pg}"
  nr="${nr:-$cur_r}"

  state_set "$DBG_MONGO_PORT_KEY" "$nm"
  state_set "$DBG_MYSQL_PORT_KEY" "$nmy"
  state_set "$DBG_PG_PORT_KEY" "$npg"
  state_set "$DBG_REDIS_PORT_KEY" "$nr"

  log_info "Đã lưu cấu hình port LOCAL: Mongo=${nm}, MySQL=${nmy}, PG=${npg}, Redis=${nr}"
}

dbg_header() {
  clear
  echo "══════════════════════════════════════════════"
  echo "            DB GUI Profiles (Plugin)"
  echo "                 nguyendc-ols"
  echo "══════════════════════════════════════════════"
  echo
}

dbg_print_mongo_profiles() {
  local mport
  mport="$(dbg_get_or_default "$DBG_MONGO_PORT_KEY" "27018")"

  dbg_header
  echo "💽 MongoDB GUI Profiles"
  echo "----------------------------------------------"
  echo "Giả định bạn đã chạy SSH tunnel kiểu:"
  echo "  ssh -L ${mport}:127.0.0.1:27017 user@your-vps"
  echo
  echo "1) MongoDB Compass"
  echo "----------------------------------------------"
  echo "Connection String:"
  echo "  mongodb://localhost:${mport}"
  echo
  echo "Nếu có user/password:"
  echo "  mongodb://USERNAME:PASSWORD@localhost:${mport}/?authSource=admin"
  echo
  echo "2) DBeaver (MongoDB)"
  echo "----------------------------------------------"
  echo "Driver: MongoDB"
  echo "Host  : localhost"
  echo "Port  : ${mport}"
  echo
  echo "3) VSCode - MongoDB extension"
  echo "----------------------------------------------"
  echo "URI:"
  echo "  mongodb://localhost:${mport}"
  echo
}

dbg_print_mysql_profiles() {
  local myport
  myport="$(dbg_get_or_default "$DBG_MYSQL_PORT_KEY" "3307")"

  dbg_header
  echo "🐬 MySQL / MariaDB GUI Profiles"
  echo "----------------------------------------------"
  echo "Giả định bạn đã chạy SSH tunnel kiểu:"
  echo "  ssh -L ${myport}:127.0.0.1:3306 user@your-vps"
  echo
  echo "1) DBeaver"
  echo "----------------------------------------------"
  echo "Driver : MySQL hoặc MariaDB"
  echo "Host   : localhost"
  echo "Port   : ${myport}"
  echo "User   : <user MySQL trên VPS>"
  echo "Pass   : <password MySQL trên VPS>"
  echo
  echo "2) TablePlus / HeidiSQL / DataGrip"
  echo "----------------------------------------------"
  echo "Host   : localhost"
  echo "Port   : ${myport}"
  echo "User   : <user>"
  echo "Pass   : <pass>"
  echo
}

dbg_print_pg_profiles() {
  local pgport
  pgport="$(dbg_get_or_default "$DBG_PG_PORT_KEY" "5433")"

  dbg_header
  echo "🐘 PostgreSQL GUI Profiles"
  echo "----------------------------------------------"
  echo "Giả định bạn đã chạy SSH tunnel kiểu:"
  echo "  ssh -L ${pgport}:127.0.0.1:5432 user@your-vps"
  echo
  echo "1) pgAdmin"
  echo "----------------------------------------------"
  echo "Host     : localhost"
  echo "Port     : ${pgport}"
  echo "Username : <user postgres trên VPS>"
  echo "Password : <password>"
  echo
  echo "2) DBeaver / TablePlus / DataGrip"
  echo "----------------------------------------------"
  echo "Driver   : PostgreSQL"
  echo "Host     : localhost"
  echo "Port     : ${pgport}"
  echo "User     : <user>"
  echo "Password : <pass>"
  echo
}

dbg_print_redis_profiles() {
  local rport
  rport="$(dbg_get_or_default "$DBG_REDIS_PORT_KEY" "6379")"

  dbg_header
  echo "🧠 Redis GUI Profiles"
  echo "----------------------------------------------"
  echo "Giả định bạn đã chạy SSH tunnel kiểu:"
  echo "  ssh -L ${rport}:127.0.0.1:6379 user@your-vps"
  echo
  echo "Ví dụ Another Redis Desktop Manager / RedisInsight:"
  echo "----------------------------------------------"
  echo "Host : localhost"
  echo "Port : ${rport}"
  echo "Auth : <password nếu Redis có đặt requirepass>"
  echo
}

dbg_show_all() {
  dbg_header
  local m my pg r
  m="$(dbg_get_or_default "$DBG_MONGO_PORT_KEY" "27018")"
  my="$(dbg_get_or_default "$DBG_MYSQL_PORT_KEY" "3307")"
  pg="$(dbg_get_or_default "$DBG_PG_PORT_KEY" "5433")"
  r="$(dbg_get_or_default "$DBG_REDIS_PORT_KEY" "6379")"

  echo "Tổng quan port LOCAL (sau SSH tunnel):"
  echo "  MongoDB : localhost:${m}"
  echo "  MySQL   : localhost:${my}"
  echo "  Postgres: localhost:${pg}"
  echo "  Redis   : localhost:${r}"
  echo
  echo "Gợi ý dùng kèm plugin: SSH Tunnel Helper (sshhelper)"
  echo "  - sshhelper mongo"
  echo "  - sshhelper mysql"
  echo "  - sshhelper pg"
  echo "  - sshhelper custom (cho Redis/khác)"
  echo
  echo "Chọn từng mục trong menu để xem cấu hình chi tiết cho từng GUI."
  echo
}

dbg_menu() {
  while true; do
    clear
    local m my pg r
    m="$(dbg_get_or_default "$DBG_MONGO_PORT_KEY" "27018")"
    my="$(dbg_get_or_default "$DBG_MYSQL_PORT_KEY" "3307")"
    pg="$(dbg_get_or_default "$DBG_PG_PORT_KEY" "5433")"
    r="$(dbg_get_or_default "$DBG_REDIS_PORT_KEY" "6379")"

    echo "══════════════════════════════════════════════"
    echo "               DB GUI Profiles"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "Port LOCAL hiện tại:"
    echo "  MongoDB : localhost:${m}"
    echo "  MySQL   : localhost:${my}"
    echo "  PGSQL   : localhost:${pg}"
    echo "  Redis   : localhost:${r}"
    echo
    echo "1) Xem profile cho MongoDB (Compass, DBeaver...)"
    echo "2) Xem profile cho MySQL/MariaDB (DBeaver, TablePlus...)"
    echo "3) Xem profile cho PostgreSQL (pgAdmin, DBeaver...)"
    echo "4) Xem profile cho Redis GUI"
    echo "5) Xem tổng quan tất cả (tóm tắt)"
    echo "6) Thiết lập lại port LOCAL mặc định"
    echo "0) Quay lại"
    echo
    read -rp "Chọn: " c
    case "$c" in
      1) dbg_print_mongo_profiles;  read -rp "Enter..." ;;
      2) dbg_print_mysql_profiles;  read -rp "Enter..." ;;
      3) dbg_print_pg_profiles;     read -rp "Enter..." ;;
      4) dbg_print_redis_profiles;  read -rp "Enter..." ;;
      5) dbg_show_all;              read -rp "Enter..." ;;
      6) dbg_set_ports;             read -rp "Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh dbgui mongo|mysql|pg|redis|all|config
dbgui_cli() {
  case "$1" in
    mongo)  dbg_print_mongo_profiles ;;
    mysql)  dbg_print_mysql_profiles ;;
    pg)     dbg_print_pg_profiles ;;
    redis)  dbg_print_redis_profiles ;;
    all|"") dbg_show_all ;;
    config) dbg_set_ports ;;
    *)
      echo "DB GUI Profiles CLI:"
      echo "  dbgui mongo   - profile cho MongoDB GUI"
      echo "  dbgui mysql   - profile cho MySQL/MariaDB GUI"
      echo "  dbgui pg      - profile cho PostgreSQL GUI"
      echo "  dbgui redis   - profile cho Redis GUI"
      echo "  dbgui all     - tóm tắt tất cả"
      echo "  dbgui config  - chỉnh port LOCAL"
      ;;
  esac
}

ndc_register_plugin \
  "dbgui" \
  "DB GUI Profiles" \
  "DB" \
  "Sinh cấu hình kết nối cho MongoDB/MySQL/Postgres/Redis GUI (Compass, DBeaver, TablePlus...)" \
  "dbg_menu"
