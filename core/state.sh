#!/usr/bin/env bash

# ======================================
# Quản lý state của nguyendc-ols
# ======================================

STATE_FILE="${STATE_FILE:-/etc/nguyendc-ols/state.conf}"

state_init() {
  if [[ ! -f "$STATE_FILE" ]]; then
    mkdir -p "$(dirname "$STATE_FILE")" 2>/dev/null || true
    touch "$STATE_FILE"
  fi
}

state_get() {
  local key="$1"
  state_init
  local line
  line="$(grep -E "^${key}=" "$STATE_FILE" 2>/dev/null | tail -n1 || true)"
  if [[ -z "$line" ]]; then
    echo ""
  else
    echo "${line#*=}"
  fi
}

state_set() {
  local key="$1"
  local value="$2"
  state_init
  if grep -qE "^${key}=" "$STATE_FILE" 2>/dev/null; then
    sed -i "s/^${key}=.*/${key}=${value}/" "$STATE_FILE"
  else
    echo "${key}=${value}" >> "$STATE_FILE"
  fi
}

state_is_enabled() {
  local key="$1"
  local val
  val="$(state_get "$key")"
  [[ "$val" == "1" ]]
}
