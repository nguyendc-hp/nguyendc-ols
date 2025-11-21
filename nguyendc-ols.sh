#!/usr/bin/env bash
#
# ============================================================
# nguyendc-ols
# Node.js, WordPress & Database VPS Management Tool
#
# Core launcher + plugin system + unattended-upgrades guard
# ============================================================

set -euo pipefail

# ----- Đường dẫn gốc & thư mục plugin -----
NDC_BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NDC_PLUGINS_DIR="${NDC_BASE_DIR}/plugins"

# ----- Thư mục cấu hình & state -----
NDC_ETC_DIR="/etc/nguyendc-ols"
NDC_STATE_FILE="${NDC_ETC_DIR}/state.env"

mkdir -p "$NDC_ETC_DIR"

# ----- Logging helpers -----
log_info()  { echo -e "[\e[32mINFO\e[0m]  $*"; }
log_warn()  { echo -e "[\e[33mWARN\e[0m]  $*"; }
log_error() { echo -e "[\e[31mERROR\e[0m] $*" >&2; }

# ----- State helpers (key=value trong state.env) -----
state_get() {
  local key="$1"
  [[ -f "$NDC_STATE_FILE" ]] || return 0
  # shellcheck disable=SC1090
  source "$NDC_STATE_FILE"
  eval "echo \"\${$key-}\""
}

state_set() {
  local key="$1" value="$2"
  touch "$NDC_STATE_FILE"

  # Xoá dòng cũ (nếu có)
  sed -i "/^${key}=/d" "$NDC_STATE_FILE" 2>/dev/null || true
  # Ghi dòng mới
  printf '%s=%q\n' "$key" "$value" >> "$NDC_STATE_FILE"
}

# ----- Header / banner -----
ndc_header() {
  clear
  cat <<'EOF'
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║              nguyendc-ols - VPS Management Tool                ║
║         WordPress + Node.js + Database Management              ║
║                                                                ║
║    Node.js · WordPress · PostgreSQL · MongoDB · MySQL ·        ║
║    MariaDB · Redis · Backup · Security · Monitoring            ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

EOF
}

# ----- Terminal intro (chạy khi khởi động) -----
ndc_show_intro() {
  clear
  cat <<'EOF'
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║         🚀  Welcome to nguyendc-ols VPS Manager 🚀             ║
║                                                                ║
║    Your Complete Solution for:                                ║
║    ✓ WordPress Installation & Management                      ║
║    ✓ Node.js Application Deployment                           ║
║    ✓ Database Management (MongoDB, MySQL, PostgreSQL)          ║
║    ✓ Backup & Recovery                                        ║
║    ✓ Security & Monitoring                                    ║
║    ✓ SSL/HTTPS Automation                                     ║
║                                                                ║
║    Type: ndc                 to open the menu                 ║
║    Type: ndc help            for quick commands               ║
║                                                                ║
║    📧 Email: support@nguyendc-ols.com                          ║
║    🌐 GitHub: nguyendc-hp/nguyendc-ols                        ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

EOF
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
#  PLUGIN SYSTEM
# ============================================================

# Mỗi plugin sẽ gọi:
# ndc_register_plugin "id" "Name" "CATEGORY" "Description" "menu_function"

NDC_PLUGIN_IDS=()
NDC_PLUGIN_NAMES=()
NDC_PLUGIN_CATEGORIES=()
NDC_PLUGIN_DESCS=()
NDC_PLUGIN_MENU_FNS=()

ndc_register_plugin() {
  local id="$1" name="$2" cat="$3" desc="$4" menu_fn="$5"

  NDC_PLUGIN_IDS+=("$id")
  NDC_PLUGIN_NAMES+=("$name")
  NDC_PLUGIN_CATEGORIES+=("$cat")
  NDC_PLUGIN_DESCS+=("$desc")
  NDC_PLUGIN_MENU_FNS+=("$menu_fn")
}

ndc_load_plugins() {
  if [[ ! -d "$NDC_PLUGINS_DIR" ]]; then
    log_warn "Không tìm thấy thư mục plugins: ${NDC_PLUGINS_DIR}"
    return 0
  fi

  for f in "$NDC_PLUGINS_DIR"/*.plugin.sh; do
    [[ -e "$f" ]] || continue
    # shellcheck disable=SC1090
    source "$f"
  done
}

ndc_list_plugins_by_category() {
  local cat="$1"
  local i
  for ((i=0; i<${#NDC_PLUGIN_IDS[@]}; i++)); do
    if [[ "${NDC_PLUGIN_CATEGORIES[$i]}" == "$cat" ]]; then
      printf "%s|%s|%s|%s\n" \
        "${NDC_PLUGIN_IDS[$i]}" \
        "${NDC_PLUGIN_NAMES[$i]}" \
        "${NDC_PLUGIN_DESCS[$i]}" \
        "${NDC_PLUGIN_MENU_FNS[$i]}"
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
    ndc_header
    echo "Category: ${title} (${cat})"
    echo "────────────────────────────────────────────"
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

    while IFS='|' read -r pid pname pdesc pmenu; do
      [[ -z "$pid" ]] && continue
      printf "%2d) %-30s [%s]\n" "$idx" "$pname" "$pid"
      echo "    $pdesc"
      menu_ids+=("$pid")
      menu_fns+=("$pmenu")
      idx=$((idx+1))
    done <<< "$lines"

    echo
    echo " 0) Quay lại"
    echo
    read -rp "Chọn plugin: " choice

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
#  MAIN MENU (TOP LEVEL)
# ============================================================

ndc_main_menu() {
  ndc_check_ubuntu_supported

  while true; do
    ndc_header
    echo "1) WordPress tools"
    echo "2) Node.js tools"
    echo "3) Database tools"
    echo "4) Ops & Monitoring"
    echo "5) System & Security"
    echo
    echo "0) Thoát"
    echo
    read -rp "Chọn: " c

    case "$c" in
      1) ndc_category_menu "WORDPRESS" "WordPress tools" ;;
      2) ndc_category_menu "NODE"      "Node.js tools" ;;
      3) ndc_category_menu "DB"        "Database tools" ;;
      4) ndc_category_menu "OPS"       "Ops & Monitoring" ;;
      5) ndc_category_menu "SYSTEM"    "System & Security" ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
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
  for ((i=0; i<${#NDC_PLUGIN_IDS[@]}; i++)); do
    if [[ "${NDC_PLUGIN_IDS[$i]}" == "$plugin_id" ]]; then
      local menu_fn="${NDC_PLUGIN_MENU_FNS[$i]}"
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

ndc_load_plugins

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 ]]; then
    # Show intro if first time (check if config dir exists)
    if [[ ! -d "$NDC_ETC_DIR" ]] || [[ ! -f "$NDC_STATE_FILE" ]]; then
      ndc_show_intro
      sleep 2
    fi
    ndc_header
    ndc_main_menu
  else
    ndc_dispatch_cli "$@"
  fi
fi
