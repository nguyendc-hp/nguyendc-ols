#!/usr/bin/env bash

# ============================================================
# nguyendc-ols Installation Script
# Project: nguyendc-ols
# Description: Automated setup for VPS management tool
# ============================================================

set -euo pipefail

# Logging functions (without color codes to avoid shell issues)
log_info()  { echo "[INFO]  $*"; }
log_warn()  { echo "[WARN]  $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }
log_step()  { echo "[STEP]  $*"; }

# ============================================================
# PRE-FLIGHT CHECKS
# ============================================================

check_root() {
  if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root or with sudo"
    exit 1
  fi
}

check_ubuntu() {
  if [[ ! -f /etc/os-release ]]; then
    log_error "Cannot detect OS version"
    exit 1
  fi

  source /etc/os-release
  local version="${VERSION_ID:-}"

  case "$version" in
    20.04|22.04|24.04)
      log_info "Detected Ubuntu ${version} - OK"
      ;;
    *)
      log_warn "Ubuntu ${version} may not be fully tested"
      read -rp "Continue anyway? (y/N): " cont
      [[ "$cont" != "y" ]] && exit 0
      ;;
  esac
}

check_dependencies() {
  log_step "Checking dependencies..."
  local missing=()

  for cmd in curl git bash; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_warn "Missing dependencies: ${missing[*]}"
    log_info "Installing dependencies..."
    apt-get update
    apt-get install -y "${missing[@]}"
  else
    log_info "All dependencies found"
  fi
}

# ============================================================
# INSTALLATION FUNCTIONS
# ============================================================

install_nguyendc_ols() {
  log_step "Installing nguyendc-ols..."

  # Determine installation method
  if [[ -f "$(pwd)/nguyendc-ols.sh" ]]; then
    # Already in the cloned directory
    INSTALL_DIR="$(pwd)"
    log_info "Using current directory: $INSTALL_DIR"
  else
    # Need to copy to /opt directory
    INSTALL_DIR="/opt/nguyendc-ols"
    log_info "Target installation directory: $INSTALL_DIR"
    
    if [[ ! -d "$INSTALL_DIR" ]]; then
      mkdir -p "$INSTALL_DIR"
    fi
    
    # Check if we have files to copy from current directory
    if [[ -f "./nguyendc-ols.sh" ]]; then
      log_info "Copying files from current directory..."
      cp -r ./* "$INSTALL_DIR/" 2>/dev/null || true
    elif [[ -d "./nguyendc-ols" ]]; then
      log_info "Copying from ./nguyendc-ols..."
      cp -r ./nguyendc-ols/* "$INSTALL_DIR/" 2>/dev/null || true
    else
      log_warn "nguyendc-ols files not found locally"
      log_info "Cloning from GitHub..."
      git clone https://github.com/nguyendc-hp/nguyendc-ols.git "$INSTALL_DIR" 2>&1 || {
        log_error "Failed to clone repository"
        exit 1
      }
    fi
  fi

  # Verify installation
  if [[ ! -f "$INSTALL_DIR/nguyendc-ols.sh" ]]; then
    log_error "Installation failed - nguyendc-ols.sh not found at $INSTALL_DIR/nguyendc-ols.sh"
    log_error "Current directory: $(pwd)"
    log_error "Directory contents: $(ls -la $(pwd) 2>/dev/null | head -20)"
    exit 1
  fi

  log_info "Installation directory: $INSTALL_DIR"
  echo "$INSTALL_DIR"
}

setup_permissions() {
  local install_dir="$1"
  log_step "Setting up permissions..."

  chmod +x "$install_dir/nguyendc-ols.sh"
  chmod +x "$install_dir/core"/*.sh 2>/dev/null || true
  chmod +x "$install_dir/plugins"/*.sh 2>/dev/null || true

  log_info "Permissions configured"
}

create_alias() {
  local install_dir="$1"
  log_step "Creating 'ndc' command alias..."

  ln -sf "$install_dir/nguyendc-ols.sh" /usr/local/bin/ndc
  chmod +x /usr/local/bin/ndc

  # Verify alias works
  if [[ -L /usr/local/bin/ndc ]]; then
    log_info "Alias 'ndc' created successfully"
  else
    log_warn "Alias creation may have failed - checking..."
  fi
}

setup_directories() {
  log_step "Setting up system directories..."

  mkdir -p /etc/nguyendc-ols
  mkdir -p /var/log/nguyendc-ols
  mkdir -p /var/lib/nguyendc-ols
  mkdir -p /opt/nguyendc-ols/backups/apps
  mkdir -p /opt/nguyendc-ols/backups/databases
  mkdir -p /opt/nguyendc-ols/backups/configs

  chmod 750 /etc/nguyendc-ols
  chmod 755 /var/log/nguyendc-ols
  chmod 755 /var/lib/nguyendc-ols

  log_info "System directories created"
}

install_basic_packages() {
  log_step "Installing basic system packages..."

  local packages=(
    build-essential
    curl
    wget
    git
    htop
    nano
    zip
    unzip
  )

  apt-get install -y "${packages[@]}" || log_warn "Some packages failed to install"
  log_info "Basic packages installed"
}

# ============================================================
# POST-INSTALLATION
# ============================================================

print_summary() {
  local install_dir="$1"

  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║                                                                ║"
  echo "║          ✅ nguyendc-ols Installation Complete!               ║"
  echo "║                                                                ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""
  echo "📦 Installation Details:"
  echo "   • Location: $install_dir"
  echo "   • Alias: ndc (available globally)"
  echo "   • Config: /etc/nguyendc-ols"
  echo "   • Logs: /var/log/nguyendc-ols"
  echo ""
  echo "🚀 Quick Start:"
  echo "   1. Run the menu:"
  echo "      ndc"
  echo ""
  echo "   2. Or run specific commands:"
  echo "      ndc wordpress install example.com"
  echo "      ndc nodejs install"
  echo "      ndc postgres install"
  echo ""
  echo "📚 Documentation:"
  echo "   • README: $install_dir/README.md"
  echo "   • Quick Setup: $install_dir/QUICK_SETUP.md"
  echo "   • Audit Report: $install_dir/AUDIT_REPORT.md"
  echo ""
  echo "💡 Tips:"
  echo "   • Type 'ndc' to open the main menu"
  echo "   • Type 'ndc help' for command list (if available)"
  echo "   • Read QUICK_SETUP.md for detailed usage guide"
  echo ""
  echo "🆘 Support:"
  echo "   • Issues: https://github.com/nguyendc-hp/nguyendc-ols/issues"
  echo "   • Email: support@nguyendc-ols.com"
  echo ""
}

# ============================================================
# MAIN INSTALLATION FLOW
# ============================================================

main() {
  clear

  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║                                                                ║"
  echo "║            nguyendc-ols - VPS Management Tool                  ║"
  echo "║                                                                ║"
  echo "║   WordPress · Node.js · Database Management Automation         ║"
  echo "║                                                                ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""

  # Pre-flight checks
  log_step "Running pre-flight checks..."
  check_root
  check_ubuntu
  check_dependencies

  echo ""
  log_step "Starting installation..."
  echo ""

  # Installation
  INSTALL_DIR=$(install_nguyendc_ols) || exit 1
  setup_permissions "$INSTALL_DIR"
  create_alias "$INSTALL_DIR"
  setup_directories
  install_basic_packages

  echo ""

  # Summary
  print_summary "$INSTALL_DIR"

  log_info "Installation completed successfully!"
}

# ============================================================
# ERROR HANDLING
# ============================================================

trap 'log_error "Installation failed!"; exit 1' ERR

# Run main
main "$@"
