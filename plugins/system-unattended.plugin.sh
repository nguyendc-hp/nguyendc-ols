#!/usr/bin/env bash
#
# ======================================
# Plugin: System Unattended-Upgrades Control
# Project: nguyendc-ols
# ID: unattended
# Category: SYSTEM
# ======================================

unattended_show_status() {
  local st enabled active pids
  st="$(ndc_unattended_status)"
  enabled=$(echo "$st" | sed -n 's/.*enabled=\([^;]*\).*/\1/p')
  active=$(echo "$st"  | sed -n 's/.*active=\([^;]*\).*/\1/p')
  pids=$(echo "$st"    | sed -n 's/.*pids=\(.*\)$/\1/p')

  ndc_header
  echo "Trạng thái unattended-upgrades:"
  echo "----------------------------------------"
  echo "  enabled : ${enabled}"
  echo "  active  : ${active}"
  if [[ -n "$pids" ]]; then
    echo "  pids    : ${pids}"
  else
    echo "  pids    : (không có tiến trình đang chạy)"
  fi
  echo
  echo "Gợi ý:"
  echo "  - Nên để ENABLED khi sử dụng bình thường."
  echo "  - Tạm DISABLE khi chạy các cài đặt nặng (OLS/stack)."
  echo
}

unattended_disable_now() {
  ndc_disable_unattended
  read -rp "Nhấn Enter để xem lại trạng thái..." _
  unattended_show_status
}

unattended_enable_now() {
  ndc_enable_unattended
  read -rp "Nhấn Enter để xem lại trạng thái..." _
  unattended_show_status
}

# Ví dụ demo: update & upgrade với apt guard
unattended_safe_update_demo() {
  _do_update() {
    log_info "Chạy safe apt update/upgrade (demo)..."
    apt update -y
    apt upgrade -y
  }

  ndc_with_apt_guard _do_update
  read -rp "Nhấn Enter để quay lại menu..." _
}

unattended_menu() {
  while true; do
    ndc_header
    echo "SYSTEM: Unattended-Upgrades Control"
    echo "══════════════════════════════════════════════"
    local st enabled active
    st="$(ndc_unattended_status)"
    enabled=$(echo "$st" | sed -n 's/.*enabled=\([^;]*\).*/\1/p')
    active=$(echo "$st"  | sed -n 's/.*active=\([^;]*\).*/\1/p')
    echo "enabled=${enabled}, active=${active}"
    echo
    echo "1) Xem trạng thái chi tiết"
    echo "2) TẮT unattended-upgrades ngay (stop + disable + dọn lock)"
    echo "3) BẬT lại unattended-upgrades"
    echo "4) Chạy 'safe apt update/upgrade' (demo với apt guard)"
    echo
    echo "0) Quay lại"
    echo
    read -rp "Chọn: " c
    case "$c" in
      1) unattended_show_status;      read -rp "Enter..." ;;
      2) unattended_disable_now ;;
      3) unattended_enable_now ;;
      4) unattended_safe_update_demo ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh unattended status|disable|enable|safe-update
unattended_cli() {
  case "$1" in
    status|"") unattended_show_status ;;
    disable)    ndc_disable_unattended ;;
    enable)     ndc_enable_unattended ;;
    safe-update) 
      unattended_safe_update_demo
      ;;
    *)
      echo "Unattended CLI:"
      echo "  unattended status      - xem trạng thái"
      echo "  unattended disable     - tắt service + disable + dọn lock"
      echo "  unattended enable      - bật lại service"
      echo "  unattended safe-update - chạy apt update/upgrade với apt guard"
      ;;
  esac
}

ndc_register_plugin \
  "unattended" \
  "System: Unattended-Upgrades" \
  "SYSINFO" \
  "" \
  "unattended_menu"
