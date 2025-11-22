#!/usr/bin/env bash

# ======================================
# Plugin: Cài đặt hệ thống
# Category: SETUP
# Menu cấp 2 theo MENU_STRUCTURE.MD
# ======================================

setup_installed_programs() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Chương trình / dịch vụ đã cài đặt"
  echo "══════════════════════════════════════════════"
  
  echo -e "\n${GREEN}Web Server:${NC}"
  if command -v nginx >/dev/null 2>&1; then
    echo "  ✅ Nginx: $(nginx -v 2>&1 | grep -oP 'nginx/\K[0-9.]+')"
  else
    echo "  ❌ Nginx chưa cài"
  fi
  
  if command -v apache2 >/dev/null 2>&1; then
    echo "  ✅ Apache: $(apache2 -v 2>&1 | head -n1)"
  else
    echo "  ❌ Apache chưa cài"
  fi
  
  echo -e "\n${GREEN}PHP:${NC}"
  if command -v php >/dev/null 2>&1; then
    echo "  ✅ PHP: $(php -v | head -n1)"
  else
    echo "  ❌ PHP chưa cài"
  fi
  
  echo -e "\n${GREEN}Node.js:${NC}"
  if command -v node >/dev/null 2>&1; then
    echo "  ✅ Node.js: $(node -v)"
    if command -v pm2 >/dev/null 2>&1; then
      echo "  ✅ PM2: $(pm2 -v)"
    else
      echo "  ❌ PM2 chưa cài"
    fi
  else
    echo "  ❌ Node.js chưa cài"
  fi
  
  echo -e "\n${GREEN}Database:${NC}"
  if command -v mysql >/dev/null 2>&1; then
    echo "  ✅ MariaDB/MySQL: $(mysql --version | grep -oP 'Distrib \K[0-9.]+')"
  else
    echo "  ❌ MariaDB/MySQL chưa cài"
  fi
  
  if command -v mongod >/dev/null 2>&1; then
    echo "  ✅ MongoDB: $(mongod --version | head -n1)"
  else
    echo "  ❌ MongoDB chưa cài"
  fi
  
  if command -v psql >/dev/null 2>&1; then
    echo "  ✅ PostgreSQL: $(psql --version)"
  else
    echo "  ❌ PostgreSQL chưa cài"
  fi
  
  if command -v redis-server >/dev/null 2>&1; then
    echo "  ✅ Redis: $(redis-server --version)"
  else
    echo "  ❌ Redis chưa cài"
  fi
  
  echo
}

setup_install_web_stack() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Cài Stack Web (Nginx + PHP + MariaDB)"
  echo "══════════════════════════════════════════════"
  
  read -rp "Xác nhận cài Stack Web? (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    log_info "Đã hủy cài đặt."
    return 0
  fi
  
  log_info "Đang cài Nginx..."
  if [[ "$(type -t nginx_install)" == "function" ]]; then
    nginx_install
  else
    apt update && apt install -y nginx
  fi
  
  log_info "Đang cài PHP + extensions..."
  apt install -y php-fpm php-mysql php-xml php-curl php-gd php-mbstring php-zip
  
  log_info "Đang cài MariaDB..."
  if [[ "$(type -t mariadb_install)" == "function" ]]; then
    mariadb_install
  else
    apt install -y mariadb-server mariadb-client
  fi
  
  log_success "Đã cài xong Stack Web (Nginx + PHP + MariaDB)."
}

setup_install_node_stack() {
  clear
  echo "══════════════════════════════════════════════"
  echo "  Cài Stack Node.js (Node + PM2 + Nginx)"
  echo "══════════════════════════════════════════════"
  
  read -rp "Xác nhận cài Stack Node.js? (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    log_info "Đã hủy cài đặt."
    return 0
  fi
  
  log_info "Đang cài Node.js + PM2..."
  if [[ "$(type -t nodejs_install)" == "function" ]]; then
    nodejs_install
  else
    apt update && apt install -y nodejs npm
    npm install -g pm2
  fi
  
  log_info "Đang cài Nginx (reverse proxy)..."
  if [[ "$(type -t nginx_install)" == "function" ]]; then
    nginx_install
  else
    apt install -y nginx
  fi
  
  log_success "Đã cài xong Stack Node.js (Node + PM2 + Nginx)."
}

setup_install_db_stack() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Cài Stack Database"
  echo "══════════════════════════════════════════════"
  echo "Chọn database muốn cài:"
  echo " 1) MongoDB"
  echo " 2) PostgreSQL"
  echo " 3) Redis"
  echo " 4) Tất cả"
  echo " 0) Quay lại"
  
  read -rp "Lựa chọn: " choice
  
  case "$choice" in
    1)
      if [[ "$(type -t mongo_install)" == "function" ]]; then
        mongo_install
      else
        log_error "Plugin MongoDB chưa được load."
      fi
      ;;
    2)
      if [[ "$(type -t postgres_install)" == "function" ]]; then
        postgres_install
      else
        log_error "Plugin PostgreSQL chưa được load."
      fi
      ;;
    3)
      if [[ "$(type -t redis_install)" == "function" ]]; then
        redis_install
      else
        apt update && apt install -y redis-server
      fi
      ;;
    4)
      [[ "$(type -t mongo_install)" == "function" ]] && mongo_install
      [[ "$(type -t postgres_install)" == "function" ]] && postgres_install
      apt update && apt install -y redis-server
      ;;
    0)
      return 0
      ;;
  esac
}

setup_install_utilities() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Cài thêm tiện ích hệ thống"
  echo "══════════════════════════════════════════════"
  
  log_info "Đang cài các tiện ích: git, fail2ban, ufw, htop, net-tools, certbot..."
  
  apt update
  apt install -y \
    git \
    fail2ban \
    ufw \
    htop \
    net-tools \
    certbot \
    python3-certbot-nginx \
    curl \
    wget \
    unzip \
    vim
  
  log_success "Đã cài xong các tiện ích hệ thống."
}

setup_update_stacks() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Update OLS / Nginx / Node / DB"
  echo "══════════════════════════════════════════════"
  
  read -rp "Xác nhận update tất cả packages? (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    log_info "Đã hủy update."
    return 0
  fi
  
  log_info "Đang update system packages..."
  apt update
  apt upgrade -y
  
  # Update Node.js nếu dùng nvm
  if command -v nvm >/dev/null 2>&1; then
    log_info "Đang update Node.js qua nvm..."
    nvm install --lts
  fi
  
  # Update PM2
  if command -v pm2 >/dev/null 2>&1; then
    log_info "Đang update PM2..."
    npm install -g pm2@latest
  fi
  
  log_success "Đã update xong."
}

setup_check_errors() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Kiểm tra lỗi sau update"
  echo "══════════════════════════════════════════════"
  
  echo -e "\n${GREEN}Kiểm tra services:${NC}"
  
  for svc in nginx mysql mongodb postgresql redis; do
    if systemctl list-unit-files | grep -q "^${svc}"; then
      if systemctl is-active --quiet "${svc}"; then
        echo "  ✅ ${svc}: running"
      else
        echo "  ❌ ${svc}: stopped"
      fi
    fi
  done
  
  echo -e "\n${GREEN}Kiểm tra versions:${NC}"
  command -v nginx >/dev/null && echo "  Nginx: $(nginx -v 2>&1)"
  command -v php >/dev/null && echo "  PHP: $(php -v | head -n1)"
  command -v node >/dev/null && echo "  Node.js: $(node -v)"
  command -v pm2 >/dev/null && echo "  PM2: $(pm2 -v)"
  
  echo
}

setup_uninstall_stack() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Gỡ stack / gỡ dịch vụ"
  echo "══════════════════════════════════════════════"
  echo "Chọn stack muốn gỡ:"
  echo " 1) Gỡ Stack Web (Nginx + PHP + MariaDB)"
  echo " 2) Gỡ Stack Node.js (Node + PM2)"
  echo " 3) Gỡ Stack Database (MongoDB/PostgreSQL/Redis)"
  echo " 0) Quay lại"
  
  read -rp "Lựa chọn: " choice
  
  case "$choice" in
    1)
      log_warn "Bạn sắp gỡ Stack Web. Điều này có thể ảnh hưởng tất cả website."
      read -rp "Gõ YES_REMOVE để xác nhận: " confirm
      if [[ "$confirm" == "YES_REMOVE" ]]; then
        apt purge -y nginx php* mariadb-server mariadb-client
        apt autoremove -y
        log_success "Đã gỡ Stack Web."
      fi
      ;;
    2)
      if [[ "$(type -t nodejs_uninstall)" == "function" ]]; then
        nodejs_uninstall
      else
        apt purge -y nodejs npm
        npm uninstall -g pm2 2>/dev/null || true
      fi
      ;;
    3)
      log_warn "Bạn sắp gỡ tất cả Database."
      read -rp "Gõ YES_REMOVE để xác nhận: " confirm
      if [[ "$confirm" == "YES_REMOVE" ]]; then
        apt purge -y mongodb-org* postgresql* redis-server
        apt autoremove -y
        log_success "Đã gỡ Database stack."
      fi
      ;;
    0)
      return 0
      ;;
  esac
}

setup_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "          Cài đặt hệ thống"
    echo "══════════════════════════════════════════════"
    echo " 1) Chương trình / dịch vụ đã cài đặt"
    echo " 2) Cài Stack Web (Nginx + PHP + MariaDB/MySQL)"
    echo " 3) Cài Stack Node.js (Node + PM2 + Nginx)"
    echo " 4) Cài Stack Database (MongoDB/PostgreSQL/Redis)"
    echo " 5) Cài thêm tiện ích hệ thống"
    echo " 6) Update OLS / Nginx / Node / DB"
    echo " 7) Kiểm tra lỗi sau update"
    echo " 8) Gỡ stack / gỡ dịch vụ"
    echo " 0) Quay lại"
    echo
    read -rp "Chọn chức năng: " choice
    
    case "$choice" in
      1) setup_installed_programs; read -rp "Nhấn Enter..." ;;
      2) setup_install_web_stack; read -rp "Nhấn Enter..." ;;
      3) setup_install_node_stack; read -rp "Nhấn Enter..." ;;
      4) setup_install_db_stack; read -rp "Nhấn Enter..." ;;
      5) setup_install_utilities; read -rp "Nhấn Enter..." ;;
      6) setup_update_stacks; read -rp "Nhấn Enter..." ;;
      7) setup_check_errors; read -rp "Nhấn Enter..." ;;
      8) setup_uninstall_stack; read -rp "Nhấn Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "system-setup" \
  "Cài đặt hệ thống" \
  "SETUP" \
  "" \
  "setup_menu"
