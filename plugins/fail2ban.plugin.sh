#!/usr/bin/env bash

# ======================================
# Plugin: Fail2ban
# Project: nguyendc-ols
# ID: fail2ban
# Category: SYSTEM
# ======================================

FAIL2BAN_SERVICE="fail2ban"
FAIL2BAN_STATE_KEY="FAIL2BAN_INSTALLED"

fail2ban_is_installed() {
  dpkg -s fail2ban >/dev/null 2>&1 || \
  rpm -q fail2ban >/dev/null 2>&1
}

fail2ban_status_systemd() {
  systemctl is-active "$FAIL2BAN_SERVICE" >/dev/null 2>&1
}

fail2ban_install() {
  if fail2ban_is_installed; then
    log_info "Fail2ban đã được cài đặt, bỏ qua bước cài."
    state_set "$FAIL2BAN_STATE_KEY" "1"
    return 0
  fi

  log_info "Bắt đầu cài đặt Fail2ban..."

  if is_debian_like; then
    apt update
    apt install -y fail2ban
  elif is_rhel_like; then
    dnf install -y fail2ban
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ cài Fail2ban tự động."
    return 1
  fi

  systemctl enable "$FAIL2BAN_SERVICE" --now

  if fail2ban_status_systemd; then
    log_info "Cài đặt Fail2ban thành công."
    log_info "Bạn có thể tuỳ chỉnh jail trong /etc/fail2ban/jail.local"
    state_set "$FAIL2BAN_STATE_KEY" "1"
  else
    log_error "Fail2ban cài xong nhưng dịch vụ không chạy."
    return 1
  fi
}

fail2ban_uninstall() {
  log_warn "Bạn sắp gỡ Fail2ban. Thao tác này sẽ bỏ lớp bảo vệ chống brute-force."
  read -r -p "Bạn có chắc chắn muốn tiếp tục? (gõ YES_TO_REMOVE_FAIL2BAN): " confirm
  if [[ "$confirm" != "YES_TO_REMOVE_FAIL2BAN" ]]; then
    log_info "Đã huỷ thao tác gỡ Fail2ban."
    return 0
  fi

  systemctl stop "$FAIL2BAN_SERVICE" 2>/dev/null || true

  if is_debian_like; then
    apt purge -y fail2ban
    apt autoremove -y
  elif is_rhel_like; then
    dnf remove -y fail2ban
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ gỡ Fail2ban tự động."
    return 1
  fi

  state_set "$FAIL2BAN_STATE_KEY" "0"
  log_info "Đã gỡ Fail2ban."
}

fail2ban_enable() {
  if ! fail2ban_is_installed; then
    log_error "Fail2ban chưa được cài. Hãy cài trước."
    return 1
  fi

  systemctl enable "$FAIL2BAN_SERVICE" --now
  if fail2ban_status_systemd; then
    log_info "Đã bật Fail2ban."
  else
    log_error "Không thể bật Fail2ban."
  fi
}

fail2ban_disable() {
  if ! fail2ban_is_installed; then
    log_error "Fail2ban chưa được cài."
    return 1
  fi

  systemctl disable "$FAIL2BAN_SERVICE" --now
  if ! fail2ban_status_systemd; then
    log_info "Đã tắt Fail2ban."
  else
    log_warn "Fail2ban vẫn đang chạy. Vui lòng kiểm tra."
  fi
}

fail2ban_show_status_line() {
  if fail2ban_is_installed; then
    if fail2ban_status_systemd; then
      echo "✅ Đã cài - Đang chạy"
    else
      echo "⏸ Đã cài - Đang tắt"
    fi
  else
    echo "❌ Chưa cài"
  fi
}

fail2ban_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "           Quản lý Fail2ban (Plugin)"
    echo "                nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    fail2ban_show_status_line
    echo
    echo "1) Cài đặt Fail2ban"
    echo "2) Gỡ Fail2ban"
    echo "3) Bật Fail2ban"
    echo "4) Tắt Fail2ban"
    echo "5) Xem trạng thái chi tiết (systemctl)"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) fail2ban_install;  read -rp "Nhấn Enter để tiếp tục..." ;;
      2) fail2ban_uninstall; read -rp "Nhấn Enter để tiếp tục..." ;;
      3) fail2ban_enable;   read -rp "Nhấn Enter để tiếp tục..." ;;
      4) fail2ban_disable;  read -rp "Nhấn Enter để tiếp tục..." ;;
      5) systemctl status "$FAIL2BAN_SERVICE"; read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "fail2ban" \
  "Fail2ban" \
  "SYSTEM" \
  "Cài đặt và quản lý Fail2ban chống brute-force" \
  "fail2ban_menu"
