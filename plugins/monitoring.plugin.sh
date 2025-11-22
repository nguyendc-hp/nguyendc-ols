#!/usr/bin/env bash

# ======================================
# Plugin: Giám sát & cảnh báo
# Category: MONITORING
# ======================================

TELEGRAM_CONFIG="/etc/nguyendc-ols/telegram.conf"

monitoring_telegram_config() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Cấu hình Telegram bot / chat id"
  echo "══════════════════════════════════════════════"
  
  read -rp "Nhập Telegram Bot Token: " bot_token
  read -rp "Nhập Telegram Chat ID: " chat_id
  
  mkdir -p "$(dirname "$TELEGRAM_CONFIG")"
  cat > "$TELEGRAM_CONFIG" <<EOF
TELEGRAM_BOT_TOKEN="${bot_token}"
TELEGRAM_CHAT_ID="${chat_id}"
EOF
  
  log_success "Đã lưu cấu hình Telegram."
}

monitoring_node_alert() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Thiết lập Node Alert"
  echo "══════════════════════════════════════════════"
  echo " 1) Giám sát PM2 status"
  echo " 2) Giám sát HTTP status / response time"
  echo " 3) Giám sát lỗi trong log"
  echo " 4) Thiết lập ngưỡng cảnh báo"
  echo " 0) Quay lại"
  
  read -rp "Chọn: " choice
  
  case "$choice" in
    1) log_info "Cấu hình giám sát PM2..." ;;
    2) log_info "Cấu hình HTTP check..." ;;
    3) log_info "Cấu hình log monitoring..." ;;
    4) log_info "Thiết lập threshold..." ;;
  esac
}

monitoring_test_telegram() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Test gửi cảnh báo Telegram"
  echo "══════════════════════════════════════════════"
  
  if [[ ! -f "$TELEGRAM_CONFIG" ]]; then
    log_error "Chưa cấu hình Telegram."
    return 1
  fi
  
  source "$TELEGRAM_CONFIG"
  
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=Test message from nguyendc-ols"
  
  log_success "Đã gửi test message."
}

monitoring_cron_setup() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Bật/tắt cron cho Node Alert"
  echo "══════════════════════════════════════════════"
  
  echo "Gợi ý cron jobs:"
  echo "*/5 * * * * /path/to/nguyendc-ols.sh healthcheck run"
  echo "*/2 * * * * /path/to/nguyendc-ols.sh processwatch run"
  echo ""
  echo "Thêm vào: crontab -e"
}

monitoring_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "          Giám sát & cảnh báo"
    echo "══════════════════════════════════════════════"
    echo " 1) Cấu hình Telegram bot / chat id"
    echo " 2) Thiết lập Node Alert"
    echo " 3) Test gửi cảnh báo Telegram"
    echo " 4) Bật/tắt cron cho Node Alert"
    echo " 0) Quay lại"
    echo
    read -rp "Chọn chức năng: " choice
    
    case "$choice" in
      1) monitoring_telegram_config; read -rp "Nhấn Enter..." ;;
      2) monitoring_node_alert; read -rp "Nhấn Enter..." ;;
      3) monitoring_test_telegram; read -rp "Nhấn Enter..." ;;
      4) monitoring_cron_setup; read -rp "Nhấn Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "monitoring" \
  "Giám sát & cảnh báo" \
  "MONITORING" \
  "" \
  "monitoring_menu"
