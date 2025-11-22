#!/usr/bin/env bash

# ======================================
# Plugin: MariaDB / MySQL
# Project: nguyendc-ols
# ID: mariadb
# Category: DB
# ======================================

MARIADB_SERVICE="mariadb"
MARIADB_STATE_KEY="MARIADB_INSTALLED"

mariadb_is_installed() {
  dpkg -s mariadb-server >/dev/null 2>&1 || \
  dpkg -s mysql-server >/dev/null 2>&1 || \
  rpm -q mariadb-server >/dev/null 2>&1
}

mariadb_status_systemd() {
  systemctl is-active "$MARIADB_SERVICE" >/dev/null 2>&1
}

mariadb_install() {
  if mariadb_is_installed; then
    log_info "MariaDB/MySQL đã được cài đặt, bỏ qua bước cài."
    state_set "$MARIADB_STATE_KEY" "1"
    return 0
  fi

  log_info "Bắt đầu cài đặt MariaDB/MySQL..."
  if is_debian_like; then
    apt update
    apt install -y mariadb-server
  elif is_rhel_like; then
    dnf install -y mariadb-server
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ cài MariaDB tự động."
    return 1
  fi

  systemctl enable "$MARIADB_SERVICE" --now

  if mariadb_status_systemd; then
    log_info "Cài đặt MariaDB/MySQL thành công."
    state_set "$MARIADB_STATE_KEY" "1"
  else
    log_error "MariaDB cài xong nhưng dịch vụ không chạy. Vui lòng kiểm tra log."
    return 1
  fi
}

mariadb_uninstall() {
  log_warn "Bạn sắp gỡ bỏ MariaDB/MySQL. Thao tác này có thể làm mất dữ liệu database."
  read -r -p "Bạn có chắc chắn muốn tiếp tục? (gõ YES_TO_REMOVE_MARIA): " confirm
  if [[ "$confirm" != "YES_TO_REMOVE_MARIA" ]]; then
    log_info "Đã huỷ thao tác gỡ MariaDB/MySQL."
    return 0
  fi

  if is_debian_like; then
    systemctl stop "$MARIADB_SERVICE" 2>/dev/null || true
    apt purge -y mariadb-server mysql-server
    apt autoremove -y

    read -r -p "Bạn có muốn xoá luôn dữ liệu /var/lib/mysql? (y/N): " confirm_data
    if [[ "$confirm_data" == "y" || "$confirm_data" == "Y" ]]; then
      rm -rf /var/lib/mysql
      log_warn "Đã xoá dữ liệu MariaDB/MySQL."
    else
      log_info "Giữ lại dữ liệu MariaDB/MySQL trong /var/lib/mysql."
    fi
  elif is_rhel_like; then
    systemctl stop "$MARIADB_SERVICE" 2>/dev/null || true
    dnf remove -y mariadb-server
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ gỡ tự động MariaDB/MySQL."
    return 1
  fi

  state_set "$MARIADB_STATE_KEY" "0"
  log_info "Đã gỡ MariaDB/MySQL (package)."
}

mariadb_enable() {
  if ! mariadb_is_installed; then
    log_error "MariaDB/MySQL chưa được cài. Hãy cài trước."
    return 1
  fi

  systemctl enable "$MARIADB_SERVICE" --now

  if mariadb_status_systemd; then
    log_info "Đã bật MariaDB và cho phép khởi động cùng hệ thống."
  else
    log_error "Không thể bật MariaDB. Vui lòng kiểm tra lại."
  fi
}

mariadb_disable() {
  if ! mariadb_is_installed; then
    log_error "MariaDB/MySQL chưa được cài."
    return 1
  fi

  systemctl disable "$MARIADB_SERVICE" --now

  if ! mariadb_status_systemd; then
    log_info "Đã tắt MariaDB và vô hiệu hoá khởi động cùng hệ thống."
  else
    log_warn "Dịch vụ MariaDB vẫn còn đang chạy. Vui lòng kiểm tra."
  fi
}

mariadb_show_status_line() {
  if mariadb_is_installed; then
    if mariadb_status_systemd; then
      echo "✅ Đã cài - Đang chạy"
    else
      echo "⏸ Đã cài - Đang tắt"
    fi
  else
    echo "❌ Chưa cài"
  fi
}

mariadb_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "   Quản lý MariaDB / MySQL (Plugin)"
    echo "              nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    mariadb_show_status_line
    echo
    echo "1) Cài đặt MariaDB/MySQL"
    echo "2) Gỡ bỏ MariaDB/MySQL"
    echo "3) Bật dịch vụ MariaDB"
    echo "4) Tắt dịch vụ MariaDB"
    echo "5) Xem trạng thái chi tiết (systemctl)"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) mariadb_install;  read -rp "Nhấn Enter để tiếp tục..." ;;
      2) mariadb_uninstall; read -rp "Nhấn Enter để tiếp tục..." ;;
      3) mariadb_enable;   read -rp "Nhấn Enter để tiếp tục..." ;;
      4) mariadb_disable;  read -rp "Nhấn Enter để tiếp tục..." ;;
      5) systemctl status "$MARIADB_SERVICE"; read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# Đăng ký plugin
ndc_register_plugin \
  "mariadb" \
  "MariaDB/MySQL" \
  "DATABASE" \
  "" \
  "mariadb_menu"
