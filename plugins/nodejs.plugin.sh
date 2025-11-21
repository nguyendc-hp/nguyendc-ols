#!/usr/bin/env bash

# ======================================
# Plugin: Node.js + PM2
# Project: nguyendc-ols
# ID: nodejs
# Category: RUNTIME
# ======================================

NODE_STATE_KEY="NODEJS_INSTALLED"
PM2_STATE_KEY="PM2_INSTALLED"

nodejs_is_installed() {
  command -v node >/dev/null 2>&1
}

pm2_is_installed() {
  command -v pm2 >/dev/null 2>&1
}

nodejs_install() {
  if nodejs_is_installed; then
    log_info "Node.js đã được cài đặt, bỏ qua bước cài."
    state_set "$NODE_STATE_KEY" "1"
  else
    log_info "Bắt đầu cài đặt Node.js (từ repo hệ điều hành)..."
    if is_debian_like; then
      apt update
      apt install -y nodejs npm
    elif is_rhel_like; then
      dnf install -y nodejs npm
    else
      log_error "Hệ điều hành hiện tại chưa được hỗ trợ cài Node.js tự động."
      return 1
    fi

    if nodejs_is_installed; then
      log_info "Cài đặt Node.js thành công. Phiên bản: $(node -v 2>/dev/null || echo 'unknown')"
      state_set "$NODE_STATE_KEY" "1"
    else
      log_error "Node.js cài xong nhưng không chạy được."
      return 1
    fi
  fi

  # Cài đặt PM2
  if pm2_is_installed; then
    log_info "PM2 đã được cài đặt, bỏ qua bước cài."
    state_set "$PM2_STATE_KEY" "1"
  else
    log_info "Bắt đầu cài đặt PM2 (global)..."
    npm install -g pm2
    if pm2_is_installed; then
      log_info "Cài đặt PM2 thành công. Phiên bản: $(pm2 -v 2>/dev/null || echo 'unknown')"
      state_set "$PM2_STATE_KEY" "1"
    else
      log_error "PM2 cài xong nhưng không chạy được."
      return 1
    fi
  fi
}

nodejs_uninstall() {
  log_warn "Bạn sắp gỡ Node.js và PM2. Thao tác này có thể ảnh hưởng tất cả app Node đang chạy."
  read -r -p "Bạn có chắc chắn muốn tiếp tục? (gõ YES_TO_REMOVE_NODE): " confirm
  if [[ "$confirm" != "YES_TO_REMOVE_NODE" ]]; then
    log_info "Đã huỷ thao tác gỡ Node.js/PM2."
    return 0
  fi

  # Dừng tất cả process PM2 trước
  if pm2_is_installed; then
    pm2 save 2>/dev/null || true
    pm2 kill 2>/dev/null || true
  fi

  if is_debian_like; then
    apt purge -y nodejs npm
    apt autoremove -y
  elif is_rhel_like; then
    dnf remove -y nodejs npm
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ gỡ Node.js/PM2 tự động."
    return 1
  fi

  # Gỡ PM2 global (thực tế khi gỡ npm có thể xoá luôn)
  npm uninstall -g pm2 2>/dev/null || true

  state_set "$NODE_STATE_KEY" "0"
  state_set "$PM2_STATE_KEY" "0"
  log_info "Đã gỡ Node.js và PM2 (package)."
}

nodejs_enable() {
  # Ở đây enable nghĩa là cấu hình PM2 chạy cùng hệ thống
  if ! pm2_is_installed; then
    log_error "PM2 chưa được cài. Hãy cài Node.js/PM2 trước."
    return 1
  fi

  log_info "Thiết lập PM2 startup (systemd)..."
  pm2 startup systemd -u root --hp /root >/tmp/pm2-startup.log 2>&1 || true
  log_info "PM2 startup command output (khuyến nghị đọc /tmp/pm2-startup.log nếu lỗi)."
  log_info "Khi bạn đã cấu hình process, hãy dùng 'pm2 save' để lưu lại."
}

nodejs_disable() {
  # Tắt PM2 startup service (thường tên kiểu 'pm2-root')
  if systemctl list-units | grep -q "pm2-"; then
    local svc
    svc="$(systemctl list-units | awk '/pm2-/{print $1}' | head -n1)"
    if [[ -n "$svc" ]]; then
      log_info "Vô hiệu hoá dịch vụ PM2: $svc"
      systemctl disable "$svc" --now 2>/dev/null || true
    fi
  fi
  log_info "Đã cố gắng vô hiệu hoá PM2 startup (nếu có)."
}

nodejs_show_status_line() {
  local node_status pm2_status

  if nodejs_is_installed; then
    node_status="✅ Node: $(node -v 2>/dev/null || echo '?')"
  else
    node_status="❌ Node chưa cài"
  fi

  if pm2_is_installed; then
    pm2_status="✅ PM2: $(pm2 -v 2>/dev/null || echo '?')"
  else
    pm2_status="❌ PM2 chưa cài"
  fi

  echo "$node_status | $pm2_status"
}

nodejs_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "       Quản lý Node.js + PM2 (Plugin)"
    echo "              nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    nodejs_show_status_line
    echo
    echo "1) Cài đặt Node.js + PM2"
    echo "2) Gỡ Node.js + PM2"
    echo "3) Thiết lập PM2 chạy cùng hệ thống (startup)"
    echo "4) Vô hiệu hoá PM2 startup"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) nodejs_install;   read -rp "Nhấn Enter để tiếp tục..." ;;
      2) nodejs_uninstall; read -rp "Nhấn Enter để tiếp tục..." ;;
      3) nodejs_enable;    read -rp "Nhấn Enter để tiếp tục..." ;;
      4) nodejs_disable;   read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# Đăng ký plugin
ndc_register_plugin \
  "nodejs" \
  "Node.js + PM2" \
  "RUNTIME" \
  "Cài đặt và quản lý môi trường Node.js + PM2" \
  "nodejs_menu"
