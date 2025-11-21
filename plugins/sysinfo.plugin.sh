#!/usr/bin/env bash

# ======================================
# Plugin: System Info
# Project: nguyendc-ols
# ID: sysinfo
# Category: SYS
# ======================================

sysinfo_show() {
  echo "===== System Info ====="
  echo "Hostname: $(hostname)"
  echo "Date    : $(date)"
  echo

  echo "OS:"
  if [[ -f /etc/os-release ]]; then
    cat /etc/os-release
  else
    uname -a
  fi
  echo

  echo "CPU:"
  lscpu 2>/dev/null || cat /proc/cpuinfo 2>/dev/null || echo "N/A"
  echo

  echo "Memory:"
  free -h || echo "N/A"
  echo

  echo "Disk:"
  df -h || echo "N/A"
  echo

  echo "Top processes (CPU):"
  ps aux --sort=-%cpu | head -n 10
  echo

  echo "Top processes (MEM):"
  ps aux --sort=-%mem | head -n 10
  echo
}

sysinfo_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "             System Info (Plugin)"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "1) Hiển thị thông tin hệ thống"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) sysinfo_show; read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh sysinfo show
sysinfo_cli() {
  local subcmd="$1"
  case "$subcmd" in
    show|"")
      sysinfo_show
      ;;
    *)
      echo "Sysinfo CLI:"
      echo "  sysinfo show   - hiển thị thông tin hệ thống"
      return 1
      ;;
  esac
}

ndc_register_plugin \
  "sysinfo" \
  "System Info" \
  "SYS" \
  "Xem nhanh thông tin hệ thống, CPU, RAM, Disk, top process" \
  "sysinfo_menu"
