#!/usr/bin/env bash

# ======================================
# Plugin: Quản lý Database
# Category: DATABASE
# ======================================

db_mysql_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "      MySQL/MariaDB Management"
    echo "══════════════════════════════════════════════"
    echo " 1) Tạo DB mới"
    echo " 2) Tạo user + cấp quyền"
    echo " 3) Xóa DB / user"
    echo " 0) Quay lại"
    read -rp "Chọn: " choice
    
    case "$choice" in
      1)
        read -rp "Tên database: " db_name
        mysql -uroot -e "CREATE DATABASE IF NOT EXISTS \`${db_name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
        log_success "Đã tạo database: $db_name"
        ;;
      2)
        read -rp "Username: " db_user
        read -rp "Password: " db_pass
        read -rp "Database: " db_name
        mysql -uroot <<EOF
CREATE USER IF NOT EXISTS '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';
GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO '${db_user}'@'localhost';
FLUSH PRIVILEGES;
EOF
        log_success "Đã tạo user và cấp quyền."
        ;;
      3)
        read -rp "Tên database cần xóa: " db_name
        mysql -uroot -e "DROP DATABASE IF EXISTS \`${db_name}\`;"
        log_success "Đã xóa database: $db_name"
        ;;
      0) break ;;
    esac
    read -rp "Nhấn Enter..."
  done
}

db_mongo_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "          MongoDB Management"
    echo "══════════════════════════════════════════════"
    echo " 1) Tạo DB/user"
    echo " 2) Thiết lập auth"
    echo " 0) Quay lại"
    read -rp "Chọn: " choice
    
    case "$choice" in
      1)
        read -rp "Database name: " db_name
        read -rp "Username: " db_user
        read -rp "Password: " db_pass
        mongosh <<EOF
use ${db_name}
db.createUser({
  user: "${db_user}",
  pwd: "${db_pass}",
  roles: [{role: "readWrite", db: "${db_name}"}]
})
EOF
        log_success "Đã tạo user MongoDB."
        ;;
      2)
        log_info "Thiết lập auth MongoDB..."
        ;;
      0) break ;;
    esac
    read -rp "Nhấn Enter..."
  done
}

db_postgres_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "        PostgreSQL Management"
    echo "══════════════════════════════════════════════"
    echo " 1) Tạo DB/user"
    echo " 0) Quay lại"
    read -rp "Chọn: " choice
    
    case "$choice" in
      1)
        read -rp "Database name: " db_name
        read -rp "Username: " db_user
        read -rp "Password: " db_pass
        sudo -u postgres psql <<EOF
CREATE DATABASE ${db_name};
CREATE USER ${db_user} WITH PASSWORD '${db_pass}';
GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${db_user};
EOF
        log_success "Đã tạo database và user PostgreSQL."
        ;;
      0) break ;;
    esac
    read -rp "Nhấn Enter..."
  done
}

db_redis_menu() {
  clear
  echo "══════════════════════════════════════════════"
  echo "          Redis Management"
  echo "══════════════════════════════════════════════"
  
  if systemctl is-active --quiet redis-server; then
    echo "✅ Redis: running"
  else
    echo "❌ Redis: stopped"
  fi
  
  read -rp "Nhấn Enter..."
}

database_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "          Quản lý Database"
    echo "══════════════════════════════════════════════"
    echo " 1) MySQL/MariaDB"
    echo " 2) MongoDB"
    echo " 3) PostgreSQL"
    echo " 4) Redis"
    echo " 0) Quay lại"
    echo
    read -rp "Chọn chức năng: " choice
    
    case "$choice" in
      1) db_mysql_menu ;;
      2) db_mongo_menu ;;
      3) db_postgres_menu ;;
      4) db_redis_menu ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "database" \
  "Quản lý Database" \
  "DATABASE" \
  "" \
  "database_menu"
