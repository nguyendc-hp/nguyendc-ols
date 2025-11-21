#!/usr/bin/env bash

# ======================================
# Plugin: Log Watcher
# Project: nguyendc-ols
# ID: logwatch
# Category: MON
# ======================================

logwatch_tail_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "File log không tồn tại: $file"
    return 1
  fi

  echo "Hiển thị 100 dòng cuối của $file:"
  echo "--------------------------------------"
  tail -n 100 "$file"
  echo "--------------------------------------"
}

logwatch_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "           Log Watcher (Plugin)"
    echo "                nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "1) Xem log Nginx access (mặc định: /var/log/nginx/access.log)"
    echo "2) Xem log Nginx error (mặc định: /var/log/nginx/error.log)"
    echo "3) Xem log hệ thống (journalctl -xe | tail)"
    echo "4) Xem log nguyendc-ols (/var/log/nguyendc-ols.log)"
    echo "5) Nhập đường dẫn log bất kỳ"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) logwatch_tail_file "/var/log/nginx/access.log"; read -rp "Nhấn Enter để tiếp tục..." ;;
      2) logwatch_tail_file "/var/log/nginx/error.log";  read -rp "Nhấn Enter để tiếp tục..." ;;
      3) echo "100 dòng cuối journalctl -xe:"; echo "--------------------------------------"; journalctl -xe | tail -n 100; echo "--------------------------------------"; read -rp "Nhấn Enter để tiếp tục..." ;;
      4) logwatch_tail_file "/var/log/nguyendc-ols.log"; read -rp "Nhấn Enter để tiếp tục..." ;;
      5) read -r -p "Nhập đường dẫn file log: " f; logwatch_tail_file "$f"; read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

logwatch_show_status_line() {
  echo "Xem nhanh log Nginx, system, nguyendc-ols và log tùy chọn."
}

ndc_register_plugin \
  "logwatch" \
  "Log Watcher" \
  "MON" \
  "Xem nhanh log Nginx, system, nguyendc-ols" \
  "logwatch_menu"
