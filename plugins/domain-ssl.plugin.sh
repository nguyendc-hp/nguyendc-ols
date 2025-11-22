#!/usr/bin/env bash

# ======================================
# Plugin: Quản lý domain & SSL
# Category: DOMAIN_SSL
# ======================================

DOMAIN_LIST_FILE="/etc/nguyendc-ols/domains.txt"

domain_list() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Quản lý danh sách domain trên server"
  echo "══════════════════════════════════════════════"
  
  if [[ -f "$DOMAIN_LIST_FILE" ]]; then
    echo -e "\n${GREEN}Danh sách domain:${NC}"
    cat "$DOMAIN_LIST_FILE"
  else
    echo "Chưa có domain nào được quản lý."
  fi
  echo
}

domain_add() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Thêm domain mới"
  echo "══════════════════════════════════════════════"
  
  read -rp "Nhập domain mới (VD: example.com): " domain
  if [[ -z "$domain" ]]; then
    log_error "Domain không được để trống."
    return 1
  fi
  
  mkdir -p "$(dirname "$DOMAIN_LIST_FILE")"
  echo "$domain" >> "$DOMAIN_LIST_FILE"
  log_success "Đã thêm domain: $domain"
}

domain_remove() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Xóa domain"
  echo "══════════════════════════════════════════════"
  
  if [[ ! -f "$DOMAIN_LIST_FILE" ]]; then
    log_error "Chưa có domain nào."
    return 1
  fi
  
  cat -n "$DOMAIN_LIST_FILE"
  read -rp "Nhập số thứ tự domain cần xóa: " num
  
  if [[ -z "$num" ]] || ! [[ "$num" =~ ^[0-9]+$ ]]; then
    log_error "Số thứ tự không hợp lệ."
    return 1
  fi
  
  sed -i "${num}d" "$DOMAIN_LIST_FILE"
  log_success "Đã xóa domain."
}

domain_assign_site() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Gắn domain vào site / app"
  echo "══════════════════════════════════════════════"
  
  read -rp "Nhập domain: " domain
  read -rp "Nhập webroot (VD: /var/www/site1): " webroot
  
  if [[ -z "$domain" || -z "$webroot" ]]; then
    log_error "Domain và webroot không được để trống."
    return 1
  fi
  
  log_info "Tạo Nginx vhost cho $domain..."
  
  cat > "/etc/nginx/sites-available/${domain}.conf" <<EOF
server {
    listen 80;
    server_name ${domain};
    root ${webroot};
    index index.php index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
EOF
  
  ln -sf "/etc/nginx/sites-available/${domain}.conf" "/etc/nginx/sites-enabled/${domain}.conf"
  nginx -t && systemctl reload nginx
  
  log_success "Đã gắn domain $domain vào $webroot"
}

domain_change_app() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Chuyển domain sang app khác"
  echo "══════════════════════════════════════════════"
  
  read -rp "Nhập domain cần chuyển: " domain
  read -rp "Nhập webroot mới: " new_webroot
  
  if [[ -z "$domain" || -z "$new_webroot" ]]; then
    log_error "Domain và webroot không được để trống."
    return 1
  fi
  
  local conf="/etc/nginx/sites-available/${domain}.conf"
  if [[ ! -f "$conf" ]]; then
    log_error "Không tìm thấy config cho domain: $domain"
    return 1
  fi
  
  sed -i "s|root .*;|root ${new_webroot};|" "$conf"
  nginx -t && systemctl reload nginx
  
  log_success "Đã chuyển domain $domain sang $new_webroot"
}

ssl_issue() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Cấp SSL mới (Let's Encrypt)"
  echo "══════════════════════════════════════════════"
  
  read -rp "Nhập domain cần cấp SSL: " domain
  read -rp "Nhập email Let's Encrypt: " email
  
  if [[ -z "$domain" || -z "$email" ]]; then
    log_error "Domain và email không được để trống."
    return 1
  fi
  
  if ! command -v certbot >/dev/null 2>&1; then
    log_info "Đang cài Certbot..."
    apt update && apt install -y certbot python3-certbot-nginx
  fi
  
  certbot --nginx -d "$domain" --email "$email" --agree-tos --non-interactive
  
  log_success "Đã cấp SSL cho domain: $domain"
}

ssl_renew() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Gia hạn SSL"
  echo "══════════════════════════════════════════════"
  
  if ! command -v certbot >/dev/null 2>&1; then
    log_error "Certbot chưa được cài."
    return 1
  fi
  
  log_info "Đang gia hạn tất cả SSL certificates..."
  certbot renew
  
  log_success "Đã gia hạn SSL."
}

ssl_check() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Kiểm tra & sửa lỗi SSL"
  echo "══════════════════════════════════════════════"
  
  if ! command -v certbot >/dev/null 2>&1; then
    log_error "Certbot chưa được cài."
    return 1
  fi
  
  certbot certificates
  echo
}

domain_ssl_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "          Quản lý domain & SSL"
    echo "══════════════════════════════════════════════"
    echo " 1) Quản lý danh sách domain trên server"
    echo " 2) Thêm domain mới"
    echo " 3) Xóa domain"
    echo " 4) Gắn domain vào site / app"
    echo " 5) Chuyển domain sang app khác"
    echo " 6) Cấp SSL mới (Let's Encrypt)"
    echo " 7) Gia hạn SSL"
    echo " 8) Kiểm tra & sửa lỗi SSL"
    echo " 0) Quay lại"
    echo
    read -rp "Chọn chức năng: " choice
    
    case "$choice" in
      1) domain_list; read -rp "Nhấn Enter..." ;;
      2) domain_add; read -rp "Nhấn Enter..." ;;
      3) domain_remove; read -rp "Nhấn Enter..." ;;
      4) domain_assign_site; read -rp "Nhấn Enter..." ;;
      5) domain_change_app; read -rp "Nhấn Enter..." ;;
      6) ssl_issue; read -rp "Nhấn Enter..." ;;
      7) ssl_renew; read -rp "Nhấn Enter..." ;;
      8) ssl_check; read -rp "Nhấn Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "domain-ssl" \
  "Quản lý domain & SSL" \
  "DOMAIN_SSL" \
  "" \
  "domain_ssl_menu"
