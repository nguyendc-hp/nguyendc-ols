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
    # Xác định phiên bản Ubuntu
    local ubuntu_version
    ubuntu_version=$(lsb_release -rs 2>/dev/null || echo "22.04")
    local ubuntu_codename
    ubuntu_codename=$(lsb_release -cs 2>/dev/null || echo "jammy")
    
    log_info "Phát hiện Ubuntu $ubuntu_version ($ubuntu_codename)"
    
    # Cài đặt dependencies
    apt-get update
    apt-get install -y gnupg curl
    
    # Import MongoDB GPG key
    log_info "Import MongoDB GPG key..."
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
      gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
    
    # Add MongoDB repository
    log_info "Thêm MongoDB repository..."
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $ubuntu_codename/mongodb-org/7.0 multiverse" | \
      tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    
    # Update và cài MongoDB
    apt-get update
    if apt-get install -y mongodb-org; then
      log_info "Đã cài mongodb-org từ official repository"
    else
      log_error "Cài mongodb-org thất bại"
      return 1
    fi
    
  elif is_rhel_like; then
    # RHEL/CentOS MongoDB setup
    log_info "Tạo MongoDB repository cho RHEL/CentOS..."
    cat > /etc/yum.repos.d/mongodb-org-7.0.repo <<'EOF'
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
    
    if ! dnf install -y mongodb-org; then
      log_error "Cài mongodb-org thất bại"
      return 1
    fi
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ cài MongoDB tự động."
    return 1
  fi

  # Enable và start MongoDB
  systemctl enable "$MONGO_SERVICE" --now

  if mongo_status_systemd; then
    log_info "Cài đặt MongoDB thành công."
    state_set "$MONGO_STATE_KEY" "1"
  else
    log_error "MongoDB cài xong nhưng dịch vụ không chạy. Vui lòng kiểm tra log."
    systemctl status "$MONGO_SERVICE" --no-pager
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
