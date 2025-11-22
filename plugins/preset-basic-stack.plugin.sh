#!/usr/bin/env bash

# ======================================
# Plugin: Basic Stack Preset
# Project: nguyendc-ols
# ID: presetbasic
# Category: SYSTEM
# ======================================

presetbasic_check_function() {
  local func="$1"
  if [[ "$(type -t "$func")" != "function" ]]; then
    log_error "Hàm ${func} không tồn tại. Hãy đảm bảo plugin liên quan đã được load."
    return 1
  fi
  return 0
}

presetbasic_install_stack() {
  echo "Stack sẽ cài:"
  echo " - Nginx"
  echo " - Node.js + PM2"
  echo " - MariaDB/MySQL"
  echo " - Redis"
  echo

  read -r -p "Xác nhận cài Basic Stack? (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    log_info "Đã huỷ cài Basic Stack."
    return 0
  fi

  # Nginx
  if presetbasic_check_function "nginx_install"; then
    nginx_install || log_error "Cài Nginx lỗi."
  fi

  # Node.js + PM2
  if presetbasic_check_function "nodejs_install"; then
    nodejs_install || log_error "Cài Node.js + PM2 lỗi."
  fi

  # MariaDB
  if presetbasic_check_function "mariadb_install"; then
    mariadb_install || log_error "Cài MariaDB/MySQL lỗi."
  fi

  # Redis
  if presetbasic_check_function "redis_install"; then
    redis_install || log_error "Cài Redis lỗi."
  fi

  log_info "Đã chạy preset Basic Stack (Nginx + Node/PM2 + MariaDB + Redis)."
}

presetbasic_show_status_line() {
  echo "Preset: Nginx + Node/PM2 + MariaDB + Redis"
}

presetbasic_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "         Basic Stack Preset (Plugin)"
    echo "                nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Thông tin: "
    presetbasic_show_status_line
    echo
    echo "1) Cài Basic Stack"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) presetbasic_install_stack; read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "presetbasic" \
  "Basic Stack Preset" \
  "SETUP" \
  "" \
  "presetbasic_menu"
