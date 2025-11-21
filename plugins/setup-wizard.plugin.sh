#!/usr/bin/env bash

# ======================================
# Plugin: First-time Setup Wizard
# Project: nguyendc-ols
# ID: setupwizard
# Category: SYSTEM
# ======================================

# Helper: check function tồn tại
sw_check_func() {
  local func="$1"
  if [[ "$(type -t "$func")" != "function" ]]; then
    log_error "Hàm ${func} không tồn tại. Có thể plugin liên quan chưa được load."
    return 1
  fi
  return 0
}

sw_prompt_domain_email() {
  local __domain_var="$1"
  local __email_var="$2"

  local d e
  read -r -p "Nhập domain chính cho website (VD: example.com): " d
  read -r -p "Nhập email dùng cho SSL (Let's Encrypt) & liên hệ: " e

  if [[ -z "$d" || -z "$e" ]]; then
    log_error "Domain và email không được để trống."
    return 1
  fi

  eval "$__domain_var=\"$d\""
  eval "$__email_var=\"$e\""
  return 0
}

# ======================================
# 1. Combo WordPress
# ======================================

sw_wordpress_stack_install() {
  echo "══════════════════════════════════════════════"
  echo "     First-time Setup Wizard: WordPress"
  echo "══════════════════════════════════════════════"
  echo "Stack sẽ cài và cấu hình:"
  echo " - Nginx (web server)"
  echo " - MariaDB/MySQL"
  echo " - phpMyAdmin"
  echo " - PHP + extension cơ bản"
  echo " - WordPress (download mới nhất)"
  echo " - Nginx vhost cho domain"
  echo " - Certbot SSL (Let's Encrypt) cho domain (tùy chọn)"
  echo
  read -r -p "Xác nhận cài combo WordPress? (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    log_info "Đã huỷ wizard WordPress."
    return 0
  fi

  # 1. Cài plugin nền tảng
  if sw_check_func "nginx_install"; then
    nginx_install || log_error "Cài Nginx lỗi."
  fi

  if sw_check_func "mariadb_install"; then
    mariadb_install || log_error "Cài MariaDB/MySQL lỗi."
  fi

  if sw_check_func "phpmyadmin_install"; then
    phpmyadmin_install || log_error "Cài phpMyAdmin lỗi."
  fi

  # PHP + extension (trực tiếp, vì chưa có plugin PHP riêng)
  log_info "Cài PHP và các extension cơ bản cho WordPress..."
  if is_debian_like; then
    apt update
    apt install -y php-fpm php-mysql php-xml php-curl php-gd php-mbstring php-zip
  elif is_rhel_like; then
    dnf install -y php php-fpm php-mysqlnd php-xml php-curl php-gd php-mbstring php-zip
  else
    log_warn "Hệ điều hành hiện tại chưa được script hoá PHP. Bạn cần cài PHP thủ công."
  fi

  # 2. Hỏi domain + email
  local domain email
  sw_prompt_domain_email domain email || return 1

  # 3. Hỏi thông tin DB
  local db_name db_user db_pass
  read -r -p "Tên database cho WordPress (VD: wp_${domain//./_}): " db_name
  db_name="${db_name:-wp_${domain//./_}}"

  read -r -p "Tên user DB (VD: wpuser): " db_user
  db_user="${db_user:-wpuser}"

  read -r -p "Mật khẩu DB: " db_pass

  if [[ -z "$db_pass" ]]; then
    log_error "Mật khẩu DB không được để trống."
    return 1
  fi

  # 4. Tạo DB + user
  log_info "Tạo database và user cho WordPress..."
  mysql -uroot <<EOF 2>/tmp/sw-wp-db.log
CREATE DATABASE IF NOT EXISTS \`${db_name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';
GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO '${db_user}'@'localhost';
FLUSH PRIVILEGES;
EOF

  if [[ $? -ne 0 ]]; then
    log_warn "Tạo DB/user có lỗi (xem /tmp/sw-wp-db.log). Hãy kiểm tra lại quyền MySQL root."
  else
    log_info "Đã tạo DB '${db_name}' và user '${db_user}'."
  fi

  # 5. Web root & WordPress
  local webroot="/var/www/${domain}"
  read -r -p "Thư mục web root cho WordPress (mặc định: ${webroot}): " webroot_input
  webroot="${webroot_input:-$webroot}"

  mkdir -p "$webroot"
  cd "$webroot" || {
    log_error "Không thể cd vào ${webroot}."
    return 1
  }

  log_info "Tải WordPress mới nhất về ${webroot}..."
  wget -q https://wordpress.org/latest.tar.gz -O latest.tar.gz || {
    log_error "Tải WordPress thất bại."
    return 1
  }

  tar -xzf latest.tar.gz --strip-components=1
  rm -f latest.tar.gz

  cp wp-config-sample.php wp-config.php

  # Sửa wp-config.php
  sed -i "s/database_name_here/${db_name}/" wp-config.php
  sed -i "s/username_here/${db_user}/" wp-config.php
  sed -i "s/password_here/${db_pass}/" wp-config.php

  chown -R www-data:www-data "$webroot" 2>/dev/null || true
  find "$webroot" -type d -exec chmod 755 {} \; 2>/dev/null || true
  find "$webroot" -type f -exec chmod 644 {} \; 2>/dev/null || true

  log_info "Đã chuẩn bị mã nguồn WordPress tại ${webroot}."

  # 6. Nginx vhost cho WordPress
  local conf="/etc/nginx/sites-available/${domain}.conf"
  mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

  cat > "$conf" <<EOF
server {
    listen 80;
    server_name ${domain};

    root ${webroot};
    index index.php index.html index.htm;

    access_log /var/log/nginx/${domain}_access.log;
    error_log  /var/log/nginx/${domain}_error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        try_files \$uri \$uri/ @fallback;
        expires max;
        log_not_found off;
    }

    location @fallback {
        try_files \$uri \$uri/ /index.php?\$args;
    }
}
EOF

  ln -sf "$conf" "/etc/nginx/sites-enabled/${domain}.conf"

  # Đảm bảo include sites-enabled
  if ! grep -q "/etc/nginx/sites-enabled" /etc/nginx/nginx.conf 2>/dev/null; then
    log_info "Thêm include sites-enabled vào /etc/nginx/nginx.conf"
    sed -i "/http {/a \    include /etc/nginx/sites-enabled/*;" /etc/nginx/nginx.conf
  fi

  nginx -t || {
    log_error "Cấu hình Nginx lỗi. Kiểm tra file ${conf}."
    return 1
  }

  systemctl reload nginx
  log_info "Đã cấu hình Nginx vhost cho ${domain}."

  # 7. SSL với Certbot (tuỳ chọn)
  if sw_check_func "certbot_install"; then
    read -r -p "Bạn có muốn cài Certbot và cấp SSL cho domain này luôn không? (y/N): " ssl_confirm
    if [[ "$ssl_confirm" == "y" || "$ssl_confirm" == "Y" ]]; then
      certbot_install || log_error "Cài Certbot lỗi."
      # gọi certbot_issue_nginx nếu có
      if [[ "$(type -t certbot_issue_nginx)" == "function" ]]; then
        log_info "Chạy Certbot cấp SSL cho ${domain}..."
        certbot_issue_nginx "${domain}" "${email}" || log_warn "Cấp SSL thất bại. Bạn có thể chạy lại sau."
      else
        log_warn "Plugin Certbot chưa có hàm certbot_issue_nginx, bạn cần tự chạy certbot bằng tay."
      fi
    fi
  fi

  log_info "Hoàn tất First-time Setup combo WordPress cho domain: http://${domain}"
  echo "Bạn hãy mở trình duyệt và truy cập domain để hoàn thành bước cài đặt qua giao diện WordPress."
}

# ======================================
# 2. Combo Node.js / React
# ======================================

sw_node_react_stack_install() {
  echo "══════════════════════════════════════════════"
  echo "   First-time Setup Wizard: Node.js / React"
  echo "══════════════════════════════════════════════"
  echo "Stack sẽ cài và cấu hình:"
  echo " - Nginx (reverse proxy)"
  echo " - Node.js + PM2"
  echo " - Database (MongoDB hoặc PostgreSQL hoặc MariaDB, tuỳ chọn)"
  echo " - Deploy 1 app Node/React từ Git (dùng plugin appnode nếu có)"
  echo " - Nginx vhost & (tuỳ chọn) Certbot SSL"
  echo
  read -r -p "Xác nhận cài combo Node.js / React? (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    log_info "Đã huỷ wizard Node/React."
    return 0
  fi

  # Nginx
  if sw_check_func "nginx_install"; then
    nginx_install || log_error "Cài Nginx lỗi."
  fi

  # Node.js + PM2
  if sw_check_func "nodejs_install"; then
    nodejs_install || log_error "Cài Node.js/PM2 lỗi."
  fi

  # Hỏi chọn DB
  echo "Chọn loại database muốn sử dụng:"
  echo " 1) MongoDB"
  echo " 2) PostgreSQL"
  echo " 3) MariaDB/MySQL"
  echo " 0) Bỏ qua (không cài DB)"
  read -rp "Lựa chọn: " db_choice

  case "$db_choice" in
    1)
      if sw_check_func "mongo_install"; then
        mongo_install || log_error "Cài MongoDB lỗi."
      else
        log_warn "Plugin MongoDB chưa load/hàm mongo_install không tồn tại."
      fi
      ;;
    2)
      if sw_check_func "postgres_install"; then
        postgres_install || log_error "Cài PostgreSQL lỗi."
      else
        log_warn "Plugin PostgreSQL chưa load/hàm postgres_install không tồn tại."
      fi
      ;;
    3)
      if sw_check_func "mariadb_install"; then
        mariadb_install || log_error "Cài MariaDB/MySQL lỗi."
      else
        log_warn "Plugin MariaDB chưa load/hàm mariadb_install không tồn tại."
      fi
      ;;
    0)
      log_info "Bỏ qua bước cài DB."
      ;;
    *)
      log_warn "Lựa chọn không hợp lệ, bỏ qua cài DB."
      ;;
  esac

  # Deploy app Node/React
  echo
  echo "Bạn có muốn deploy 1 app Node/React ngay bây giờ không?"
  echo " - Nếu có plugin appnode, wizard sẽ dùng appnode_deploy."
  read -r -p "Deploy app luôn? (y/N): " deploy_choice
  if [[ "$deploy_choice" == "y" || "$deploy_choice" == "Y" ]]; then
    if sw_check_func "appnode_deploy"; then
      appnode_deploy
    else
      log_warn "Plugin appnode chưa load/hàm appnode_deploy không tồn tại. Bạn cần deploy app thủ công."
    fi
  fi

  # SSL (tuỳ chọn)
  if sw_check_func "certbot_install"; then
    read -r -p "Bạn có muốn cài Certbot và cấp SSL cho domain app Node/React không? (y/N): " ssl_confirm
    if [[ "$ssl_confirm" == "y" || "$ssl_confirm" == "Y" ]]; then
      certbot_install || log_error "Cài Certbot lỗi."
      echo "Lưu ý: Certbot sẽ hỏi domain tương ứng với vhost Nginx bạn đã cấu hình."
      if [[ "$(type -t certbot_issue_nginx)" == "function" ]]; then
        read -r -p "Nhập domain app Node/React để Certbot xử lý: " node_domain
        read -r -p "Nhập email cho Let's Encrypt: " node_email
        [[ -n "$node_domain" && -n "$node_email" ]] && \
          certbot_issue_nginx "${node_domain}" "${node_email}" || \
          log_warn "Không đủ thông tin để cấp SSL."
      else
        log_warn "Plugin Certbot chưa có hàm certbot_issue_nginx. Hãy tự chạy certbot sau."
      fi
    fi
  fi

  log_info "Hoàn tất First-time Setup combo Node.js / React (ở mức cơ bản)."
}

# ======================================
# 3. Cấu hình nhanh Monitoring + Alert
# ======================================

sw_monitoring_alert_setup() {
  echo "══════════════════════════════════════════════"
  echo "   Wizard: Monitoring & Telegram Alerts"
  echo "══════════════════════════════════════════════"
  echo "Chức năng:"
  echo " - Thiết lập Telegram Bot (Token + Chat ID)"
  echo " - Chạy thử healthcheck / httpcheck / processwatch"
  echo " - Gợi ý cấu hình cron cho các check này"
  echo

  # Telegram
  if [[ "$(type -t telegram_set_token)" == "function" && "$(type -t telegram_set_chatid)" == "function" ]]; then
    read -r -p "Thiết lập Telegram Bot ngay bây giờ? (y/N): " tele_choice
    if [[ "$tele_choice" == "y" || "$tele_choice" == "Y" ]]; then
      telegram_set_token
      telegram_set_chatid
      telegram_test_message
    fi
  else
    log_warn "Plugin Telegram chưa được load (không có hàm telegram_set_token / telegram_set_chatid)."
  fi

  # Healthcheck
  if [[ "$(type -t healthcheck_run_once)" == "function" ]]; then
    echo
    read -r -p "Chạy thử healthcheck ngay bây giờ? (y/N): " hc_choice
    if [[ "$hc_choice" == "y" || "$hc_choice" == "Y" ]]; then
      healthcheck_run_once
    fi
  else
    log_warn "Plugin healthcheck chưa load."
  fi

  # HTTP check
  if [[ "$(type -t httpcheck_run_once)" == "function" ]]; then
    echo
    read -r -p "Bạn có muốn thêm 1 endpoint HTTP để theo dõi không? (y/N): " hch_add
    if [[ "$hch_add" == "y" || "$hch_add" == "Y" ]]; then
      httpcheck_add
    fi
  else
    log_warn "Plugin httpcheck chưa load."
  fi

  # Process watch
  if [[ "$(type -t processwatch_run_once)" == "function" ]]; then
    echo
    read -r -p "Bạn có muốn thêm 1 service/process cần theo dõi không? (y/N): " pw_add
    if [[ "$pw_add" == "y" || "$pw_add" == "Y" ]]; then
      processwatch_add
    fi
  else
    log_warn "Plugin processwatch chưa load."
  fi

  echo
  echo "Gợi ý cấu hình cron (bạn tự thêm vào crontab -e của root):"
  echo "----------------------------------------------------------"
  echo "*/5 * * * * /path/to/nguyendc-ols.sh healthcheck run >/dev/null 2>&1"
  echo "*/2 * * * * /path/to/nguyendc-ols.sh processwatch run >/dev/null 2>&1"
  echo "*  * * * * /path/to/nguyendc-ols.sh httpcheck run    >/dev/null 2>&1"
  echo "----------------------------------------------------------"
  echo "Hãy thay /path/to/nguyendc-ols.sh bằng đường dẫn thực tế trên VPS của bạn."
}

# ======================================
# Menu Wizard
# ======================================

setupwizard_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "          First-time Setup Wizard"
    echo "               nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "Chọn chế độ wizard:"
    echo " 1) Combo WordPress (Nginx + MariaDB + PHP + WP)"
    echo " 2) Combo Node.js / React (Nginx + Node/PM2 + DB)"
    echo " 3) Cấu hình Monitoring + Telegram Alerts"
    echo " 0) Quay lại menu trước"
    echo
    read -rp "Lựa chọn: " choice
    case "$choice" in
      1) sw_wordpress_stack_install;        read -rp "Nhấn Enter để tiếp tục..." ;;
      2) sw_node_react_stack_install;       read -rp "Nhấn Enter để tiếp tục..." ;;
      3) sw_monitoring_alert_setup;         read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh setupwizard wordpress|node|monitor
setupwizard_cli() {
  local subcmd="$1"
  case "$subcmd" in
    wordpress)
      sw_wordpress_stack_install
      ;;
    node|nodejs|react)
      sw_node_react_stack_install
      ;;
    monitor|mon|alert)
      sw_monitoring_alert_setup
      ;;
    ""|menu)
      setupwizard_menu
      ;;
    *)
      echo "Setup Wizard CLI:"
      echo "  setupwizard wordpress   - chạy wizard combo WordPress"
      echo "  setupwizard node        - chạy wizard combo Node.js/React"
      echo "  setupwizard monitor     - chạy wizard cấu hình monitoring & Telegram"
      echo
      return 1
      ;;
  esac
}

ndc_register_plugin \
  "setupwizard" \
  "First-time Setup Wizard" \
  "SYSTEM" \
  "Wizard cài combo WordPress / Node.js-React & Monitoring/Alert" \
  "setupwizard_menu"
