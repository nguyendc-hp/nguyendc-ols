#!/usr/bin/env bash

# ======================================
# Plugin: MongoDB
# Project: nguyendc-ols
# ID: mongo
# Category: DB
# ======================================

MONGO_SERVICE="mongod"
MONGO_STATE_KEY="MONGO_INSTALLED"

mongo_is_installed() {
  dpkg -s mongodb-org >/dev/null 2>&1 || \
  dpkg -s mongodb >/dev/null 2>&1 || \
  rpm -q mongodb-org >/dev/null 2>&1 || \
  rpm -q mongodb >/dev/null 2>&1
}

mongo_status_systemd() {
  systemctl is-active "$MONGO_SERVICE" >/dev/null 2>&1
}

mongo_install() {
  if mongo_is_installed; then
    log_info "MongoDB đã được cài đặt, bỏ qua bước cài."
    state_set "$MONGO_STATE_KEY" "1"
    return 0
  fi

  log_info "Bắt đầu cài đặt MongoDB..."

  if is_debian_like; then
    apt update
    # Thử official package, nếu fail thì fallback về mongodb từ repo distro
    if ! apt install -y mongodb-org; then
      log_warn "Cài mongodb-org thất bại, thử cài mongodb từ repo mặc định."
      apt install -y mongodb
      MONGO_SERVICE="mongodb"
    fi
  elif is_rhel_like; then
    # Tuỳ distro, bạn có thể tinh chỉnh thêm để dùng official repo MongoDB
    if ! dnf install -y mongodb-org; then
      log_warn "Cài mongodb-org thất bại, thử cài mongodb từ repo mặc định."
      dnf install -y mongodb
      MONGO_SERVICE="mongodb"
    fi
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ cài MongoDB tự động."
    return 1
  fi

  systemctl enable "$MONGO_SERVICE" --now

  if mongo_status_systemd; then
    log_info "Cài đặt MongoDB thành công."
    state_set "$MONGO_STATE_KEY" "1"
  else
    log_error "MongoDB cài xong nhưng dịch vụ không chạy. Vui lòng kiểm tra log."
    return 1
  fi
}

mongo_uninstall() {
  log_warn "Bạn sắp gỡ bỏ MongoDB. Thao tác này có thể làm mất dữ liệu database."
  read -r -p "Bạn có chắc chắn muốn tiếp tục? (gõ YES_TO_REMOVE_MONGO): " confirm
  if [[ "$confirm" != "YES_TO_REMOVE_MONGO" ]]; then
    log_info "Đã huỷ thao tác gỡ MongoDB."
    return 0
  fi

  if is_debian_like; then
    systemctl stop "$MONGO_SERVICE" 2>/dev/null || true
    apt purge -y mongodb-org mongodb
    apt autoremove -y

    read -r -p "Bạn có muốn xoá luôn dữ liệu /var/lib/mongodb? (y/N): " confirm_data
    if [[ "$confirm_data" == "y" || "$confirm_data" == "Y" ]]; then
      rm -rf /var/lib/mongodb
      log_warn "Đã xoá dữ liệu MongoDB."
    else
      log_info "Giữ lại dữ liệu MongoDB trong /var/lib/mongodb."
    fi
  elif is_rhel_like; then
    systemctl stop "$MONGO_SERVICE" 2>/dev/null || true
    dnf remove -y mongodb-org mongodb
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ gỡ MongoDB tự động."
    return 1
  fi

  state_set "$MONGO_STATE_KEY" "0"
  log_info "Đã gỡ MongoDB (package)."
}

mongo_enable() {
  if ! mongo_is_installed; then
    log_error "MongoDB chưa được cài. Hãy cài trước."
    return 1
  fi

  systemctl enable "$MONGO_SERVICE" --now

  if mongo_status_systemd; then
    log_info "Đã bật MongoDB và cho phép khởi động cùng hệ thống."
  else
    log_error "Không thể bật MongoDB. Vui lòng kiểm tra lại."
  fi
}

mongo_disable() {
  if ! mongo_is_installed; then
    log_error "MongoDB chưa được cài."
    return 1
  fi

  systemctl disable "$MONGO_SERVICE" --now

  if ! mongo_status_systemd; then
    log_info "Đã tắt MongoDB và vô hiệu hoá khởi động cùng hệ thống."
  else
    log_warn "Dịch vụ MongoDB vẫn còn đang chạy. Vui lòng kiểm tra."
  fi
}

mongo_show_status_line() {
  if mongo_is_installed; then
    if mongo_status_systemd; then
      echo "✅ Đã cài - Đang chạy"
    else
      echo "⏸ Đã cài - Đang tắt"
    fi
  else
    echo "❌ Chưa cài"
  fi
}

mongo_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "           Quản lý MongoDB (Plugin)"
    echo "              nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    mongo_show_status_line
    echo
    echo "1) Cài đặt MongoDB"
    echo "2) Gỡ bỏ MongoDB"
    echo "3) Bật dịch vụ MongoDB"
    echo "4) Tắt dịch vụ MongoDB"
    echo "5) Xem trạng thái chi tiết (systemctl)"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) mongo_install;  read -rp "Nhấn Enter để tiếp tục..." ;;
      2) mongo_uninstall; read -rp "Nhấn Enter để tiếp tục..." ;;
      3) mongo_enable;   read -rp "Nhấn Enter để tiếp tục..." ;;
      4) mongo_disable;  read -rp "Nhấn Enter để tiếp tục..." ;;
      5) systemctl status "$MONGO_SERVICE"; read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# Đăng ký plugin
ndc_register_plugin \
  "mongo" \
  "MongoDB" \
  "DATABASE" \
  "" \
  "mongo_menu"
