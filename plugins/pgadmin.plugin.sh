#!/usr/bin/env bash

# ======================================
# Plugin: pgAdmin 4
# Project: nguyendc-ols
# ID: pgadmin
# Category: DB
# ======================================

PGADMIN_STATE_KEY="PGADMIN_INSTALLED"

pgadmin_is_installed() {
  dpkg -s pgadmin4 >/dev/null 2>&1 || \
  dpkg -s pgadmin4-web >/dev/null 2>&1 || \
  rpm -q pgadmin4 >/dev/null 2>&1
}

pgadmin_install() {
  if pgadmin_is_installed; then
    log_info "pgAdmin 4 đã được cài đặt, bỏ qua bước cài."
    state_set "$PGADMIN_STATE_KEY" "1"
    return 0
  fi

  log_info "Bắt đầu cài đặt pgAdmin 4..."

  if is_debian_like; then
    # Repo chính thức của pgAdmin cho Debian/Ubuntu
    curl https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo apt-key add -
    sh -c 'echo "deb https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list'

    apt update
    # Cài bản web (chạy qua web server)
    apt install -y pgadmin4-web

    # Cài đặt cấu hình web (script chính thức)
    /usr/pgadmin4/bin/setup-web.sh

    log_info "pgAdmin 4 đã được cài. Thường truy cập qua: http://your-server/pgadmin4 hoặc virtualhost cấu hình sẵn."
  elif is_rhel_like; then
    log_warn "pgAdmin 4 trên RHEL-like chưa được script hoá. Bạn nên cài thủ công theo hướng dẫn pgAdmin."
    return 1
  else
    log_error "Hệ điều hành hiện tại chưa được hỗ trợ cài pgAdmin 4 tự động."
    return 1
  fi

  if pgadmin_is_installed; then
    state_set "$PGADMIN_STATE_KEY" "1"
  else
    log_error "pgAdmin 4 cài xong nhưng không tìm thấy package."
    return 1
  fi
}

pgadmin_uninstall() {
  log_warn "Bạn sắp gỡ pgAdmin 4. Điều này không xoá PostgreSQL, chỉ xoá giao diện quản trị."
  read -r -p "Bạn có chắc chắn muốn tiếp tục? (gõ YES_TO_REMOVE_PGADMIN): " confirm
  if [[ "$confirm" != "YES_TO_REMOVE_PGADMIN" ]]; then
    log_info "Đã huỷ thao tác gỡ pgAdmin 4."
    return 0
  fi

  if is_debian_like; then
    apt purge -y pgadmin4 pgadmin4-web
    apt autoremove -y
    log_info "Đã gỡ pgAdmin 4."
  else
    log_error "Hiện tại chỉ hỗ trợ gỡ pgAdmin tự động trên Debian/Ubuntu."
    return 1
  fi

  state_set "$PGADMIN_STATE_KEY" "0"
}

pgadmin_show_status_line() {
  if pgadmin_is_installed; then
    echo "✅ Đã cài - truy cập qua web (pgAdmin 4)"
  else
    echo "❌ Chưa cài"
  fi
}

pgadmin_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "           Quản lý pgAdmin 4 (Plugin)"
    echo "                nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    pgadmin_show_status_line
    echo
    echo "1) Cài đặt pgAdmin 4"
    echo "2) Gỡ pgAdmin 4"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) pgadmin_install;   read -rp "Nhấn Enter để tiếp tục..." ;;
      2) pgadmin_uninstall; read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "pgadmin" \
  "pgAdmin 4" \
  "DB_GUI" \
  "" \
  "pgadmin_menu"
