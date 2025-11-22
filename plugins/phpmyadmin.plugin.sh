#!/usr/bin/env bash

# ======================================
# Plugin: phpMyAdmin
# Project: nguyendc-ols
# ID: phpmyadmin
# Category: DB
# ======================================

PHPMYADMIN_STATE_KEY="PHPMYADMIN_INSTALLED"

phpmyadmin_is_installed() {
  dpkg -s phpmyadmin >/dev/null 2>&1 || \
  [ -d /usr/share/phpmyadmin ]
}

phpmyadmin_install() {
  if phpmyadmin_is_installed; then
    log_info "phpMyAdmin đã được cài đặt, bỏ qua bước cài."
    state_set "$PHPMYADMIN_STATE_KEY" "1"
    return 0
  fi

  if ! is_debian_like; then
    log_error "Hiện tại chỉ hỗ trợ cài phpMyAdmin tự động trên hệ Debian/Ubuntu."
    return 1
  fi

  log_info "Bắt đầu cài đặt phpMyAdmin..."
  apt update

  # Cài các dependency cơ bản
  apt install -y php php-mbstring php-zip php-gd php-json php-curl

  # Cài phpMyAdmin (không dùng debconf tự động quá phức tạp, để user cấu hình DB sau)
  apt install -y phpmyadmin

  # Thông thường phpMyAdmin sẽ tự tạo cấu hình Apache.
  # Nếu dùng Nginx, user có thể tự reverse proxy tới /usr/share/phpmyadmin/.

  if phpmyadmin_is_installed; then
    log_info "Cài đặt phpMyAdmin thành công."
    log_info "Đường dẫn mặc định: /usr/share/phpmyadmin (Apache) hoặc cấu hình Nginx proxy đến đó."
    state_set "$PHPMYADMIN_STATE_KEY" "1"
  else
    log_error "phpMyAdmin cài xong nhưng không tìm thấy thư mục cài đặt."
    return 1
  fi
}

phpmyadmin_uninstall() {
  log_warn "Bạn sắp gỡ phpMyAdmin. Thao tác này không xoá database MySQL/MariaDB, chỉ xoá giao diện web."
  read -r -p "Bạn có chắc chắn muốn tiếp tục? (gõ YES_TO_REMOVE_PHPMYADMIN): " confirm
  if [[ "$confirm" != "YES_TO_REMOVE_PHPMYADMIN" ]]; then
    log_info "Đã huỷ thao tác gỡ phpMyAdmin."
    return 0
  fi

  if is_debian_like; then
    apt purge -y phpmyadmin
    apt autoremove -y
    log_info "Đã gỡ phpMyAdmin (package)."
  else
    log_error "Hiện tại chỉ hỗ trợ gỡ phpMyAdmin tự động trên Debian/Ubuntu."
    return 1
  fi

  state_set "$PHPMYADMIN_STATE_KEY" "0"
}

phpmyadmin_show_status_line() {
  if phpmyadmin_is_installed; then
    echo "✅ Đã cài (Debian/Ubuntu) - đường dẫn: /usr/share/phpmyadmin"
  else
    echo "❌ Chưa cài"
  fi
}

phpmyadmin_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "         Quản lý phpMyAdmin (Plugin)"
    echo "                nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    phpmyadmin_show_status_line
    echo
    echo "1) Cài đặt phpMyAdmin"
    echo "2) Gỡ phpMyAdmin"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) phpmyadmin_install;   read -rp "Nhấn Enter để tiếp tục..." ;;
      2) phpmyadmin_uninstall; read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "phpmyadmin" \
  "phpMyAdmin" \
  "DB_GUI" \
  "" \
  "phpmyadmin_menu"
