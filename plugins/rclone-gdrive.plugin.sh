#!/usr/bin/env bash

# ======================================
# Plugin: rclone Google Drive Backup
# Project: nguyendc-ols
# ID: rclone
# Category: BKP
# ======================================

RCLONE_STATE_KEY="RCLONE_INSTALLED"
RCLONE_REMOTE_NAME="gdrive"
RCLONE_DEFAULT_PATH="nguyendc-ols-backups"
BACKUP_BASE_DIR="/opt/nguyendc-ols/backups"

rclone_is_installed() {
  command -v rclone >/dev/null 2>&1
}

rclone_install() {
  if rclone_is_installed; then
    log_info "rclone đã được cài đặt, bỏ qua bước cài."
    state_set "$RCLONE_STATE_KEY" "1"
    return 0
  fi

  log_info "Bắt đầu cài đặt rclone..."

  if is_debian_like; then
    apt update
    apt install -y rclone
  elif is_rhel_like; then
    dnf install -y rclone
  else
    log_warn "Hệ điều hành hiện tại chưa hỗ trợ apt/dnf, thử script chính thức."
    curl https://rclone.org/install.sh | bash || {
      log_error "Cài đặt rclone thất bại."
      return 1
    }
  fi

  if rclone_is_installed; then
    log_info "Cài đặt rclone thành công. Phiên bản: $(rclone version 2>/dev/null | head -n1 || echo '?')"
    state_set "$RCLONE_STATE_KEY" "1"
  else
    log_error "rclone cài xong nhưng không chạy được."
    return 1
  fi
}

rclone_config_gdrive() {
  if ! rclone_is_installed; then
    log_error "rclone chưa được cài. Hãy cài trước."
    return 1
  fi

  log_info "Chạy rclone config. Hãy tạo remote ${RCLONE_REMOTE_NAME} trỏ đến Google Drive."
  echo "Gợi ý: nhập 'n' để tạo remote mới, name: ${RCLONE_REMOTE_NAME}, storage: drive."
  rclone config
}

rclone_backup_to_gdrive() {
  if ! rclone_is_installed; then
    log_error "rclone chưa được cài. Hãy cài trước."
    return 1
  fi

  mkdir -p "$BACKUP_BASE_DIR"

  read -r -p "Nhập tên remote (mặc định: ${RCLONE_REMOTE_NAME}): " remote
  remote="${remote:-${RCLONE_REMOTE_NAME}}"

  read -r -p "Nhập thư mục trên Google Drive (mặc định: ${RCLONE_DEFAULT_PATH}): " remote_dir
  remote_dir="${remote_dir:-${RCLONE_DEFAULT_PATH}}"

  local dest="${remote}:${remote_dir}"

  log_info "Đang sync ${BACKUP_BASE_DIR} -> ${dest} ..."
  rclone sync "${BACKUP_BASE_DIR}" "${dest}" --progress || {
    log_error "Backup lên Google Drive thất bại."
    return 1
  }

  log_info "Backup lên Google Drive thành công."
}

rclone_show_status_line() {
  if rclone_is_installed(); then
    echo "✅ rclone đã cài - remote mặc định: ${RCLONE_REMOTE_NAME}"
  else
    echo "❌ rclone chưa cài"
  fi
}

rclone_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "     Backup lên Google Drive (rclone)"
    echo "                nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    rclone_show_status_line
    echo
    echo "Local backup dir: ${BACKUP_BASE_DIR}"
    echo
    echo "1) Cài đặt rclone"
    echo "2) rclone config (tạo remote Google Drive)"
    echo "3) Sync backup local -> Google Drive"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) rclone_install;          read -rp "Nhấn Enter để tiếp tục..." ;;
      2) rclone_config_gdrive;    read -rp "Nhấn Enter để tiếp tục..." ;;
      3) rclone_backup_to_gdrive; read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "rclone" \
  "rclone Google Drive" \
  "BKP" \
  "Backup thư mục backup local lên Google Drive bằng rclone" \
  "rclone_menu"
