#!/usr/bin/env bash

# ======================================
# Plugin: Certbot (Let's Encrypt)
# Project: nguyendc-ols
# ID: certbot
# Category: SSL
# ======================================

CERTBOT_STATE_KEY="CERTBOT_INSTALLED"

certbot_is_installed() {
  command -v certbot >/dev/null 2>&1
}

certbot_install() {
  if certbot_is_installed; then
    log_info "Certbot đã được cài đặt, bỏ qua bước cài."
    state_set "$CERTBOT_STATE_KEY" "1"
    return 0
  fi

  log_info "Bắt đầu cài đặt Certbot..."

  if is_debian_like; then
    apt update
    apt install -y certbot python3-certbot-nginx
  elif is_rhel_like; then
    dnf install -y certbot python3-certbot-nginx
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ cài Certbot tự động."
    return 1
  fi

  if certbot_is_installed; then
    log_info "Cài đặt Certbot thành công."
    state_set "$CERTBOT_STATE_KEY" "1"
  else
    log_error "Certbot cài xong nhưng không chạy được."
    return 1
  fi
}

certbot_uninstall() {
  log_warn "Bạn sắp gỡ Certbot. Điều này không xoá chứng chỉ hiện có, chỉ xoá công cụ quản lý."
  read -r -p "Bạn có chắc chắn muốn tiếp tục? (gõ YES_TO_REMOVE_CERTBOT): " confirm
  if [[ "$confirm" != "YES_TO_REMOVE_CERTBOT" ]]; then
    log_info "Đã huỷ thao tác gỡ Certbot."
    return 0
  fi

  if is_debian_like; then
    apt purge -y certbot python3-certbot-nginx
    apt autoremove -y
  elif is_rhel_like; then
    dnf remove -y certbot python3-certbot-nginx
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ gỡ Certbot tự động."
    return 1
  fi

  state_set "$CERTBOT_STATE_KEY" "0"
  log_info "Đã gỡ Certbot."
}

certbot_issue_nginx() {
  if ! certbot_is_installed; then
    log_error "Certbot chưa được cài. Hãy cài trước."
    return 1
  fi

  read -r -p "Nhập domain (VD: example.com): " domain
  read -r -p "Nhập email dùng cho Let's Encrypt (để nhận thông báo hết hạn): " email

  if [[ -z "$domain" || -z "$email" ]]; then
    log_error "Domain và email không được để trống."
    return 1
  fi

  log_info "Bắt đầu tạo/chạy SSL cho domain: $domain"
  certbot --nginx -d "$domain" --non-interactive --agree-tos -m "$email" || {
    log_error "Cấp SSL thất bại. Vui lòng kiểm tra lại cấu hình Nginx và domain."
    return 1
  }

  log_info "Cấp SSL thành công cho $domain."
}

certbot_show_status_line() {
  if certbot_is_installed; then
    echo "✅ Đã cài Certbot"
  else
    echo "❌ Chưa cài Certbot"
  fi
}

certbot_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "     Quản lý SSL Let's Encrypt (Certbot)"
    echo "                nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    certbot_show_status_line
    echo
    echo "1) Cài đặt Certbot"
    echo "2) Gỡ Certbot"
    echo "3) Cấp/chạy SSL cho domain (Nginx)"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) certbot_install;       read -rp "Nhấn Enter để tiếp tục..." ;;
      2) certbot_uninstall;     read -rp "Nhấn Enter để tiếp tục..." ;;
      3) certbot_issue_nginx;   read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "certbot" \
  "Certbot (SSL)" \
  "SSL" \
  "Cài đặt Certbot và cấp SSL Let's Encrypt cho Nginx" \
  "certbot_menu"
