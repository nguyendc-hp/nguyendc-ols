#!/usr/bin/env bash

# ======================================
# Plugin: Nginx
# Project: nguyendc-ols
# ID: nginx
# Category: WEB
# ======================================

NGINX_SERVICE="nginx"
NGINX_STATE_KEY="NGINX_INSTALLED"

nginx_is_installed() {
  dpkg -s nginx >/dev/null 2>&1 || \
  rpm -q nginx >/dev/null 2>&1
}

nginx_status_systemd() {
  systemctl is-active "$NGINX_SERVICE" >/dev/null 2>&1
}

nginx_install() {
  if nginx_is_installed; then
    log_info "Nginx đã được cài đặt, bỏ qua bước cài."
    state_set "$NGINX_STATE_KEY" "1"
    return 0
  fi

  log_info "Bắt đầu cài đặt Nginx..."
  if is_debian_like; then
    apt update
    apt install -y nginx
  elif is_rhel_like; then
    dnf install -y nginx
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ cài Nginx tự động."
    return 1
  fi

  systemctl enable "$NGINX_SERVICE" --now

  if nginx_status_systemd; then
    log_info "Cài đặt Nginx thành công."
    state_set "$NGINX_STATE_KEY" "1"
  else
    log_error "Nginx cài xong nhưng dịch vụ không chạy. Vui lòng kiểm tra log."
    return 1
  fi
}

nginx_uninstall() {
  log_warn "Bạn sắp gỡ bỏ Nginx. Thao tác này sẽ dừng toàn bộ web server."
  read -r -p "Bạn có chắc chắn muốn tiếp tục? (gõ YES_TO_REMOVE_NGINX): " confirm
  if [[ "$confirm" != "YES_TO_REMOVE_NGINX" ]]; then
    log_info "Đã huỷ thao tác gỡ Nginx."
    return 0
  fi

  if is_debian_like; then
    systemctl stop "$NGINX_SERVICE" 2>/dev/null || true
    apt purge -y nginx nginx-common nginx-full
    apt autoremove -y
    read -r -p "Bạn có muốn xoá luôn cấu hình /etc/nginx và web root /var/www? (y/N): " confirm_data
    if [[ "$confirm_data" == "y" || "$confirm_data" == "Y" ]]; then
      rm -rf /etc/nginx
      rm -rf /var/www/*
      log_warn "Đã xoá cấu hình Nginx và web root."
    else
      log_info "Giữ lại cấu hình và web root."
    fi
  elif is_rhel_like; then
    systemctl stop "$NGINX_SERVICE" 2>/dev/null || true
    dnf remove -y nginx
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ gỡ Nginx tự động."
    return 1
  fi

  state_set "$NGINX_STATE_KEY" "0"
  log_info "Đã gỡ Nginx (package)."
}

nginx_enable() {
  if ! nginx_is_installed; then
    log_error "Nginx chưa được cài. Hãy cài trước."
    return 1
  fi

  systemctl enable "$NGINX_SERVICE" --now

  if nginx_status_systemd; then
    log_info "Đã bật Nginx và cho phép khởi động cùng hệ thống."
  else
    log_error "Không thể bật Nginx. Vui lòng kiểm tra lại."
  fi
}

nginx_disable() {
  if ! nginx_is_installed; then
    log_error "Nginx chưa được cài."
    return 1
  fi

  systemctl disable "$NGINX_SERVICE" --now

  if ! nginx_status_systemd; then
    log_info "Đã tắt Nginx và vô hiệu hoá khởi động cùng hệ thống."
  else
    log_warn "Dịch vụ Nginx vẫn còn đang chạy. Vui lòng kiểm tra."
  fi
}

nginx_show_status_line() {
  if nginx_is_installed; then
    if nginx_status_systemd; then
      echo "✅ Đã cài - Đang chạy"
    else
      echo "⏸ Đã cài - Đang tắt"
    fi
  else
    echo "❌ Chưa cài"
  fi
}

nginx_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "           Quản lý Nginx (Plugin)"
    echo "              nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    nginx_show_status_line
    echo
    echo "1) Cài đặt Nginx"
    echo "2) Gỡ bỏ Nginx"
    echo "3) Bật dịch vụ Nginx"
    echo "4) Tắt dịch vụ Nginx"
    echo "5) Xem trạng thái chi tiết (systemctl)"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) nginx_install;  read -rp "Nhấn Enter để tiếp tục..." ;;
      2) nginx_uninstall; read -rp "Nhấn Enter để tiếp tục..." ;;
      3) nginx_enable;   read -rp "Nhấn Enter để tiếp tục..." ;;
      4) nginx_disable;  read -rp "Nhấn Enter để tiếp tục..." ;;
      5) systemctl status "$NGINX_SERVICE"; read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# Đăng ký plugin
ndc_register_plugin \
  "nginx" \
  "Nginx" \
  "WEB" \
  "Cài đặt và quản lý web server Nginx" \
  "nginx_menu"
