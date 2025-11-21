#!/usr/bin/env bash

# ======================================
# Plugin system core cho nguyendc-ols
# ======================================

NDC_PLUGINS_IDS=()
NDC_PLUGINS_NAMES=()
NDC_PLUGINS_CATEGORIES=()
NDC_PLUGINS_DESCRIPTIONS=()
NDC_PLUGINS_MENU_FUNCS=()

ndc_register_plugin() {
  local id="$1"          # ví dụ: postgres
  local name="$2"        # ví dụ: PostgreSQL
  local category="$3"    # ví dụ: DB, SYS, GUI
  local description="$4" # mô tả ngắn
  local menu_func="$5"   # hàm menu chính của plugin

  NDC_PLUGINS_IDS+=("$id")
  NDC_PLUGINS_NAMES+=("$name")
  NDC_PLUGINS_CATEGORIES+=("$category")
  NDC_PLUGINS_DESCRIPTIONS+=("$description")
  NDC_PLUGINS_MENU_FUNCS+=("$menu_func")

  log_debug "Đăng ký plugin: id=$id name=$name category=$category menu_func=$menu_func"
}

ndc_plugins_count() {
  echo "${#NDC_PLUGINS_IDS[@]}"
}

ndc_plugin_index_by_id() {
  local search_id="$1"
  local i
  for ((i = 0; i < ${#NDC_PLUGINS_IDS[@]}; i++)); do
    if [[ "${NDC_PLUGINS_IDS[$i]}" == "$search_id" ]]; then
      echo "$i"
      return 0
    fi
  done
  echo "-1"
  return 1
}

ndc_plugin_menu_by_index() {
  local idx="$1"
  local func="${NDC_PLUGINS_MENU_FUNCS[$idx]}"
  if [[ -n "$func" && "$(type -t "$func")" == "function" ]]; then
    "$func"
  else
    log_error "Plugin ở index $idx không có hàm menu hợp lệ: $func"
  fi
}

ndc_plugins_load_all() {
  local plugins_dir="$1"
  log_debug "Đang load plugin từ thư mục: $plugins_dir"

  if [[ ! -d "$plugins_dir" ]]; then
    log_warn "Thư mục plugin không tồn tại: $plugins_dir"
    return
  fi

  local f
  for f in "$plugins_dir"/*.plugin.sh; do
    [[ -e "$f" ]] || continue
    log_debug "Sourcing plugin: $f"
    # shellcheck source=/dev/null
    source "$f"
  done
}
