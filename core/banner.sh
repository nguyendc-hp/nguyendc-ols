#!/usr/bin/env bash

# ======================================
# Welcome Banner cho nguyendc-ols
# ======================================

show_welcome_banner() {
  local version
  version=$(cat /opt/nguyendc-ols/VERSION 2>/dev/null || echo "1.0.0")
  
  clear
  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║                                                                ║"
  echo "║              🚀 nguyendc-ols - VPS Management Tool 🚀          ║"
  echo "║                                                                ║"
  echo "║         WordPress + Node.js + Database Management              ║"
  echo "║                     Version: $version                          ║"
  echo "║                                                                ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""
  
  # System info
  local hostname_val ip_addr os_info uptime_val
  hostname_val=$(hostname 2>/dev/null || echo "unknown")
  ip_addr=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "N/A")
  os_info=$(lsb_release -ds 2>/dev/null || cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo "Linux")
  uptime_val=$(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}')
  
  echo "  📍 Server Info:"
  echo "  ├─ Hostname    : $hostname_val"
  echo "  ├─ IP Address  : $ip_addr"
  echo "  ├─ OS          : $os_info"
  echo "  └─ Uptime      : $uptime_val"
  echo ""
  
  # Resource usage
  local cpu_count mem_total mem_used mem_percent disk_usage
  cpu_count=$(nproc 2>/dev/null || echo "N/A")
  mem_total=$(free -h 2>/dev/null | awk '/^Mem:/{print $2}' || echo "N/A")
  mem_used=$(free -h 2>/dev/null | awk '/^Mem:/{print $3}' || echo "N/A")
  mem_percent=$(free 2>/dev/null | awk '/^Mem:/{printf "%.1f%%", $3/$2*100}' || echo "N/A")
  disk_usage=$(df -h / 2>/dev/null | awk 'NR==2{print $5}' || echo "N/A")
  
  echo "  💻 Resources:"
  echo "  ├─ CPU Cores   : $cpu_count"
  echo "  ├─ Memory      : $mem_used / $mem_total ($mem_percent)"
  echo "  └─ Disk (/)    : $disk_usage used"
  echo ""
  
  # Service status
  echo "  🔧 Service Status:"
  local nginx_status node_status mysql_status mongo_status redis_status
  
  if systemctl is-active nginx >/dev/null 2>&1; then
    nginx_status="✅ Running"
  else
    nginx_status="❌ Stopped"
  fi
  
  if command -v node >/dev/null 2>&1; then
    node_status="✅ $(node -v 2>/dev/null)"
  else
    node_status="❌ Not installed"
  fi
  
  if systemctl is-active mysql >/dev/null 2>&1 || systemctl is-active mariadb >/dev/null 2>&1; then
    mysql_status="✅ Running"
  else
    mysql_status="❌ Stopped"
  fi
  
  if systemctl is-active mongod >/dev/null 2>&1; then
    mongo_status="✅ Running"
  else
    mongo_status="❌ Stopped"
  fi
  
  if systemctl is-active redis >/dev/null 2>&1 || systemctl is-active redis-server >/dev/null 2>&1; then
    redis_status="✅ Running"
  else
    redis_status="❌ Stopped"
  fi
  
  echo "  ├─ Nginx       : $nginx_status"
  echo "  ├─ Node.js     : $node_status"
  echo "  ├─ MySQL       : $mysql_status"
  echo "  ├─ MongoDB     : $mongo_status"
  echo "  └─ Redis       : $redis_status"
  echo ""
  
  # Quick commands
  echo "  📌 Quick Commands:"
  echo "  ├─ Open menu   : ndc"
  echo "  ├─ View logs   : sudo tail -f /var/log/nguyendc-ols.log"
  echo "  └─ Check docs  : cat /opt/nguyendc-ols/README.md"
  echo ""
  
  echo "════════════════════════════════════════════════════════════════"
  echo ""
}

# Compact banner cho .bashrc
show_compact_banner() {
  local version
  version=$(cat /opt/nguyendc-ols/VERSION 2>/dev/null || echo "1.0.0")
  
  echo ""
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║   🚀 nguyendc-ols v$version - Type 'ndc' to start        ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""
}
