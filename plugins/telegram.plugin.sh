#!/usr/bin/env bash

# ======================================
# Plugin: Telegram Notification
# Project: nguyendc-ols
# ID: telegram
# Category: OPS
# ======================================

TELEGRAM_TOKEN_KEY="TELEGRAM_BOT_TOKEN"
TELEGRAM_CHATID_KEY="TELEGRAM_CHAT_ID"

telegram_get_token() {
  state_get "$TELEGRAM_TOKEN_KEY"
}

telegram_get_chatid() {
  state_get "$TELEGRAM_CHATID_KEY"
}

telegram_set_token() {
  read -r -p "Nhập Telegram Bot Token (từ BotFather): " token
  if [[ -z "$token" ]]; then
    log_error "Token không được để trống."
    return 1
  fi
  state_set "$TELEGRAM_TOKEN_KEY" "$token"
  log_info "Đã lưu Telegram Bot Token vào state."
}

telegram_set_chatid() {
  read -r -p "Nhập Chat ID (user hoặc group): " chatid
  if [[ -z "$chatid" ]]; then
    log_error "Chat ID không được để trống."
    return 1
  fi
  state_set "$TELEGRAM_CHATID_KEY" "$chatid"
  log_info "Đã lưu Telegram Chat ID vào state."
}

telegram_send_message() {
  local text="$1"
  local token
  local chatid

  token="$(telegram_get_token)"
  chatid="$(telegram_get_chatid)"

  if [[ -z "$token" || -z "$chatid" ]]; then
    log_error "Chưa cấu hình Token hoặc Chat ID. Hãy thiết lập trong menu Telegram."
    return 1
  fi

  if ! command -v curl >/dev/null 2>&1; then
    log_error "Thiếu curl. Hãy cài curl trước (apt install -y curl)."
    return 1
  fi

  local api_url="https://api.telegram.org/bot${token}/sendMessage"

  curl -s -X POST "$api_url" \
    -d "chat_id=${chatid}" \
    -d "text=${text}" \
    -d "parse_mode=Markdown" >/tmp/telegram-send.log 2>&1

  if grep -q '"ok":true' /tmp/telegram-send.log 2>/dev/null; then
    log_info "Đã gửi thông báo Telegram thành công."
    return 0
  else
    log_error "Gửi Telegram thất bại. Kiểm tra /tmp/telegram-send.log."
    return 1
  fi
}

telegram_test_message() {
  read -r -p "Nhập nội dung test (mặc định: 'Test từ nguyendc-ols'): " msg
  msg="${msg:-Test từ nguyendc-ols}"
  telegram_send_message "$msg"
}

telegram_show_status_line() {
  local token chatid
  token="$(telegram_get_token)"
  chatid="$(telegram_get_chatid)"

  if [[ -n "$token" && -n "$chatid" ]]; then
    echo "✅ Đã cấu hình Bot & Chat ID"
  elif [[ -n "$token" ]]; then
    echo "⚠️ Có Token, chưa có Chat ID"
  else
    echo "❌ Chưa cấu hình Telegram Bot"
  fi
}

telegram_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "      Telegram Notification (Plugin)"
    echo "              nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    telegram_show_status_line
    echo
    echo "1) Thiết lập Bot Token"
    echo "2) Thiết lập Chat ID"
    echo "3) Gửi tin nhắn test"
    echo "0) Quay lại menu trước"
    echo
    echo "Gợi ý:"
    echo " - Tạo bot qua @BotFather để lấy token."
    echo " - Lấy Chat ID bằng cách gửi tin cho bot, sau đó dùng bot như @userinfobot, hoặc API getUpdates."
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) telegram_set_token;      read -rp "Nhấn Enter để tiếp tục..." ;;
      2) telegram_set_chatid;     read -rp "Nhấn Enter để tiếp tục..." ;;
      3) telegram_test_message;   read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

telegram_cli() {
  # CLI usage:
  #   nguyendc-ols.sh telegram send "message..."
  #   nguyendc-ols.sh telegram test
  #   nguyendc-ols.sh telegram health "Nội dung health tuỳ chọn"
  local subcmd="$1"
  shift || true

  case "$subcmd" in
    send)
      # gửi message qua CLI
      local msg="$*"
      if [[ -z "$msg" ]]; then
        echo "Usage: nguyendc-ols.sh telegram send \"Nội dung\""
        return 1
      fi
      telegram_send_message "$msg"
      ;;
    test|"")
      telegram_test_message
      ;;
    health)
      # dùng cho các plugin healthcheck… truyền message mô tả tình trạng server
      local msg="$*"
      msg="${msg:-Healthcheck alert từ nguyendc-ols}"
      telegram_send_message "$msg"
      ;;
    *)
      echo "Telegram CLI:"
      echo "  telegram send \"text\"   - Gửi tin nhắn"
      echo "  telegram test            - Gửi tin test"
      echo "  telegram health \"text\" - Gửi cảnh báo health"
      return 1
      ;;
  esac
}

ndc_register_plugin \
  "telegram" \
  "Telegram Notify" \
  "MONITORING" \
  "" \
  "telegram_menu"
