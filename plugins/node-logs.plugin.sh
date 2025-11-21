#!/usr/bin/env bash
#
# ======================================
# Plugin: Node Logs Analyzer
# Project: nguyendc-ols
# ID: nodelogs
# Category: NODE
# ======================================

nodelogs_require_pm2() {
  if ! command -v pm2 >/dev/null 2>&1; then
    log_error "PM2 chưa cài."
    return 1
  fi
}

nodelogs_tail() {
  nodelogs_require_pm2 || return 1
  read -r -p "Tên app (pm2 name): " name
  read -r -p "Số dòng log (default 200): " lines
  lines="${lines:-200}"
  pm2 logs "$name" --lines "$lines"
}

nodelogs_summary() {
  nodelogs_require_pm2 || return 1
  read -r -p "Tên app (pm2 name): " name
  read -r -p "Số dòng log để phân tích (default 500): " lines
  lines="${lines:-500}"

  echo "Đang lấy log từ pm2..."
  tmp=$(mktemp)
  pm2 logs "$name" --lines "$lines" --raw > "$tmp" 2>/dev/null &

  # Chờ 1 chút cho pm2 logs đổ log vào rồi kill
  sleep 2
  pkill -f "pm2 logs $name" 2>/dev/null || true

  echo "===== Tóm tắt lỗi trong ${lines} dòng log gần nhất ====="
  total_errors=$(grep -Ei "error|exception|unhandled" "$tmp" | wc -l || echo 0)
  echo "Tổng số dòng có ERROR/EXCEPTION/UNHANDLED: ${total_errors}"

  echo
  echo "Top 10 pattern lỗi (dựa trên dòng chứa 'error/exception'):"
  grep -Ei "error|exception|unhandled" "$tmp" \
    | sed 's/[0-9]\{2,4\}[-:T ]/[TIME]/g' \
    | sed 's/[0-9]\+/[NUM]/g' \
    | sed 's/0x[0-9a-fA-F]\+/[HEX]/g' \
    | sort \
    | uniq -c \
    | sort -nr \
    | head -n 10

  rm -f "$tmp"
}

nodelogs_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "          Node Logs Analyzer (Plugin)"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "1) Xem tail log 1 app (pm2 logs)"
    echo "2) Phân tích lỗi (tóm tắt pattern trong log)"
    echo "0) Quay lại"
    echo
    read -rp "Chọn: " c
    case "$c" in
      1) nodelogs_tail ;;
      2) nodelogs_summary; read -rp "Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh nodelogs summary <app>
nodelogs_cli() {
  case "$1" in
    summary)
      shift
      if [[ -n "$1" ]]; then
        name="$1"
        lines="${2:-500}"
        tmp=$(mktemp)
        pm2 logs "$name" --lines "$lines" --raw > "$tmp" 2>/dev/null &
        sleep 2
        pkill -f "pm2 logs $name" 2>/dev/null || true
        echo "Top lỗi:"
        grep -Ei "error|exception|unhandled" "$tmp" \
          | sed 's/[0-9]\{2,4\}[-:T ]/[TIME]/g' \
          | sed 's/[0-9]\+/[NUM]/g' \
          | sort \
          | uniq -c \
          | sort -nr \
          | head -n 10
        rm -f "$tmp"
      else
        nodelogs_summary
      fi
      ;;
    *)
      nodelogs_tail
      ;;
  esac
}

ndc_register_plugin \
  "nodelogs" \
  "Node Logs Analyzer" \
  "NODE" \
  "Phân tích log PM2, đếm lỗi, tóm tắt pattern" \
  "nodelogs_menu"
