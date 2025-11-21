#!/usr/bin/env bash

# ============================================================
# Installation Verification Script
# Check if nguyendc-ols is properly installed
# ============================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
PASS=0
FAIL=0

# Functions
check_pass() { echo -e "${GREEN}✓${NC} $1"; ((PASS++)); }
check_fail() { echo -e "${RED}✗${NC} $1"; ((FAIL++)); }
check_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
check_info() { echo -e "${BLUE}ℹ${NC} $1"; }

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║   nguyendc-ols Installation Verification                       ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================
# System Checks
# ============================================================

echo -e "${BLUE}=== SYSTEM CHECKS ===${NC}"

# Check OS
if [[ -f /etc/os-release ]]; then
  source /etc/os-release
  version="${VERSION_ID:-unknown}"
  check_pass "OS detected: $NAME $version"
else
  check_fail "Cannot detect OS"
fi

# Check Bash
if bash -c 'exit 0' 2>/dev/null; then
  bash_version=$(bash --version | head -1)
  check_pass "Bash available: $bash_version"
else
  check_fail "Bash not available"
fi

# Check Root
if [[ $EUID -eq 0 ]]; then
  check_pass "Running as root"
else
  check_warn "Not running as root (some features may be limited)"
fi

echo ""

# ============================================================
# Installation Checks
# ============================================================

echo -e "${BLUE}=== INSTALLATION CHECKS ===${NC}"

# Check ndc command
if command -v ndc &>/dev/null; then
  check_pass "Command 'ndc' found in PATH"
  ndc_path=$(which ndc)
  check_info "Location: $ndc_path"
else
  check_fail "Command 'ndc' not found in PATH"
fi

# Check main script
if [[ -f /opt/nguyendc-ols/nguyendc-ols.sh ]]; then
  check_pass "Main script exists: /opt/nguyendc-ols/nguyendc-ols.sh"
  if [[ -x /opt/nguyendc-ols/nguyendc-ols.sh ]]; then
    check_pass "Main script is executable"
  else
    check_fail "Main script is not executable"
  fi
else
  check_fail "Main script not found at /opt/nguyendc-ols/nguyendc-ols.sh"
fi

# Check core directory
if [[ -d /opt/nguyendc-ols/core ]]; then
  check_pass "Core directory exists"
  core_count=$(ls /opt/nguyendc-ols/core/*.sh 2>/dev/null | wc -l)
  check_info "Core files: $core_count"
else
  check_fail "Core directory not found"
fi

# Check plugins directory
if [[ -d /opt/nguyendc-ols/plugins ]]; then
  check_pass "Plugins directory exists"
  plugin_count=$(ls /opt/nguyendc-ols/plugins/*.plugin.sh 2>/dev/null | wc -l)
  if [[ $plugin_count -gt 0 ]]; then
    check_pass "Plugins found: $plugin_count"
  else
    check_warn "No plugins found in directory"
  fi
else
  check_fail "Plugins directory not found"
fi

# Check config directory
if [[ -d /etc/nguyendc-ols ]]; then
  check_pass "Config directory exists: /etc/nguyendc-ols"
else
  check_warn "Config directory not found (will be created on first run)"
fi

# Check logs directory
if [[ -d /var/log/nguyendc-ols ]]; then
  check_pass "Logs directory exists: /var/log/nguyendc-ols"
else
  check_warn "Logs directory not found (will be created on first run)"
fi

echo ""

# ============================================================
# File Checks
# ============================================================

echo -e "${BLUE}=== DOCUMENTATION CHECKS ===${NC}"

# Check README
if [[ -f /opt/nguyendc-ols/README.md ]]; then
  check_pass "README.md exists"
else
  check_warn "README.md not found"
fi

# Check QUICK_SETUP
if [[ -f /opt/nguyendc-ols/QUICK_SETUP.md ]]; then
  check_pass "QUICK_SETUP.md exists"
else
  check_warn "QUICK_SETUP.md not found"
fi

# Check INSTALLATION
if [[ -f /opt/nguyendc-ols/INSTALLATION.md ]]; then
  check_pass "INSTALLATION.md exists"
else
  check_warn "INSTALLATION.md not found"
fi

echo ""

# ============================================================
# Functionality Checks
# ============================================================

echo -e "${BLUE}=== FUNCTIONALITY CHECKS ===${NC}"

# Try to run ndc (basic test)
if command -v ndc &>/dev/null; then
  if ndc 2>&1 | grep -q "nguyendc-ols" 2>/dev/null; then
    check_pass "ndc command responds"
  else
    check_warn "ndc command found but may not be responding correctly"
  fi
fi

echo ""

# ============================================================
# Summary
# ============================================================

echo -e "${BLUE}=== VERIFICATION SUMMARY ===${NC}"
echo ""
echo -e "Passed: ${GREEN}$PASS${NC}"
echo -e "Failed: ${RED}$FAIL${NC}"
echo ""

if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}✓ Installation verification PASSED${NC}"
  echo ""
  echo "Your nguyendc-ols installation is ready to use!"
  echo ""
  echo "Get started:"
  echo "  ndc                           # Open main menu"
  echo "  ndc wordpress install domain  # Install WordPress"
  echo "  ndc nodejs install            # Install Node.js"
  echo ""
  exit 0
else
  echo -e "${RED}✗ Installation verification FAILED${NC}"
  echo ""
  echo "Please fix the issues above. If you need help:"
  echo "  • Read: /opt/nguyendc-ols/INSTALLATION.md"
  echo "  • Read: /opt/nguyendc-ols/QUICK_SETUP.md"
  echo "  • Reinstall: git clone ... && sudo bash install.sh"
  echo ""
  exit 1
fi
