#!/usr/bin/env bash

# ======================================
# Plugin: Redis
# Project: nguyendc-ols
# ID: redis
# Category: CACHE
# ======================================

REDIS_SERVICE="redis-server"
REDIS_STATE_KEY="REDIS_INSTALLED"

redis_is_installed() {
  dpkg -s redis-server >/dev/null 2>&1 || \
  rpm -q redis >/dev/null 2>&1
}

redis_status_systemd() {
  systemctl is-active "$REDIS_SERVICE" >/dev/null 2>&1
}

redis_install() {
  if redis_is_installed; then
    log_info "Redis đã được cài đặt, bỏ qua bước cài."
    state_set "$REDIS_STATE_KEY" "1"
    return 0
  fi

  log_info "Bắt đầu cài đặt Redis..."
  if is_debian_like; then
    apt update
    apt install -y redis-server
    # Bật Redis theo kiểu service systemd mặc định
    systemctl enable "$REDIS_SERVICE" --now
  elif is_rhel_like; then
    dnf install -y redis
    systemctl enable redis --now
    REDIS_SERVICE="redis"
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ cài Redis tự động."
    return 1
  fi

  if redis_status_systemd; then
    log_info "Cài đặt Redis thành công."
    state_set "$REDIS_STATE_KEY" "1"
  else
    log_error "Redis cài xong nhưng dịch vụ không chạy. Vui lòng kiểm tra log."
    return 1
  fi
}

redis_uninstall() {
  log_warn "Bạn sắp gỡ bỏ Redis. Thao tác này có thể làm ảnh hưởng cache/session của ứng dụng."
  read -r -p "Bạn có chắc chắn muốn tiếp tục? (gõ YES_TO_REMOVE_REDIS): " confirm
  if [[ "$confirm" != "YES_TO_REMOVE_REDIS" ]]; then
    log_info "Đã huỷ thao tác gỡ Redis."
    return 0
  fi

  if is_debian_like; then
    systemctl stop "$REDIS_SERVICE" 2>/dev/null || true
    apt purge -y redis-server
    apt autoremove -y
    read -r -p "Bạn có muốn xoá luôn dữ liệu /var/lib/redis? (y/N): " confirm_data
    if [[ "$confirm_data" == "y" || "$confirm_data" == "Y" ]]; then
      rm -rf /var/lib/redis
      log_warn "Đã xoá dữ liệu Redis."
    else
      log_info "Giữ lại dữ liệu Redis trong /var/lib/redis."
    fi
  elif is_rhel_like; then
    systemctl stop redis 2>/dev/null || true
    dnf remove -y redis
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ gỡ Redis tự động."
    return 1
  fi

  state_set "$REDIS_STATE_KEY" "0"
  log_info "Đã gỡ Redis (package)."
}

redis_enable() {
  if ! redis_is_installed; then
    log_error "Redis chưa được cài. Hãy cài trước."
    return 1
  fi

  systemctl enable "$REDIS_SERVICE" --now

  if redis_status_systemd; then
    log_info "Đã bật Redis và cho phép khởi động cùng hệ thống."
  else
    log_error "Không thể bật Redis. Vui lòng kiểm tra lại."
  fi
}

redis_disable() {
  if ! redis_is_installed; then
    log_error "Redis chưa được cài."
    return 1
  fi

  systemctl disable "$REDIS_SERVICE" --now

  if ! redis_status_systemd; then
    log_info "Đã tắt Redis và vô hiệu hoá khởi động cùng hệ thống."
  else
    log_warn "Dịch vụ Redis vẫn còn đang chạy. Vui lòng kiểm tra."
  fi
}

redis_show_status_line() {
  if redis_is_installed; then
    if redis_status_systemd; then
      echo "✅ Đã cài - Đang chạy"
    else
      echo "⏸ Đã cài - Đang tắt"
    fi
  else
    echo "❌ Chưa cài"
  fi
}

redis_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "           Quản lý Redis (Plugin)"
    echo "              nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    redis_show_status_line
    echo
    echo "1) Cài đặt Redis"
    echo "2) Gỡ bỏ Redis"
    echo "3) Bật dịch vụ Redis"
    echo "4) Tắt dịch vụ Redis"
    echo "5) Xem trạng thái chi tiết (systemctl)"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) redis_install;  read -rp "Nhấn Enter để tiếp tục..." ;;
      2) redis_uninstall; read -rp "Nhấn Enter để tiếp tục..." ;;
      3) redis_enable;   read -rp "Nhấn Enter để tiếp tục..." ;;
      4) redis_disable;  read -rp "Nhấn Enter để tiếp tục..." ;;
      5) systemctl status "$REDIS_SERVICE"; read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# Đăng ký plugin
ndc_register_plugin \
  "redis" \
  "Redis" \
  "CACHE" \
  "Cài đặt và quản lý Redis (cache/session)" \
  "redis_menu"
