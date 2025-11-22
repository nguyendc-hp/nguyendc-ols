#!/usr/bin/env bash

# Update plugin categories theo cấu trúc mới

cd "$(dirname "$0")/plugins"

# SETUP category
sed -i 's/"SYSTEM"/"SETUP"/; s/"Cài đặt.*"/""/4' nginx.plugin.sh 2>/dev/null || true
sed -i 's/"SYSTEM"/"SETUP"/; s/"Cài đặt.*"/""/4' php.plugin.sh 2>/dev/null || true  
sed -i 's/"NODE"/"SETUP"/; s/"Cài đặt.*"/""/4' nodejs.plugin.sh 2>/dev/null || true
sed -i 's/"SYSTEM"/"SETUP"/; s/"Cài đặt.*"/""/4' docker.plugin.sh 2>/dev/null || true
sed -i 's/"SYSTEM"/"SETUP"/; s/"Cài.*"/""/4' preset-basic-stack.plugin.sh 2>/dev/null || true
sed -i 's/"SYSTEM"/"SETUP"/; s/"Wizard.*"/""/4' setup-wizard.plugin.sh 2>/dev/null || true

# DOMAIN_SSL
sed -i 's/"SYSTEM"/"DOMAIN_SSL"/; s/"Cài đặt.*"/""/4' certbot.plugin.sh 2>/dev/null || true
sed -i 's/"SYSTEM"/"DOMAIN_SSL"/; s/"Quản lý.*"/""/4' vhost-nginx.plugin.sh 2>/dev/null || true

# WORDPRESS (giữ nguyên)

# WP_OPTIMIZE
sed -i 's/"WORDPRESS"/"WP_OPTIMIZE"/; s/"Tối ưu.*"/""/4' wordpress-speed.plugin.sh 2>/dev/null || true
sed -i 's/"WORDPRESS"/"WP_OPTIMIZE"/; s/"Hardening.*"/""/4' wordpress-security.plugin.sh 2>/dev/null || true
sed -i 's/"WORDPRESS"/"WP_OPTIMIZE"/; s/"Backup.*"/""/4' wordpress-backup.plugin.sh 2>/dev/null || true

# NODE (giữ nguyên category, chỉ xóa description)
for f in app-deploy-node node-app-manager node-project node-env node-pm2-manager node-logs node-bluegreen node-git-deploy node-health node-alert; do
  sed -i 's/\("NODE".*\\\)$/\1/; s/"Triển khai.*"/""/4; s/"Tạo &.*"/""/4; s/"Quản lý.*"/""/4; s/"Giám sát.*"/""/4' ${f}.plugin.sh 2>/dev/null || true
done

# DATABASE
sed -i 's/"DB"/"DATABASE"/; s/"Cài đặt.*"/""/4' mariadb.plugin.sh 2>/dev/null || true
sed -i 's/"DB"/"DATABASE"/; s/"Cài đặt.*"/""/4' mongo.plugin.sh 2>/dev/null || true
sed -i 's/"DB"/"DATABASE"/; s/"Cài đặt.*"/""/4' postgres.plugin.sh 2>/dev/null || true
sed -i 's/"DB"/"DATABASE"/; s/"Cài đặt.*"/""/4' redis.plugin.sh 2>/dev/null || true

# DB_GUI
sed -i 's/"DB"/"DB_GUI"/; s/"Sinh cấu.*"/""/4' db-gui-profiles.plugin.sh 2>/dev/null || true
sed -i 's/"DB"/"DB_GUI"/; s/"Cài đặt.*"/""/4' phpmyadmin.plugin.sh 2>/dev/null || true
sed -i 's/"DB"/"DB_GUI"/; s/"Cài đặt.*"/""/4' pgadmin.plugin.sh 2>/dev/null || true

# MONITORING  
sed -i 's/"OPS"/"MONITORING"/; s/"Kiểm tra.*"/""/4' healthcheck.plugin.sh 2>/dev/null || true
sed -i 's/"OPS"/"MONITORING"/; s/"Kiểm tra.*"/""/4' httpcheck.plugin.sh 2>/dev/null || true
sed -i 's/"OPS"/"MONITORING"/; s/"Theo dõi.*"/""/4' processwatch.plugin.sh 2>/dev/null || true
sed -i 's/"OPS"/"MONITORING"/; s/"Xem nhanh.*"/""/4' logwatch.plugin.sh 2>/dev/null || true
sed -i 's/"OPS"/"MONITORING"/; s/"Cài đặt.*"/""/4' netdata.plugin.sh 2>/dev/null || true
sed -i 's/"OPS"/"MONITORING"/; s/"Gửi.*"/""/4' telegram.plugin.sh 2>/dev/null || true

# PROJECT_BACKUP
sed -i 's/"OPS"/"PROJECT_BACKUP"/; s/"Backup.*"/""/4' backup.plugin.sh 2>/dev/null || true

# SYSTEM_BACKUP  
sed -i 's/"OPS"/"SYSTEM_BACKUP"/; s/"Backup.*"/""/4' rclone-gdrive.plugin.sh 2>/dev/null || true

# SECURITY
sed -i 's/"SYSTEM"/"SECURITY"/; s/"Cài đặt.*"/""/4' fail2ban.plugin.sh 2>/dev/null || true
sed -i 's/"SYSTEM"/"SECURITY"/; s/"Quản lý.*"/""/4' ufw.plugin.sh 2>/dev/null || true

# SYSINFO (đã update)

# UTILITIES
sed -i 's/"SYSTEM"/"UTILITIES"/; s/"Quản lý.*"/""/4' cron.plugin.sh 2>/dev/null || true
sed -i 's/"SYSTEM"/"UTILITIES"/; s/"Tạo.*"/""/4' ssh-helper.plugin.sh 2>/dev/null || true

echo "✓ Done updating plugin categories!"
