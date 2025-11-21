#!/usr/bin/env bash

# ======================================
# Phát hiện hệ điều hành cho nguyendc-ols
# ======================================

OS_ID=""
OS_VERSION_ID=""
OS_ID_LIKE=""

os_detect() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="$ID"
    OS_VERSION_ID="$VERSION_ID"
    OS_ID_LIKE="$ID_LIKE"
  else
    OS_ID="unknown"
    OS_VERSION_ID="unknown"
    OS_ID_LIKE=""
  fi
}

is_debian_like() {
  os_detect
  [[ "$OS_ID_LIKE" == *"debian"* || "$OS_ID" == "debian" || "$OS_ID" == "ubuntu" ]]
}

is_rhel_like() {
  os_detect
  [[ "$OS_ID_LIKE" == *"rhel"* || "$OS_ID" == "centos" || "$OS_ID" == "rocky" || "$OS_ID" == "almalinux" ]]
}

print_os_info() {
  os_detect
  echo "Hệ điều hành: $OS_ID $OS_VERSION_ID"
}
