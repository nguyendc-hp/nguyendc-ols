#!/usr/bin/env bash

# ======================================
# Plugin: Kết nối GUI / SSH Tunnel
# Category: DB_GUI
# ======================================

db_gui_mongo_tunnel() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Sinh SSH tunnel cho MongoDB"
  echo "══════════════════════════════════════════════"
  
  echo "Kết nối MongoDB qua SSH tunnel:"
  echo ""
  echo "Từ máy local, chạy lệnh:"
  echo "  ssh -L 27017:localhost:27017 user@your-server-ip"
  echo ""
  echo "Sau đó kết nối Mongo Compass/DBeaver tới:"
  echo "  mongodb://localhost:27017"
  echo ""
  echo "Hoặc tạo alias trong ~/.ssh/config:"
  echo "Host ndc-mongo"
  echo "  HostName your-server-ip"
  echo "  User root"
  echo "  LocalForward 27017 127.0.0.1:27017"
  echo ""
}

db_gui_mysql_tunnel() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Sinh SSH tunnel cho MySQL/MariaDB"
  echo "══════════════════════════════════════════════"
  
  echo "Kết nối MySQL qua SSH tunnel:"
  echo ""
  echo "Từ máy local, chạy lệnh:"
  echo "  ssh -L 3306:localhost:3306 user@your-server-ip"
  echo ""
  echo "Sau đó kết nối DBeaver/TablePlus tới:"
  echo "  localhost:3306"
  echo ""
}

db_gui_postgres_tunnel() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Sinh SSH tunnel cho PostgreSQL"
  echo "══════════════════════════════════════════════"
  
  echo "Kết nối PostgreSQL qua SSH tunnel:"
  echo ""
  echo "Từ máy local, chạy lệnh:"
  echo "  ssh -L 5432:localhost:5432 user@your-server-ip"
  echo ""
  echo "Sau đó kết nối pgAdmin/DBeaver tới:"
  echo "  localhost:5432"
  echo ""
}

db_gui_redis_tunnel() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Sinh SSH tunnel cho Redis"
  echo "══════════════════════════════════════════════"
  
  echo "Kết nối Redis qua SSH tunnel:"
  echo ""
  echo "Từ máy local, chạy lệnh:"
  echo "  ssh -L 6379:localhost:6379 user@your-server-ip"
  echo ""
  echo "Sau đó kết nối RedisInsight tới:"
  echo "  localhost:6379"
  echo ""
}

db_gui_connection_profiles() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Hiển thị profile kết nối"
  echo "══════════════════════════════════════════════"
  
  echo "MongoDB:"
  echo "  Connection string: mongodb://localhost:27017"
  echo ""
  echo "MySQL:"
  echo "  Host: localhost"
  echo "  Port: 3306"
  echo ""
  echo "PostgreSQL:"
  echo "  Host: localhost"
  echo "  Port: 5432"
  echo ""
  echo "Redis:"
  echo "  Host: localhost"
  echo "  Port: 6379"
  echo ""
}

db_gui_ssh_aliases() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Gợi ý alias SSH"
  echo "══════════════════════════════════════════════"
  
  echo "Thêm vào file ~/.ssh/config trên máy local:"
  echo ""
  echo "Host ndc-mongo"
  echo "  HostName your-server-ip"
  echo "  User root"
  echo "  LocalForward 27017 127.0.0.1:27017"
  echo ""
  echo "Host ndc-mysql"
  echo "  HostName your-server-ip"
  echo "  User root"
  echo "  LocalForward 3306 127.0.0.1:3306"
  echo ""
  echo "Host ndc-pg"
  echo "  HostName your-server-ip"
  echo "  User root"
  echo "  LocalForward 5432 127.0.0.1:5432"
  echo ""
}

db_gui_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "    Kết nối GUI / SSH Tunnel cho DB"
    echo "══════════════════════════════════════════════"
    echo " 1) Sinh SSH tunnel cho MongoDB"
    echo " 2) Sinh SSH tunnel cho MySQL/MariaDB"
    echo " 3) Sinh SSH tunnel cho PostgreSQL"
    echo " 4) Sinh SSH tunnel cho Redis"
    echo " 5) Hiển thị profile kết nối"
    echo " 6) Gợi ý alias SSH"
    echo " 0) Quay lại"
    echo
    read -rp "Chọn chức năng: " choice
    
    case "$choice" in
      1) db_gui_mongo_tunnel; read -rp "Nhấn Enter..." ;;
      2) db_gui_mysql_tunnel; read -rp "Nhấn Enter..." ;;
      3) db_gui_postgres_tunnel; read -rp "Nhấn Enter..." ;;
      4) db_gui_redis_tunnel; read -rp "Nhấn Enter..." ;;
      5) db_gui_connection_profiles; read -rp "Nhấn Enter..." ;;
      6) db_gui_ssh_aliases; read -rp "Nhấn Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "db-gui" \
  "Kết nối GUI / SSH Tunnel cho DB" \
  "DB_GUI" \
  "" \
  "db_gui_menu"
