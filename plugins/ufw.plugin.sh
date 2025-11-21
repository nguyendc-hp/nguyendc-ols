#!/usr/bin/env bash

# ======================================
# Plugin: UFW Firewall
# Project: nguyendc-ols
# ID: ufw
# Category: SEC
# ======================================

UFW_STATE_KEY="UFW_INSTALLED"

ufw_is_installed() {
  dpkg -s ufw >/dev/null 2>&1
}

ufw_install() {
  if ufw_is_installed; then
    log_info "UFW đã được cài đặt, bỏ qua bước cài."
    state_set "$UFW_STATE_KEY" "1"
    return 0
  fi

  if ! is_debian_like; then
    log_error "Hiện tại chỉ hỗ trợ quản lý UFW trên Debian/Ubuntu."
    return 1
  fi

  log_info "Bắt đầu cài đặt UFW..."
  apt update
  apt install -y ufw

  # Cho phép SSH mặc định
  ufw allow OpenSSH

  log_info "UFW đã được cài đặt. Bạn có thể bật firewall từ menu."
  state_set "$UFW_STATE_KEY" "1"
}

ufw_uninstall() {
  log_warn "Bạn sắp gỡ UFW. Thao tác này sẽ xoá firewall UFW, nhưng không ảnh hưởng iptables thấp hơn."
  read -r -p "Bạn có chắc chắn muốn tiếp tục? (gõ YES_TO_REMOVE_UFW): " confirm
  if [[ "$confirm" != "YES_TO_REMOVE_UFW" ]]; then
    log_info "Đã huỷ thao tác gỡ UFW."
    return 0
  fi

  if ! is_debian_like; then
    log_error "Hiện tại chỉ hỗ trợ gỡ UFW trên Debian/Ubuntu."
    return 1
  fi

  ufw disable || true
  apt purge -y ufw
  apt autoremove -y

  state_set "$UFW_STATE_KEY" "0"
  log_info "Đã gỡ UFW."
}

ufw_enable_firewall() {
  if ! ufw_is_installed; then
    log_error "UFW chưa được cài. Hãy cài trước."
    return 1
  fi

  log_warn "Bạn sắp bật UFW. Hãy đảm bảo đã allow port SSH hoặc rule OpenSSH."
  read -r -p "Xác nhận bật UFW? (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    log_info "Đã huỷ bật UFW."
    return 0
  fi

  ufw enable
  log_info "Đã bật UFW."
}

ufw_disable_firewall() {
  if ! ufw_is_installed; then
    log_error "UFW chưa được cài."
    return 1
  fi

  ufw disable
  log_info "Đã tắt UFW."
}

ufw_show_status_line() {
  if ! ufw_is_installed; then
    echo "❌ Chưa cài"
    return
  fi

  local status
  status="$(ufw status | head -n1 2>/dev/null || echo "")"
  echo "✅ Đã cài - $status"
}

ufw_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "            Quản lý UFW Firewall"
    echo "               nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    ufw_show_status_line
    echo
    echo "1) Cài đặt UFW"
    echo "2) Gỡ UFW"
    echo "3) Bật UFW (enable)"
    echo "4) Tắt UFW (disable)"
    echo "5) Xem chi tiết trạng thái UFW"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) ufw_install;           read -rp "Nhấn Enter để tiếp tục..." ;;
      2) ufw_uninstall;         read -rp "Nhấn Enter để tiếp tục..." ;;
      3) ufw_enable_firewall;   read -rp "Nhấn Enter để tiếp tục..." ;;
      4) ufw_disable_firewall;  read -rp "Nhấn Enter để tiếp tục..." ;;
      5) ufw status verbose;    read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "ufw" \
  "UFW Firewall" \
  "SEC" \
  "Cài đặt và quản lý UFW firewall" \
  "ufw_menu"
