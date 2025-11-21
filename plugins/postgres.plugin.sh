#!/usr/bin/env bash

# ======================================
# Plugin: PostgreSQL
# Project: nguyendc-ols
# ID: postgres
# Category: DB
# ======================================

POSTGRES_SERVICE="postgresql"
POSTGRES_STATE_KEY="POSTGRES_INSTALLED"

postgres_is_installed() {
  dpkg -s postgresql >/dev/null 2>&1 || rpm -q postgresql-server >/dev/null 2>&1
}

postgres_status_systemd() {
  systemctl is-active "$POSTGRES_SERVICE" >/dev/null 2>&1
}

postgres_install() {
  if postgres_is_installed; then
    log_info "PostgreSQL đã được cài đặt, bỏ qua bước cài."
    state_set "$POSTGRES_STATE_KEY" "1"
    return 0
  fi

  log_info "Bắt đầu cài đặt PostgreSQL..."
  if is_debian_like; then
    apt update
    apt install -y postgresql postgresql-contrib
  elif is_rhel_like; then
    dnf install -y postgresql-server postgresql-contrib
    postgresql-setup --initdb
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ cài PostgreSQL tự động."
    return 1
  fi

  systemctl enable "$POSTGRES_SERVICE" --now
  if postgres_status_systemd; then
    log_info "Cài đặt PostgreSQL thành công."
    state_set "$POSTGRES_STATE_KEY" "1"
  else
    log_error "PostgreSQL cài xong nhưng dịch vụ không chạy. Vui lòng kiểm tra log."
    return 1
  fi
}

postgres_uninstall() {
  log_warn "Bạn sắp gỡ bỏ PostgreSQL. Thao tác này có thể làm mất dữ liệu database."
  read -r -p "Bạn có chắc chắn muốn tiếp tục? (gõ YES_TO_REMOVE_PG): " confirm
  if [[ "$confirm" != "YES_TO_REMOVE_PG" ]]; then
    log_info "Đã huỷ thao tác gỡ PostgreSQL."
    return 0
  fi

  if is_debian_like; then
    systemctl stop "$POSTGRES_SERVICE" 2>/dev/null || true
    apt purge -y "postgresql*"
    apt autoremove -y
    read -r -p "Bạn có muốn xoá luôn dữ liệu /var/lib/postgresql? (y/N): " confirm_data
    if [[ "$confirm_data" == "y" || "$confirm_data" == "Y" ]]; then
      rm -rf /var/lib/postgresql
      log_warn "Đã xoá dữ liệu PostgreSQL."
    else
      log_info "Giữ lại dữ liệu PostgreSQL trong /var/lib/postgresql."
    fi
  elif is_rhel_like; then
    systemctl stop "$POSTGRES_SERVICE" 2>/dev/null || true
    dnf remove -y postgresql-server postgresql-contrib
  fi

  state_set "$POSTGRES_STATE_KEY" "0"
  log_info "Đã gỡ PostgreSQL (package)."
}

postgres_enable() {
  if ! postgres_is_installed; then
    log_error "PostgreSQL chưa được cài. Hãy cài trước."
    return 1
  fi
  systemctl enable "$POSTGRES_SERVICE" --now
  if postgres_status_systemd; then
    log_info "Đã bật PostgreSQL và cho phép khởi động cùng hệ thống."
  else
    log_error "Không thể bật PostgreSQL. Vui lòng kiểm tra lại."
  fi
}

postgres_disable() {
  if ! postgres_is_installed; then
    log_error "PostgreSQL chưa được cài."
    return 1
  fi
  systemctl disable "$POSTGRES_SERVICE" --now
  if ! postgres_status_systemd; then
    log_info "Đã tắt PostgreSQL và vô hiệu hoá khởi động cùng hệ thống."
  else
    log_warn "Dịch vụ PostgreSQL vẫn còn đang chạy. Vui lòng kiểm tra."
  fi
}

postgres_show_status_line() {
  if postgres_is_installed; then
    if postgres_status_systemd; then
      echo "✅ Đã cài - Đang chạy"
    else
      echo "⏸ Đã cài - Đang tắt"
    fi
  else
    echo "❌ Chưa cài"
  fi
}

postgres_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "       Quản lý PostgreSQL (Plugin)"
    echo "         nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    postgres_show_status_line
    echo
    echo "1) Cài đặt PostgreSQL"
    echo "2) Gỡ bỏ PostgreSQL"
    echo "3) Bật dịch vụ PostgreSQL"
    echo "4) Tắt dịch vụ PostgreSQL"
    echo "5) Xem trạng thái chi tiết (systemctl)"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) postgres_install; read -rp "Nhấn Enter để tiếp tục..." ;;
      2) postgres_uninstall; read -rp "Nhấn Enter để tiếp tục..." ;;
      3) postgres_enable; read -rp "Nhấn Enter để tiếp tục..." ;;
      4) postgres_disable; read -rp "Nhấn Enter để tiếp tục..." ;;
      5) systemctl status "$POSTGRES_SERVICE"; read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# Đăng ký plugin vào core
ndc_register_plugin \
  "postgres" \
  "PostgreSQL" \
  "DB" \
  "Cài đặt và quản lý PostgreSQL" \
  "postgres_menu"
