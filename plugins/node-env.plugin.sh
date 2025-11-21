#!/usr/bin/env bash
#
# ======================================
# Plugin: Node Env Manager
# Project: nguyendc-ols
# ID: nodeenv
# Category: NODE
# ======================================

NODE_APPS_CONF="/etc/nguyendc-ols/node-apps.conf"

nodeenv_ensure_conf() {
  if [[ ! -f "$NODE_APPS_CONF" ]]; then
    log_warn "Chưa có ${NODE_APPS_CONF}. Hãy dùng Node App Manager để tạo app trước."
    return 1
  fi
  return 0
}

nodeenv_list_apps() {
  nodeenv_ensure_conf || return 1
  echo "Danh sách app Node:"
  echo "-------------------------------------------"
  awk -F'|' '{printf "- %-15s dir=%-30s domain=%s\n", $1,$3,$2}' "$NODE_APPS_CONF"
  echo "-------------------------------------------"
}

nodeenv_select_app() {
  nodeenv_ensure_conf || return 1
  local name="$1"
  if [[ -z "$name" ]]; then
    read -r -p "Tên app (pm2 name): " name
  fi
  local line
  line=$(grep "^${name}|" "$NODE_APPS_CONF" || true)
  if [[ -z "$line" ]]; then
    log_error "Không tìm thấy app '${name}' trong ${NODE_APPS_CONF}"
    return 1
  fi
  echo "$line"
}

nodeenv_get_dir_from_line() {
  local line="$1"
  IFS='|' read -r n d dir port <<< "$line"
  echo "$dir"
}

nodeenv_profiles_dir() {
  local app_dir="$1"
  echo "${app_dir}/.env-profiles"
}

nodeenv_list_profiles() {
  local app_dir="$1"
  local pdir
  pdir=$(nodeenv_profiles_dir "$app_dir")
  mkdir -p "$pdir"
  echo "Profiles cho app (${app_dir}):"
  ls -1 "$pdir" 2>/dev/null || echo "(chưa có profile)"
}

nodeenv_create_profile() {
  local app_dir="$1"
  local pdir
  pdir=$(nodeenv_profiles_dir "$app_dir")
  mkdir -p "$pdir"

  read -r -p "Tên profile (VD: dev, staging, prod): " prof
  [[ -z "$prof" ]] && { log_error "Profile không được trống."; return 1; }

  local src="${app_dir}/.env"
  local dst="${pdir}/${prof}.env"

  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
  else
    touch "$dst"
  fi

  log_info "Đã tạo profile ${prof} tại ${dst}"
  echo "Bạn có thể chỉnh sửa bằng: nano ${dst}"
}

nodeenv_switch_profile() {
  local app_dir="$1"
  local pdir prof src dst

  pdir=$(nodeenv_profiles_dir "$app_dir")
  mkdir -p "$pdir"

  nodeenv_list_profiles "$app_dir"
  echo
  read -r -p "Nhập tên profile cần dùng (VD: prod): " prof
  [[ -z "$prof" ]] && { log_error "Profile không được trống."; return 1; }

  src="${pdir}/${prof}.env"
  dst="${app_dir}/.env"

  if [[ ! -f "$src" ]]; then
    log_error "Không tìm thấy file ${src}"
    return 1
  fi

  cp "$src" "$dst"
  log_info "Đã switch .env sang profile '${prof}'."
}

nodeenv_show_active() {
  local app_dir="$1"
  local env="${app_dir}/.env"
  echo "===== .env hiện tại (${app_dir}) ====="
  if [[ -f "$env" ]]; then
    cat "$env"
  else
    echo "(Không có file .env)"
  fi
}

nodeenv_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "            Node Env Manager (Plugin)"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "1) Xem danh sách app Node"
    echo "2) Xem profile/.env cho 1 app"
    echo "3) Tạo profile mới từ .env hiện tại"
    echo "4) Switch .env sang profile khác"
    echo "0) Quay lại"
    echo
    read -rp "Chọn: " c

    case "$c" in
      1) nodeenv_list_apps; read -rp "Enter..." ;;
      2)
         read -rp "Tên app: " an
         line=$(nodeenv_select_app "$an") || { read -rp "Enter..."; continue; }
         dir=$(nodeenv_get_dir_from_line "$line")
         nodeenv_list_profiles "$dir"
         nodeenv_show_active "$dir"
         read -rp "Enter..." ;;
      3)
         read -rp "Tên app: " an
         line=$(nodeenv_select_app "$an") || { read -rp "Enter..."; continue; }
         dir=$(nodeenv_get_dir_from_line "$line")
         nodeenv_create_profile "$dir"
         read -rp "Enter..." ;;
      4)
         read -rp "Tên app: " an
         line=$(nodeenv_select_app "$an") || { read -rp "Enter..."; continue; }
         dir=$(nodeenv_get_dir_from_line "$line")
         nodeenv_switch_profile "$dir"
         read -rp "Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh nodeenv list|switch <app> <profile>
nodeenv_cli() {
  case "$1" in
    list|"")
      nodeenv_list_apps
      ;;
    switch)
      local app="$2"
      local prof="$3"
      line=$(nodeenv_select_app "$app") || return 1
      dir=$(nodeenv_get_dir_from_line "$line")
      if [[ -n "$prof" ]]; then
        # switch nhanh, không hỏi
        pdir=$(nodeenv_profiles_dir "$dir")
        src="${pdir}/${prof}.env"
        dst="${dir}/.env"
        if [[ ! -f "$src" ]]; then
          log_error "Không có profile ${prof} tại ${src}"
          return 1
        fi
        cp "$src" "$dst"
        log_info "Đã switch .env của ${app} sang profile ${prof}"
      else
        nodeenv_switch_profile "$dir"
      fi
      ;;
    *)
      echo "NodeEnv CLI:"
      echo "  nodeenv list                    - liệt kê app"
      echo "  nodeenv switch <app> [profile]  - switch profile .env"
      ;;
  esac
}

ndc_register_plugin \
  "nodeenv" \
  "Node Env Manager" \
  "NODE" \
  "Quản lý .env profile (dev/staging/prod) cho Node apps" \
  "nodeenv_menu"
