#!/usr/bin/env bash

# ======================================
# Plugin: Công cụ tiện ích khác
# Category: UTILITIES
# ======================================

util_speedtest() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Test tốc độ internet"
  echo "══════════════════════════════════════════════"
  
  if ! command -v speedtest >/dev/null 2>&1; then
    log_info "Đang cài speedtest-cli..."
    apt update && apt install -y speedtest-cli
  fi
  
  speedtest
  echo ""
}

util_ping_trace() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Ping / traceroute"
  echo "══════════════════════════════════════════════"
  
  read -rp "Nhập host (VD: google.com): " host
  
  if [[ -z "$host" ]]; then
    log_error "Host không được để trống."
    return 1
  fi
  
  echo -e "\n${GREEN}Ping:${NC}"
  ping -c 4 "$host"
  
  echo -e "\n${GREEN}Traceroute:${NC}"
  traceroute "$host"
  
  echo ""
}

util_whois() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Whois domain"
  echo "══════════════════════════════════════════════"
  
  read -rp "Nhập domain: " domain
  
  if [[ -z "$domain" ]]; then
    log_error "Domain không được để trống."
    return 1
  fi
  
  if ! command -v whois >/dev/null 2>&1; then
    apt update && apt install -y whois
  fi
  
  whois "$domain"
  echo ""
}

util_ssh_key() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Tạo / quản lý SSH key"
  echo "══════════════════════════════════════════════"
  
  echo " 1) Tạo SSH key mới"
  echo " 2) Xem public key hiện có"
  echo " 0) Quay lại"
  
  read -rp "Chọn: " choice
  
  case "$choice" in
    1)
      read -rp "Nhập email cho SSH key: " email
      ssh-keygen -t ed25519 -C "$email"
      log_success "Đã tạo SSH key."
      ;;
    2)
      if [[ -f ~/.ssh/id_ed25519.pub ]]; then
        cat ~/.ssh/id_ed25519.pub
      elif [[ -f ~/.ssh/id_rsa.pub ]]; then
        cat ~/.ssh/id_rsa.pub
      else
        echo "Không tìm thấy public key."
      fi
      ;;
  esac
  
  echo ""
}

util_dev_tools() {
  clear
  echo "══════════════════════════════════════════════"
  echo "    Các lệnh dev tiện dụng"
  echo "══════════════════════════════════════════════"
  
  echo "1) Xem process tree: pstree"
  echo "2) Monitor resources: htop"
  echo "3) Disk usage: ncdu"
  echo "4) Network monitoring: iftop"
  echo ""
  echo "Cài thêm tools: apt install pstree htop ncdu iftop"
}

utilities_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "          Công cụ tiện ích khác"
    echo "══════════════════════════════════════════════"
    echo " 1) Test tốc độ internet"
    echo " 2) Ping / traceroute"
    echo " 3) Whois domain"
    echo " 4) Tạo / quản lý SSH key"
    echo " 5) Các lệnh dev tiện dụng"
    echo " 0) Quay lại"
    echo
    read -rp "Chọn chức năng: " choice
    
    case "$choice" in
      1) util_speedtest; read -rp "Nhấn Enter..." ;;
      2) util_ping_trace; read -rp "Nhấn Enter..." ;;
      3) util_whois; read -rp "Nhấn Enter..." ;;
      4) util_ssh_key; read -rp "Nhấn Enter..." ;;
      5) util_dev_tools; read -rp "Nhấn Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "utilities" \
  "Công cụ tiện ích khác" \
  "UTILITIES" \
  "" \
  "utilities_menu"
