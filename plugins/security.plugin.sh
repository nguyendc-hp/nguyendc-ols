#!/usr/bin/env bash

# ======================================
# Plugin: Bảo mật máy chủ
# Category: SECURITY
# ======================================

security_ufw_config() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Cấu hình UFW"
  echo "══════════════════════════════════════════════"
  
  if ! command -v ufw >/dev/null 2>&1; then
    log_info "Đang cài UFW..."
    apt update && apt install -y ufw
  fi
  
  log_info "Cấu hình UFW - mở port cơ bản..."
  
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 22/tcp    # SSH
  ufw allow 80/tcp    # HTTP
  ufw allow 443/tcp   # HTTPS
  
  read -rp "Bật UFW ngay bây giờ? (y/N): " confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    echo "y" | ufw enable
    log_success "Đã bật UFW."
  fi
  
  ufw status verbose
}

security_fail2ban_config() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Cấu hình Fail2ban"
  echo "══════════════════════════════════════════════"
  
  if ! command -v fail2ban-client >/dev/null 2>&1; then
    log_info "Đang cài Fail2ban..."
    apt update && apt install -y fail2ban
  fi
  
  log_info "Cấu hình Fail2ban cho SSH và HTTP..."
  
  cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 22

[nginx-http-auth]
enabled = true
EOF
  
  systemctl restart fail2ban
  log_success "Đã cấu hình Fail2ban."
}

security_ssh_config() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Cấu hình SSH"
  echo "══════════════════════════════════════════════"
  echo " 1) Đổi port SSH"
  echo " 2) Disable root login"
  echo " 3) Chỉ cho phép key auth"
  echo " 0) Quay lại"
  
  read -rp "Chọn: " choice
  
  case "$choice" in
    1)
      read -rp "Nhập port SSH mới (mặc định 22): " new_port
      new_port="${new_port:-22}"
      sed -i "s/^#*Port .*/Port ${new_port}/" /etc/ssh/sshd_config
      systemctl restart sshd
      log_success "Đã đổi SSH port thành: $new_port"
      log_warn "Nhớ mở port mới trong UFW: ufw allow ${new_port}/tcp"
      ;;
    2)
      sed -i "s/^#*PermitRootLogin .*/PermitRootLogin no/" /etc/ssh/sshd_config
      systemctl restart sshd
      log_success "Đã disable root login."
      ;;
    3)
      sed -i "s/^#*PasswordAuthentication .*/PasswordAuthentication no/" /etc/ssh/sshd_config
      systemctl restart sshd
      log_success "Đã bật chỉ key auth."
      ;;
  esac
}

security_nginx_ratelimit() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Chặn bot / rate limit trên Nginx"
  echo "══════════════════════════════════════════════"
  
  log_info "Thêm rate limit vào Nginx config..."
  
  cat > /etc/nginx/conf.d/ratelimit.conf <<'EOF'
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
limit_req zone=general burst=20 nodelay;
EOF
  
  nginx -t && systemctl reload nginx
  
  log_success "Đã cấu hình rate limit cho Nginx."
}

security_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "          Bảo mật máy chủ"
    echo "══════════════════════════════════════════════"
    echo " 1) Cấu hình UFW"
    echo " 2) Cấu hình Fail2ban"
    echo " 3) Cấu hình SSH"
    echo " 4) Chặn bot / rate limit trên Nginx"
    echo " 0) Quay lại"
    echo
    read -rp "Chọn chức năng: " choice
    
    case "$choice" in
      1) security_ufw_config; read -rp "Nhấn Enter..." ;;
      2) security_fail2ban_config; read -rp "Nhấn Enter..." ;;
      3) security_ssh_config; read -rp "Nhấn Enter..." ;;
      4) security_nginx_ratelimit; read -rp "Nhấn Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "security" \
  "Bảo mật máy chủ" \
  "SECURITY" \
  "" \
  "security_menu"
