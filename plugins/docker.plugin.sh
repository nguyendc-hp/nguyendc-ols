#!/usr/bin/env bash

# ======================================
# Plugin: Docker Engine
# Project: nguyendc-ols
# ID: docker
# Category: SYSTEM
# ======================================

DOCKER_STATE_KEY="DOCKER_INSTALLED"

docker_is_installed() {
  command -v docker >/dev/null 2>&1
}

docker_install() {
  if docker_is_installed; then
    log_info "Docker đã được cài đặt, bỏ qua bước cài."
    state_set "$DOCKER_STATE_KEY" "1"
    return 0
  fi

  log_info "Bắt đầu cài đặt Docker (script chính thức)..."

  # Script chính thức từ Docker
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sh /tmp/get-docker.sh || {
    log_error "Cài đặt Docker thất bại."
    return 1
  }

  systemctl enable docker --now

  # Cài docker-compose nếu chưa có
  if ! command -v docker-compose >/dev/null 2>&1; then
    log_info "Cài đặt docker-compose (v2, alias docker compose)..."
    # Trên bản mới, docker compose tích hợp trong docker, nhưng ta thêm binary v1 nếu muốn.
    DOCKER_COMPOSE_VERSION="1.29.2"
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
      -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
  fi

  if docker_is_installed; then
    log_info "Cài đặt Docker thành công. Phiên bản: $(docker -v 2>/dev/null || echo '?')"
    state_set "$DOCKER_STATE_KEY" "1"
  else
    log_error "Docker cài xong nhưng không chạy được."
    return 1
  fi
}

docker_uninstall() {
  log_warn "Bạn sắp gỡ Docker. Thao tác này sẽ gỡ engine và có thể ảnh hưởng tất cả container."
  read -r -p "Bạn có chắc chắn muốn tiếp tục? (gõ YES_TO_REMOVE_DOCKER): " confirm
  if [[ "$confirm" != "YES_TO_REMOVE_DOCKER" ]]; then
    log_info "Đã huỷ thao tác gỡ Docker."
    return 0
  fi

  systemctl stop docker 2>/dev/null || true

  if is_debian_like; then
    apt purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose || true
    apt autoremove -y || true
  elif is_rhel_like; then
    dnf remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose || true
  fi

  rm -f /usr/local/bin/docker-compose 2>/dev/null || true
  rm -rf /var/lib/docker 2>/dev/null || true
  rm -rf /var/lib/containerd 2>/dev/null || true

  state_set "$DOCKER_STATE_KEY" "0"
  log_info "Đã gỡ Docker (có thể cần kiểm tra dữ liệu container/volume thủ công)."
}

docker_show_status_line() {
  if docker_is_installed; then
    echo "✅ Docker: $(docker -v 2>/dev/null || echo '?')"
  else
    echo "❌ Docker chưa cài"
  fi
}

docker_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "           Quản lý Docker Engine"
    echo "                nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Trạng thái: "
    docker_show_status_line
    echo
    echo "1) Cài đặt Docker + docker-compose"
    echo "2) Gỡ Docker"
    echo "3) Xem danh sách container (docker ps)"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) docker_install;   read -rp "Nhấn Enter để tiếp tục..." ;;
      2) docker_uninstall; read -rp "Nhấn Enter để tiếp tục..." ;;
      3) docker ps -a;      read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

ndc_register_plugin \
  "docker" \
  "Docker Engine" \
  "SETUP" \
  "" \
  "docker_menu"
