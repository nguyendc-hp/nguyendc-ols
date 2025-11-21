#!/usr/bin/env bash
#
# ======================================
# Plugin: Node Git Deploy
# Project: nguyendc-ols
# ID: nodedeploy
# Category: NODE
# ======================================

NODE_DEPLOY_CONF="/etc/nguyendc-ols/node-git-deploy.conf"

nodedeploy_require_pm2() {
  if ! command -v pm2 >/dev/null 2>&1; then
    log_error "PM2 chưa cài."
    return 1
  fi
}

nodedeploy_require_git() {
  if ! command -v git >/dev/null 2>&1; then
    log_error "Git chưa cài."
    return 1
  fi
}

nodedeploy_ensure_conf() {
  mkdir -p "$(dirname "$NODE_DEPLOY_CONF")"
  [[ -f "$NODE_DEPLOY_CONF" ]] || touch "$NODE_DEPLOY_CONF"
}

nodedeploy_list() {
  nodedeploy_ensure_conf
  echo "Danh sách project deploy từ Git:"
  echo "------------------------------------------------------------"
  if [[ ! -s "$NODE_DEPLOY_CONF" ]]; then
    echo "(Chưa có config nào)"
  else
    awk -F'|' '{printf "- %-15s dir=%-25s branch=%-10s pm2=%-15s\n", $1,$3,$4,$5}' "$NODE_DEPLOY_CONF"
  fi
  echo "------------------------------------------------------------"
}

nodedeploy_add_project() {
  nodedeploy_require_pm2 || return 1
  nodedeploy_require_git || return 1
  nodedeploy_ensure_conf

  local name repo dir branch pm2_name build_cmd start_cmd
  read -r -p "Tên project (id, VD: api-mivn): " name
  read -r -p "Git repo URL (VD: git@github.com:user/repo.git): " repo
  read -r -p "Thư mục local (VD: /var/www/node/api-mivn): " dir
  read -r -p "Branch (default: main): " branch
  read -r -p "PM2 process name (VD: api-mivn): " pm2_name
  read -r -p "Lệnh build (VD: npm run build, có thể để trống): " build_cmd
  read -r -p "Lệnh start (VD: npm start hoặc node index.js): " start_cmd

  branch="${branch:-main}"

  [[ -z "$name" || -z "$repo" || -z "$dir" || -z "$pm2_name" || -z "$start_cmd" ]] && {
    log_error "name, repo, dir, pm2_name, start_cmd không được trống."
    return 1
  }

  echo "${name}|${repo}|${dir}|${branch}|${pm2_name}|${build_cmd}|${start_cmd}" >> "$NODE_DEPLOY_CONF"
  log_info "Đã thêm project ${name} vào config."
}

nodedeploy_find_project() {
  local name="$1"
  nodedeploy_ensure_conf
  grep "^${name}|" "$NODE_DEPLOY_CONF" || true
}

nodedeploy_git_clone_or_pull() {
  local repo="$1"
  local dir="$2"
  local branch="$3"

  if [[ -d "$dir/.git" ]]; then
    log_info "Thư mục ${dir} đã là repo git, tiến hành git pull..."
    cd "$dir" || return 1
    git fetch --all
    git checkout "$branch"
    git pull origin "$branch"
  else
    mkdir -p "$dir"
    cd "$(dirname "$dir")" || return 1
    git clone -b "$branch" "$repo" "$(basename "$dir")"
  fi
}

nodedeploy_install_and_build() {
  local dir="$1"
  local build_cmd="$2"

  cd "$dir" || return 1

  if [[ -f "package-lock.json" ]]; then
    npm ci || npm install
  else
    npm install
  fi

  if [[ -n "$build_cmd" ]]; then
    log_info "Chạy lệnh build: ${build_cmd}"
    eval "$build_cmd"
  fi
}

nodedeploy_restart_pm2() {
  local dir="$1"
  local pm2_name="$2"
  local start_cmd="$3"

  cd "$dir" || return 1

  if pm2 describe "$pm2_name" >/dev/null 2>&1; then
    log_info "Restart PM2 process: ${pm2_name}"
    pm2 restart "$pm2_name"
  else
    log_info "PM2 process chưa tồn tại, start mới: ${pm2_name}"
    pm2 start $start_cmd --name "$pm2_name" --cwd "$dir" --env production
  fi

  pm2 save
}

nodedeploy_notify() {
  local msg="$1"
  if [[ "$(type -t telegram_send_message)" == "function" ]]; then
    telegram_send_message "$msg" || true
  fi
}

nodedeploy_deploy_project() {
  nodedeploy_require_pm2 || return 1
  nodedeploy_require_git || return 1

  read -r -p "Tên project trong config (VD: api-mivn): " name
  [[ -z "$name" ]] && return 1

  local line
  line=$(nodedeploy_find_project "$name")
  if [[ -z "$line" ]]; then
    log_error "Không tìm thấy project '${name}' trong ${NODE_DEPLOY_CONF}"
    return 1
  fi

  IFS='|' read -r pname repo dir branch pm2_name build_cmd start_cmd <<< "$line"

  log_info "=== Deploy project: ${pname} ==="
  log_info "Repo: ${repo}"
  log_info "Dir : ${dir}"
  log_info "Branch: ${branch}"
  log_info "PM2 : ${pm2_name}"

  local started_at
  started_at="$(date +%Y-%m-%d' '%H:%M:%S)"

  if ! nodedeploy_git_clone_or_pull "$repo" "$dir" "$branch"; then
    log_error "Git pull/clone thất bại."
    nodedeploy_notify "❌ Node deploy FAILED: ${pname} (git error)"
    return 1
  fi

  if ! nodedeploy_install_and_build "$dir" "$build_cmd"; then
    log_error "npm install/build thất bại."
    nodedeploy_notify "❌ Node deploy FAILED: ${pname} (npm/build error)"
    return 1
  fi

  if ! nodedeploy_restart_pm2 "$dir" "$pm2_name" "$start_cmd"; then
    log_error "PM2 start/restart thất bại."
    nodedeploy_notify "❌ Node deploy FAILED: ${pname} (pm2 error)"
    return 1
  fi

  local finished_at
  finished_at="$(date +%Y-%m-%d' '%H:%M:%S)"
  log_info "Deploy ${pname} hoàn tất."

  nodedeploy_notify "✅ Node deploy OK: ${pname}\nStarted: ${started_at}\nFinished: ${finished_at}"
}

nodedeploy_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "            Node Git Deploy (Plugin)"
    echo "                 nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo "1) Thêm project Node deploy từ Git"
    echo "2) Liệt kê project"
    echo "3) Deploy/Update 1 project"
    echo "0) Quay lại"
    echo
    read -rp "Chọn: " c
    case "$c" in
      1) nodedeploy_add_project;  read -rp "Enter..." ;;
      2) nodedeploy_list;         read -rp "Enter..." ;;
      3) nodedeploy_deploy_project; read -rp "Enter..." ;;
      0) break ;;
      *) log_warn "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh nodedeploy add|list|deploy
nodedeploy_cli() {
  case "$1" in
    add)    nodedeploy_add_project ;;
    list)   nodedeploy_list ;;
    deploy) nodedeploy_deploy_project ;;
    *)
      echo "NodeDeploy CLI:"
      echo "  nodedeploy add     - thêm project mới"
      echo "  nodedeploy list    - liệt kê project"
      echo "  nodedeploy deploy  - deploy/update 1 project"
      ;;
  esac
}

ndc_register_plugin \
  "nodedeploy" \
  "Node Git Deploy" \
  "NODE" \
  "Deploy/update app Node từ Git + PM2 + Telegram notify" \
  "nodedeploy_menu"
