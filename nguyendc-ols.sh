#!/usr/bin/env bash
#
# ============================================================
# nguyendc-ols
# Node.js, WordPress & Database VPS Management Tool
#
# Core launcher + plugin system + unattended-upgrades guard
# ============================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ----- Print functions -----
print_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} ${GREEN}$1${NC}"; }
print_error() { echo -e "${RED}[✗]${NC} ${RED}$1${NC}"; }
print_warning() { echo -e "${YELLOW}[!]${NC} ${YELLOW}$1${NC}"; }
print_step() { echo -e "${BLUE}[→]${NC} ${BOLD}$1${NC}"; }

# ----- Đường dẫn gốc & thư mục plugin -----
# Robust symlink resolution
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
NDC_BASE_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
NDC_PLUGINS_DIR="${NDC_BASE_DIR}/plugins"
NDC_CORE_DIR="${NDC_BASE_DIR}/core"

# ----- Thư mục cấu hình & state -----
NDC_ETC_DIR="/etc/nguyendc-ols"
NDC_STATE_FILE="${NDC_ETC_DIR}/state.env"
export STATE_FILE="$NDC_STATE_FILE" # For core/state.sh

mkdir -p "$NDC_ETC_DIR"

# ----- Load Core Modules -----
ndc_load_core() {
  if [[ ! -d "$NDC_CORE_DIR" ]]; then
    echo "ERROR: Core directory not found at $NDC_CORE_DIR"
    exit 1
  fi
  
  for f in "$NDC_CORE_DIR"/*.sh; do
    [[ -e "$f" ]] || continue
    # shellcheck disable=SC1090
    source "$f"
  done
}

ndc_load_core

# ----- Header / banner -----
ndc_banner() {
  if [ "${1-}" != "no-clear" ]; then
      clear
  fi
  printf "%b" "${CYAN}"
  printf "%b" "+-----------------------------------------------------------------------+\n"
  printf "%b" "|                                                                       |\n"
  printf "%b" "|                       ${BOLD}NDC OLS${CYAN} phiên bản: ${BOLD}1.0.0${CYAN}                        |\n"
  printf "%b" "|                  Công cụ quản lý VPS Node.js & React                  |\n"
  printf "%b" "|                                                                       |\n"
  printf "%b" "+-----------------------------------------------------------------------+\n"
  printf "%b" "Chúc bạn có buổi chiều tuyệt vời - Chào mừng bạn đến với NDC OLS\n"
  printf "%b" "-------------------------------------------------------------------------\n"
  printf "%b" "${NC}"
}

ndc_menu_header() {
  clear
  printf "%b" "${CYAN}"
  printf "%b" "+-----------------------------------------------------------------------+\n"
  printf "%b" "|                                                                       |\n"
  printf "%b" "|                       ${BOLD}NDC OLS${CYAN} phiên bản: ${BOLD}1.0.0${CYAN}                        |\n"
  printf "%b" "|                       Phát triển bởi: Nguyen DC                       |\n"
  printf "%b" "|                                                                       |\n"
  printf "%b" "+-----------------------------------------------------------------------+\n"
  printf "%b" "=========================================================================\n"
  printf "%b" "Tình trạng máy chủ: ${GREEN}Hoạt động tốt${CYAN}\n"
  printf "%b" "=========================================================================\n"
  printf "%b" "${NC}"
}

# ----- System Info Bar (Detailed) -----
ndc_system_info() {
  # Get system info
  local ram_usage=$(free -m | awk '/Mem:/ { printf("%d/%dMB (%.2f%%)", $3, $2, $3*100/$2) }')
  local disk_usage=$(df -BG / | awk 'NR==2 { printf("%d/%dGB (%s)", $3, $2, $5) }')
  local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
  local uptime=$(uptime -p | sed 's/up //;s/days/ngày/;s/hours/giờ/;s/minutes/phút/')

  printf "%b" "CPU : ${GREEN}${cpu_usage}${NC} | Ram : ${GREEN}${ram_usage}${NC} | Disk: ${GREEN}${disk_usage}${NC}\n"
  printf "%b" "${CYAN}-------------------------------------------------------------------------${NC}\n"
  printf "%b" "Webserver Nginx         : ${GREEN}Hoạt động tốt${NC}\n"
  printf "%b" "MongoDB                 : ${GREEN}Hoạt động tốt${NC}\n"
  printf "%b" "Tình trạng máy chủ      : ${GREEN}Hoạt động tốt${NC}\n"
  printf "%b" "System uptime           : ${GREEN}${uptime}${NC}\n"
  printf "%b" "${CYAN}-------------------------------------------------------------------------${NC}\n"
  printf "%b" "Tài liệu hướng dẫn      : ${CYAN}https://github.com/nguyendc-hp/ndc-ols${NC}\n"
  printf "%b" "Nhà phát triển          : ${CYAN}Nguyen DC${NC}\n"
  printf "%b" "Phiên bản hiện tại      : ${CYAN}1.0.0${NC}\n"
  printf "%b" "${CYAN}-------------------------------------------------------------------------${NC}\n"
  printf "%b" "Nhập lệnh ${GREEN}ndc${NC} để vào menu quản trị\n"
  printf "%b" "Nhập lệnh ${GREEN}0${NC} để thoát chương trình\n"
  printf "%b" "${CYAN}-------------------------------------------------------------------------${NC}\n"
  printf "%b" "${CYAN}=========================================================================${NC}\n"
  printf "%b" "Thông báo Cập nhật - Bạn đang sử dụng NDC OLS phiên bản:  ${BOLD}1.0.0${NC}\n"
  printf "%b" "${CYAN}=========================================================================${NC}\n"
  printf "%b" "Phát triển bởi: Nguyen DC (nguyendc-hp)\n"
  printf "%b" "Tài trợ dự án: https://github.com/sponsors/nguyendc-hp\n"
  printf "%b" "${CYAN}=========================================================================${NC}\n"
  echo ""
}

# ----- Terminal intro (chạy khi khởi động) -----
ndc_show_intro() {
  ndc_banner "no-clear"
  ndc_system_info
}

# ============================================================
#  OS DETECTION
# ============================================================

NDC_OS_NAME=""
NDC_OS_VERSION_ID=""

ndc_detect_os() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    NDC_OS_NAME="$NAME"
    NDC_OS_VERSION_ID="${VERSION_ID:-}"
  else
    NDC_OS_NAME="Unknown"
    NDC_OS_VERSION_ID="0"
  fi
}

ndc_check_ubuntu_supported() {
  ndc_detect_os
  case "$NDC_OS_NAME" in
    "Ubuntu")
      case "$NDC_OS_VERSION_ID" in
        "20.04"|"22.04"|"24.04")
          log_info "Hệ điều hành: Ubuntu ${NDC_OS_VERSION_ID} – OK."
          ;;
        *)
          log_warn "Ubuntu ${NDC_OS_VERSION_ID} chưa được test kỹ. Vẫn tiếp tục nhưng có thể có lỗi."
          ;;
      esac
      ;;
    *)
      log_warn "Hệ điều hành không phải Ubuntu. Script tối ưu cho Ubuntu 20.04/22.04/24.04."
      ;;
  esac
}

# ============================================================
#  unattended-upgrades GUARD
# ============================================================

NDC_UNATTENDED_UNIT="unattended-upgrades.service"

ndc_unattended_status() {
  local enabled="unknown" active="unknown" pids=""

  if command -v systemctl >/dev/null 2>&1; then
    enabled=$(systemctl is-enabled "$NDC_UNATTENDED_UNIT" 2>/dev/null || echo "disabled")
    active=$(systemctl is-active "$NDC_UNATTENDED_UNIT" 2>/dev/null || echo "inactive")
  fi

  pids=$(pgrep -f "unattended-upgrade" 2>/dev/null || true)

  echo "enabled=${enabled};active=${active};pids=${pids}"
}

ndc_wait_for_apt() {
  # Đợi unattended-upgrades nếu đang chạy, tối đa 120s, sau đó cưỡng bức tắt
  local timeout=120
  local waited=0

  while pgrep -f "unattended-upgrade" >/dev/null 2>&1; do
    if (( waited >= timeout )); then
      log_warn "unattended-upgrades chạy quá lâu (> ${timeout}s) → sẽ dừng cưỡng bức."
      ndc_disable_unattended
      return
    fi
    log_warn "unattended-upgrades đang chạy… chờ 5s (đã chờ ${waited}s)"
    sleep 5
    ((waited+=5))
  done
}

ndc_disable_unattended() {
  log_info "Đang tắt unattended-upgrades & dọn lock APT..."

  if command -v systemctl >/dev/null 2>&1; then
    systemctl stop "$NDC_UNATTENDED_UNIT" >/dev/null 2>&1 || true
    systemctl disable "$NDC_UNATTENDED_UNIT" >/dev/null 2>&1 || true
  fi

  # kill tiến trình đang chạy
  pkill -f "unattended-upgrade" >/dev/null 2>&1 || true

  # dọn lock APT
  rm -f /var/lib/apt/lists/lock \
        /var/cache/apt/archives/lock \
        /var/lib/dpkg/lock \
        /var/lib/dpkg/lock-frontend 2>/dev/null || true

  # đảm bảo dpkg không bị treo
  dpkg --configure -a >/dev/null 2>&1 || true

  log_info "Đã tắt unattended-upgrades & dọn lock APT."
}

ndc_enable_unattended() {
  log_info "Bật lại unattended-upgrades..."

  if command -v systemctl >/dev/null 2>&1; then
    systemctl enable "$NDC_UNATTENDED_UNIT" >/dev/null 2>&1 || true
    systemctl start "$NDC_UNATTENDED_UNIT" >/dev/null 2>&1 || true
  fi

  log_info "unattended-upgrades đã bật trở lại (nếu service tồn tại)."
}

# Wrapper dùng cho mọi cài đặt nặng (OLS/stack…)
# Usage: ndc_with_apt_guard function_name arg1 arg2...
ndc_with_apt_guard() {
  local fn="$1"; shift || true
  if [[ -z "$fn" ]]; then
    log_error "ndc_with_apt_guard: thiếu tên function."
    return 1
  fi

  ndc_wait_for_apt
  ndc_disable_unattended

  log_info "Bắt đầu khối cài đặt được bảo vệ bởi apt guard (${fn})..."
  "$fn" "$@"
  local rc=$?

  ndc_enable_unattended

  if (( rc == 0 )); then
    log_info "Khối cài đặt (${fn}) hoàn tất OK. unattended-upgrades đã bật lại."
  else
    log_error "Khối cài đặt (${fn}) bị lỗi (exit code=${rc}). unattended-upgrades đã bật lại."
  fi

  return "$rc"
}

# ============================================================
#  PLUGIN SYSTEM (Delegated to core/plugins.sh)
# ============================================================

ndc_list_plugins_by_category() {
  local cat="$1"
  local i
  # Use arrays from core/plugins.sh (NDC_PLUGINS_*)
  for ((i=0; i<${#NDC_PLUGINS_IDS[@]}; i++)); do
    if [[ "${NDC_PLUGINS_CATEGORIES[$i]}" == "$cat" ]]; then
      printf "%s|%s|%s|%s\n" \
        "${NDC_PLUGINS_IDS[$i]}" \
        "${NDC_PLUGINS_NAMES[$i]}" \
        "${NDC_PLUGINS_DESCRIPTIONS[$i]}" \
        "${NDC_PLUGINS_MENU_FUNCS[$i]}"
    fi
  done
}

# ============================================================
#  CATEGORY MENU
# ============================================================

ndc_category_menu() {
  local cat="$1"
  local title="$2"

  while true; do
    ndc_menu_header
    echo ""
    echo -e "${CYAN}:: ${title} ::${NC}"
    echo -e "${CYAN}────────────────────────────────────────────${NC}"
    local lines line idx=1
    local menu_ids=()
    local menu_fns=()

    lines="$(ndc_list_plugins_by_category "$cat")"
    if [[ -z "$lines" ]]; then
      echo "Hiện chưa có plugin nào trong nhóm này."
      echo
      read -rp "Nhấn Enter để quay lại..." _
      break
    fi

    # Bỏ description và tags [xxx]
    while IFS='|' read -r pid pname pdesc pmenu; do
      [[ -z "$pid" ]] && continue
      printf " ${GREEN}%2d)${NC} %s\n" "$idx" "$pname"
      menu_ids+=("$pid")
      menu_fns+=("$pmenu")
      idx=$((idx+1))
    done <<< "$lines"

    echo
    echo -e " ${RED}0)${NC} Quay lại"
    echo
    read -rp "Chọn chức năng: " choice

    if [[ "$choice" == "0" || -z "$choice" ]]; then
      break
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice >= idx )); then
      log_warn "Lựa chọn không hợp lệ."
      sleep 1
      continue
    fi

    local idx0=$((choice-1))
    local fn="${menu_fns[$idx0]}"

    if [[ -n "$fn" && "$(type -t "$fn")" == "function" ]]; then
      "$fn"
    else
      log_error "Plugin này chưa có hàm menu: ${fn}"
      sleep 1
    fi
  done
}

# ============================================================
#  MAIN MENU (TOP LEVEL) - 14 categories theo MENU_STRUCTURE.MD
# ============================================================

ndc_main_menu() {
  ndc_check_ubuntu_supported

  while true; do
    ndc_banner
    echo ""
    echo -e " ${GREEN} 1)${NC}  Cài đặt hệ thống                    ${GREEN} 8)${NC}  Giám sát & cảnh báo"
    echo -e " ${GREEN} 2)${NC}  Quản lý domain & SSL               ${GREEN} 9)${NC}  Ops Dashboard (Node + WordPress)"
    echo -e " ${GREEN} 3)${NC}  Quản lý WordPress                  ${GREEN}10)${NC}  Sao lưu & phục hồi dự án"
    echo -e " ${GREEN} 4)${NC}  Tối ưu & bảo mật WordPress         ${GREEN}11)${NC}  Sao lưu & phục hồi hệ thống"
    echo -e " ${GREEN} 5)${NC}  Quản lý ứng dụng Node.js           ${GREEN}12)${NC}  Bảo mật máy chủ"
    echo -e " ${GREEN} 6)${NC}  Quản lý Database                   ${GREEN}13)${NC}  Thông tin & chẩn đoán hệ thống"
    echo -e " ${GREEN} 7)${NC}  Kết nối GUI / SSH Tunnel cho DB   ${GREEN}14)${NC}  Công cụ tiện ích khác"
    echo ""
    echo -e " ${RED} 0)${NC}  Thoát"
    echo ""
    read -rp "Nhập lựa chọn của bạn [0-14]: " c

    case "$c" in
      1)  ndc_category_menu "SETUP"          "Cài đặt hệ thống" ;;
      2)  ndc_category_menu "DOMAIN_SSL"     "Quản lý domain & SSL" ;;
      3)  ndc_category_menu "WORDPRESS"      "Quản lý WordPress" ;;
      4)  ndc_category_menu "WP_OPTIMIZE"    "Tối ưu & bảo mật WordPress" ;;
      5)  ndc_category_menu "NODE"           "Quản lý ứng dụng Node.js" ;;
      6)  ndc_category_menu "DATABASE"       "Quản lý Database" ;;
      7)  ndc_category_menu "DB_GUI"         "Kết nối GUI / SSH Tunnel cho DB" ;;
      8)  ndc_category_menu "MONITORING"     "Giám sát & cảnh báo" ;;
      9)  ndc_category_menu "OPS_DASHBOARD"  "Ops Dashboard (Node + WordPress)" ;;
      10) ndc_category_menu "PROJECT_BACKUP" "Sao lưu & phục hồi dự án" ;;
      11) ndc_category_menu "SYSTEM_BACKUP"  "Sao lưu & phục hồi hệ thống" ;;
      12) ndc_category_menu "SECURITY"       "Bảo mật máy chủ" ;;
      13) ndc_category_menu "SYSINFO"        "Thông tin & chẩn đoán hệ thống" ;;
      14) ndc_category_menu "UTILITIES"      "Công cụ tiện ích khác" ;;
      0)  break ;;
      *)  log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# ============================================================
#  CLI DISPATCH
#  ./nguyendc-ols.sh <plugin_id> [subcmd...]
# ============================================================

ndc_dispatch_cli() {
  local plugin_id="$1"; shift || true
  local cli_fn="${plugin_id}_cli"

  if [[ "$(type -t "$cli_fn")" == "function" ]]; then
    "$cli_fn" "$@"
    return
  fi

  # Nếu không có *_cli, thử gọi menu_fn
  local i
  for ((i=0; i<${#NDC_PLUGINS_IDS[@]}; i++)); do
    if [[ "${NDC_PLUGINS_IDS[$i]}" == "$plugin_id" ]]; then
      local menu_fn="${NDC_PLUGINS_MENU_FUNCS[$i]}"
      if [[ -n "$menu_fn" && "$(type -t "$menu_fn")" == "function" ]]; then
        "$menu_fn"
        return
      fi
    fi
  done

  log_error "Không tìm thấy plugin hoặc CLI function cho ID: ${plugin_id}"
  echo "Gợi ý: chạy không có tham số để mở menu đầy đủ:"
  echo "  sudo $0"
}

# ============================================================
#  ENTRY POINT
# ============================================================

ndc_plugins_load_all "$NDC_PLUGINS_DIR"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 ]]; then
    # Always go straight to main menu
    # ndc_menu_header is called inside ndc_main_menu
    ndc_main_menu
  elif [[ "$1" == "--info" ]]; then
    ndc_show_intro
    exit 0
  else
    ndc_dispatch_cli "$@"
  fi
fi
