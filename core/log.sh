#!/usr/bin/env bash

# ======================================
# Logging cho nguyendc-ols
# ======================================

LOG_TIME_FORMAT="+%Y-%m-%d %H:%M:%S"
LOG_FILE="${LOG_FILE:-/var/log/nguyendc-ols.log}"

NC="\e[0m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"

log_ts() {
  date "${LOG_TIME_FORMAT}"
}

log_to_file() {
  local level="$1"
  local msg="$2"
  mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
  echo "$(log_ts) [$level] $msg" >> "$LOG_FILE"
}

log_info() {
  local msg="$1"
  echo -e "${GREEN}[INFO]${NC} $msg"
  log_to_file "INFO" "$msg"
}

log_warn() {
  local msg="$1"
  echo -e "${YELLOW}[WARN]${NC} $msg"
  log_to_file "WARN" "$msg"
}

log_error() {
  local msg="$1"
  echo -e "${RED}[ERROR]${NC} $msg"
  log_to_file "ERROR" "$msg"
}

log_debug() {
  local msg="$1"
  if [[ "${NGUYENDC_OLS_DEBUG:-0}" == "1" ]]; then
    echo -e "${BLUE}[DEBUG]${NC} $msg"
  fi
  log_to_file "DEBUG" "$msg"
}
