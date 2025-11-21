#!/usr/bin/env bash
#
# ======================================
# Plugin: PM2 Manager
# Project: nguyendc-ols
# ID: pm2mgr
# Category: NODE
# ======================================

pm2mgr_require_pm2() {
  if ! command -v pm2 >/dev/null 2>&1; then
    log_error "PM2 chưa cài. Hãy dùng plugin nodejs để cài Node + PM2."
    return 1
  fi
}

pm2mgr_list() {
  pm2mgr_require_pm2 || return 1
  pm2 list
}

pm2mgr_show_logs() {
  pm2mgr_require_pm2 || return 1
  read -r -p "Tên app (pm2 name): " name
  [[ -z "$name" ]] && return 1
  pm2 logs "$name"
}

pm2mgr_start_stop_restart() {
  pm2mgr_require_pm2 || return 1
  echo "1) start"
  echo "2) stop"
  echo "3) restart"
  read -r -p "Chọn thao tác: " act
  read -r -p "Tên app (pm2 name): " name

  case "$act" in
    1) pm2 start "$name" ;;
    2) pm2 stop "$name" ;;
    3) pm2 restart "$name" ;;
    *) echo "Không hợp lệ." ;;
  esac
}

pm2mgr_delete_app() {
  pm2mgr_require_pm2 || return 1
  read -r -p "Tên app (pm2 name) cần delete: " name
  pm2 delete "$name"
}

pm2mgr_setup_startup() {
  pm2mgr_require_pm2 || return 1
  local cmd
  cmd=$(pm2 startup | tail -n1)
  echo "Chạy lệnh sau (nếu chưa tự chạy):"
  echo "$cmd"
  eval "$cmd"
  pm2 save
  log_info "Đã cấu hình PM2 startup + save process list."
}

pm2mgr_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "             PM2 Manager (Plugin)"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "1) pm2 list"
    echo "2) Xem logs 1 app"
    echo "3) start/stop/restart 1 app"
    echo "4) delete 1 app"
    echo "5) Thiết lập PM2 startup (reboot tự reload)"
    echo "0) Quay lại"
    echo
    read -rp "Chọn: " c
    case "$c" in
      1) pm2mgr_list;                read -rp "Enter..." ;;
      2) pm2mgr_show_logs;           read -rp "Enter..." ;;
      3) pm2mgr_start_stop_restart;  read -rp "Enter..." ;;
      4) pm2mgr_delete_app;          read -rp "Enter..." ;;
      5) pm2mgr_setup_startup;       read -rp "Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh pm2mgr list|logs|start|stop|restart|startup
pm2mgr_cli() {
  case "$1" in
    list|"") pm2mgr_list ;;
    logs)    pm2mgr_show_logs ;;
    start|stop|restart)
      # dùng chung function start_stop_restart (sẽ hỏi lại hành động cho chắc)
      pm2mgr_start_stop_restart
      ;;
    startup)
      pm2mgr_setup_startup
      ;;
    *)
      echo "PM2 Manager CLI:"
      echo "  pm2mgr list       - pm2 list"
      echo "  pm2mgr logs       - logs app"
      echo "  pm2mgr startup    - cấu hình pm2 startup"
      ;;
  esac
}

ndc_register_plugin \
  "pm2mgr" \
  "PM2 Manager" \
  "NODE" \
  "Quản lý process PM2: list, logs, start/stop/restart, startup" \
  "pm2mgr_menu"
