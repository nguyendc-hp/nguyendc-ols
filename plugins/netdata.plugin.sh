#!/usr/bin/env bash

# ======================================
# Plugin: Netdata
# Project: nguyendc-ols
# ID: netdata
# Category: OPS
# ======================================

NETDATA_SERVICE="netdata"
NETDATA_STATE_KEY="NETDATA_INSTALLED"

netdata_is_installed() {
  dpkg -s netdata >/dev/null 2>&1 || \
  rpm -q netdata >/dev/null 2>&1 || \
  command -v netdata >/dev/null 2>&1
}

netdata_status_systemd() {
  systemctl is-active "$NETDATA_SERVICE" >/dev/null 2>&1
}

netdata_install() {
  if netdata_is_installed; then
    log_info "Netdata đã được cài đặt, bỏ qua bước cài."
    state_set "$NETDATA_STATE_KEY" "1"
    return 0
  fi

  log_info "Bắt đầu cài đặt Netdata (script chính thức)..."
  bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait || {
    log_error "Cài đặt Netdata thất bại."
    return 1
  }

  systemctl enable "$NETDATA_SERVICE" --now 2>/dev/null || true

  if netdata_status_systemd; then
    log_info "Cài đặt Netdata thành công."
    log_info "Mặc định truy cập: http://<server-ip>:19999"
    state_set "$NETDATA_STATE_KEY" "1"
  else
    log_warn "Netdata cài xong nhưng không thấy dịch vụ đang chạy. Hãy kiểm tra systemctl status netdata."
  fi
}

netdata_uninstall() {
  log_warn "Bạn sắp gỡ Netdata. Thao tác này sẽ xoá monitoring realtime."
  read -r -p "Bạn có chắc chắn muốn tiếp tục? (gõ YES_TO_REMOVE_NETDATA): " confirm
  if [[ "$confirm" != "YES_TO_REMOVE_NETDATA" ]]; then
    log_info "Đã huỷ thao tác gỡ Netdata."
    return 0
  fi

  systemctl stop "$NETDATA_SERVICE" 2>/dev/null || true

  if is_debian_like; then
    apt purge -y netdata || true
    apt autoremove -y || true
  elif is_rhel_like; then
    dnf remove -y netdata || true
  fi

  # Xoá folder cài đặt (tùy script)
  rm -rf /opt/netdata 2>/dev/null || true
  rm -rf /etc/netdata 2>/dev/null || true
  rm -rf /var/lib/netdata 2>/dev/null || true

  state_set "$NETDATA_STATE_KEY" "0"
  log_info "Đã gỡ Netdata (có thể cần kiểm tra lại thủ công)."
}

netdata_show_status_line() {
  if netdata_is_installed; then
    if netdata_status_systemd; then
      echo "✅ Đã cài - Đang chạy (port 19999)"
    else
      echo "⏸ Đã cài - Đang tắt"
    fi
  else
    echo "❌ Chưa cài"
  fi
}

netdata_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "           Quản lý Netdata (Monitoring)"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    netdata_show_status_line
    echo
    echo "1) Cài đặt Netdata"
    echo "2) Gỡ Netdata"
    echo "3) Xem trạng thái chi tiết (systemctl)"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) netdata_install;   read -rp "Nhấn Enter để tiếp tục..." ;;
      2) netdata_uninstall; read -rp "Nhấn Enter để tiếp tục..." ;;
      3) systemctl status "$NETDATA_SERVICE"; read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "netdata" \
  "Netdata" \
  "OPS" \
  "Cài đặt và quản lý Netdata (monitoring realtime)" \
  "netdata_menu"
