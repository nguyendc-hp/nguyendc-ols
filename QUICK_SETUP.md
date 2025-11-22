# nguyendc-ols - Quick Setup & Usage Guide

**Version:** 1.0.0  
**Status:** Production Ready  
**Last Updated:** November 2025

---

## 🚀 Cài đặt mới (Fresh Install)

### Bước 1: Clone repository
```bash
cd ~
git clone https://github.com/nguyendc-hp/nguyendc-ols.git
cd nguyendc-ols
```

### Bước 2: Chạy installer
```bash
sudo bash install.sh
```

Installer sẽ tự động:
- ✅ Kiểm tra phiên bản Ubuntu (20.04/22.04/24.04)
- ✅ Cài đặt dependencies (bash, curl, wget, git)
- ✅ Tạo thư mục `/opt/nguyendc-ols`
- ✅ Copy toàn bộ code vào `/opt/nguyendc-ols`
- ✅ Tạo lệnh `ndc` toàn cục
- ✅ Phân quyền thực thi
- ✅ Tạo thư mục config `/etc/nguyendc-ols`
- ✅ Tạo thư mục log `/var/log/nguyendc-ols`

### Bước 3: Kiểm tra cài đặt
```bash
which ndc
# Output: /usr/local/bin/ndc

ndc
# Hiển thị menu chính với 14 categories
```

---

## 🔄 Update trên VPS đang có nguyendc-ols

### Cách 1: Update nhanh (giữ nguyên config)
```bash
cd /opt/nguyendc-ols
sudo git pull origin main
sudo chmod +x /opt/nguyendc-ols/nguyendc-ols.sh
ndc
```

### Cách 2: Update toàn bộ (backup + reinstall)
```bash
# Backup cấu hình cũ
sudo cp -r /etc/nguyendc-ols /root/nguyendc-ols-config-backup
sudo cp -r /opt/nguyendc-ols /root/nguyendc-ols-backup

# Pull code mới
cd /opt/nguyendc-ols
sudo git pull origin main

# Restore config nếu cần
sudo cp -r /root/nguyendc-ols-config-backup/* /etc/nguyendc-ols/

# Kiểm tra
ndc
```

### Cách 3: Cài lại hoàn toàn từ đầu
```bash
# Xóa phiên bản cũ
sudo rm -rf /opt/nguyendc-ols
sudo rm -f /usr/local/bin/ndc

# Backup config (nếu muốn giữ lại)
sudo cp -r /etc/nguyendc-ols /root/nguyendc-ols-config-backup

# Cài mới
cd ~
rm -rf nguyendc-ols
git clone https://github.com/nguyendc-hp/nguyendc-ols.git
cd nguyendc-ols
sudo bash install.sh

# Restore config cũ (optional)
sudo cp -r /root/nguyendc-ols-config-backup/* /etc/nguyendc-ols/
```

---

## 🆕 Reset VPS hoàn toàn (VPS trắng)

### Khi nào cần reset?
- VPS mới toanh chưa cài gì
- Muốn xóa hết cài lại từ đầu
- Gặp lỗi nghiêm trọng không fix được

### Bước reset hoàn toàn:

#### 1. Xóa hết dữ liệu cũ (nếu có)
```bash
# Xóa code
sudo rm -rf /opt/nguyendc-ols
sudo rm -f /usr/local/bin/ndc

# Xóa config (CẨNTHẬN: mất hết cấu hình)
sudo rm -rf /etc/nguyendc-ols

# Xóa logs
sudo rm -rf /var/log/nguyendc-ols

# Xóa source code cũ
cd ~
rm -rf nguyendc-ols
```

#### 2. Update hệ thống
```bash
sudo apt-get update
sudo apt-get upgrade -y
```

#### 3. Cài đặt lại nguyendc-ols
```bash
cd ~
git clone https://github.com/nguyendc-hp/nguyendc-ols.git
cd nguyendc-ols
sudo bash install.sh
```

#### 4. Kiểm tra
```bash
ndc
```

---

## 📦 Cài đặt bằng tay (Manual Install)

Nếu `install.sh` gặp lỗi, làm thủ công:

```bash
# Clone code
cd ~
git clone https://github.com/nguyendc-hp/nguyendc-ols.git
cd nguyendc-ols

# Tạo thư mục
sudo mkdir -p /opt/nguyendc-ols
sudo mkdir -p /etc/nguyendc-ols
sudo mkdir -p /var/log/nguyendc-ols

# Copy code
sudo cp -r ./* /opt/nguyendc-ols/

# Phân quyền
sudo chmod +x /opt/nguyendc-ols/nguyendc-ols.sh
sudo chmod +x /opt/nguyendc-ols/modules/*.sh
sudo chmod +x /opt/nguyendc-ols/plugins/*.sh

# Tạo lệnh ndc toàn cục
sudo ln -sf /opt/nguyendc-ols/nguyendc-ols.sh /usr/local/bin/ndc

# Kiểm tra
which ndc
ndc
```

---

## 🎯 Sử dụng cơ bản

### Mở menu chính
```bash
ndc
```

Menu hiển thị 14 categories:
```
╔════════════════════════════════════════════════════════════════╗
║              nguyendc-ols - VPS Management Tool                ║
║         WordPress + Node.js + Database Management              ║
╚════════════════════════════════════════════════════════════════╝

MENU CHÍNH:
──────────────────────────────────────────────────────
 1. SETUP               │  8. MONITORING
 2. DOMAIN_SSL          │  9. OPS_DASHBOARD
 3. WORDPRESS           │ 10. PROJECT_BACKUP
 4. WP_OPTIMIZE         │ 11. SYSTEM_BACKUP
 5. NODE                │ 12. SECURITY
 6. DATABASE            │ 13. SYSINFO
 7. DB_GUI              │ 14. UTILITIES
──────────────────────────────────────────────────────
 0. Exit

Choose:
```

### Category SETUP (Cài đặt hệ thống cơ bản)
```bash
ndc  # Chọn 1
```
Gồm:
- Install Nginx + PHP-FPM
- Install Node.js + PM2
- Install Docker
- Setup Wizard (cài stack tự động)

### Category DOMAIN_SSL (Quản lý domain & SSL)
```bash
ndc  # Chọn 2
```
Gồm:
- Tạo/xóa Nginx VHost
- Certbot SSL (Let's Encrypt)
- Quản lý SSL certificates

### Category WORDPRESS (Quản lý WordPress)
```bash
ndc  # Chọn 3
```
Gồm:
- Cài đặt WordPress mới
- Clone/Migrate WordPress
- Quản lý WordPress sites

### Category WP_OPTIMIZE (Tối ưu WordPress)
```bash
ndc  # Chọn 4
```
Gồm:
- Backup WordPress (files + DB)
- Security Firewall (hardening + fail2ban)
- SpeedPack (cache + Redis + tối ưu)

### Category NODE (Node.js Apps)
```bash
ndc  # Chọn 5
```
Gồm:
- Deploy Node.js apps
- PM2 management
- Git auto-deploy
- Blue-Green deployment
- Health monitoring
- Logs tracking

### Category DATABASE (Quản lý Database)
```bash
ndc  # Chọn 6
```
Sub-menus:
- MariaDB/MySQL
- PostgreSQL
- MongoDB
- Redis

### Category DB_GUI (GUI cho Database)
```bash
ndc  # Chọn 7
```
Gồm:
- phpMyAdmin (MySQL)
- pgAdmin (PostgreSQL)
- SSH Tunnel helper
- DB GUI profiles

### Category MONITORING (Giám sát)
```bash
ndc  # Chọn 8
```
Gồm:
- Health check services
- HTTP endpoint check
- Process watch (auto-restart)
- Telegram notify
- Logwatch
- Netdata

### Category PROJECT_BACKUP (Backup dự án)
```bash
ndc  # Chọn 10
```
Gồm:
- Backup local projects
- Schedule backups
- Restore backups

### Category SYSTEM_BACKUP (Backup hệ thống)
```bash
ndc  # Chọn 11
```
Gồm:
- Rclone + Google Drive
- System snapshots

### Category SECURITY (Bảo mật)
```bash
ndc  # Chọn 12
```
Gồm:
- UFW Firewall
- Fail2ban (chống brute-force)
- Security audit

### Category SYSINFO (Thông tin hệ thống)
```bash
ndc  # Chọn 13
```
Gồm:
- System info
- Resource usage
- Unattended-upgrades control

### Category UTILITIES (Tiện ích)
```bash
ndc  # Chọn 14
```
Gồm:
- Cron Manager
- SSH Helper (tunnels)
- File Manager

---

## 🔧 Cấu hình & thư mục

### Thư mục config
```bash
/etc/nguyendc-ols/
├── state.env           # Persistent state (key=value)
└── [configs khác]
```

### Thư mục cài đặt chính
```bash
/opt/nguyendc-ols/
├── nguyendc-ols.sh     # Main script
├── core/               # Core functions
├── modules/            # Core modules
├── plugins/            # 48 plugins (14 categories)
├── templates/          # Config templates
└── utils/              # Utilities
```

### Thư mục logs
```bash
/var/log/nguyendc-ols/
└── nguyendc-ols.log
```

### Xem trạng thái hiện tại
```bash
sudo cat /etc/nguyendc-ols/state.env
```

---

## ✅ Yêu cầu hệ thống

### Ubuntu Versions
- ✅ Ubuntu 20.04 LTS
- ✅ Ubuntu 22.04 LTS
- ✅ Ubuntu 24.04 LTS

### Resources tối thiểu
- **CPU:** 1 core
- **RAM:** 1 GB (khuyến nghị 2 GB)
- **Disk:** 2 GB free space
- **Network:** Kết nối Internet

### Dependencies tự động cài
```bash
# install.sh sẽ tự động cài:
apt-get install -y bash curl wget git
```

---

## 🐛 Xử lý lỗi thường gặp

### Lỗi 1: "install.sh: No such file or directory"
**Nguyên nhân:** Chưa vào đúng thư mục

**Giải pháp:**
```bash
# Kiểm tra bạn đang ở đâu
pwd
ls -la install.sh

# Phải ở trong: ~/nguyendc-ols

# Chạy lại
sudo bash install.sh
```

### Lỗi 2: Permission Denied khi chạy 'ndc'
**Lỗi:** `bash: /usr/local/bin/ndc: Permission denied`

**Giải pháp:**
```bash
# Fix phân quyền
sudo chmod +x /opt/nguyendc-ols/nguyendc-ols.sh
sudo chmod +x /usr/local/bin/ndc

# Test
which ndc
ndc
```

### Lỗi 3: "command not found: ndc"
**Nguyên nhân:** Chưa tạo symlink

**Giải pháp:**
```bash
# Tạo symlink thủ công
sudo ln -sf /opt/nguyendc-ols/nguyendc-ols.sh /usr/local/bin/ndc

# Kiểm tra
ls -la /usr/local/bin/ndc

# Reload shell
exec bash
ndc
```

### Lỗi 4: Plugin Directory Not Found
**Lỗi:** "Không tìm thấy thư mục plugins"

**Giải pháp:**
```bash
# Kiểm tra plugins
ls -la /opt/nguyendc-ols/plugins/

# Nếu rỗng, cài lại
cd ~/nguyendc-ols
sudo bash install.sh
```

### Lỗi 5: APT Lock (Held by unattended-upgrades)
**Lỗi:** "E: Could not get lock /var/lib/apt/lists/lock"

**Giải pháp:**
```bash
# Tắt unattended-upgrades tạm thời
sudo systemctl stop unattended-upgrades
sudo rm -f /var/lib/apt/lists/lock
sudo apt-get update
```

### Lỗi 6: Git pull failed
**Lỗi:** "error: Your local changes to the following files would be overwritten"

**Giải pháp:**
```bash
cd /opt/nguyendc-ols

# Backup changes
sudo git stash

# Pull mới
sudo git pull origin main

# Apply changes lại (optional)
sudo git stash pop
```

---

## ✅ Checklist sau khi cài đặt

```bash
# 1. Kiểm tra lệnh ndc
which ndc
# Output: /usr/local/bin/ndc

# 2. Kiểm tra thư mục cài đặt
ls -la /opt/nguyendc-ols/
# Phải có: nguyendc-ols.sh, plugins/, core/, modules/

# 3. Kiểm tra config
sudo ls -la /etc/nguyendc-ols/

# 4. Kiểm tra logs
sudo ls -la /var/log/nguyendc-ols/

# 5. Chạy ndc
ndc
# Hiển thị menu với 14 categories

# 6. Đếm số plugins
ls -1 /opt/nguyendc-ols/plugins/*.plugin.sh | wc -l
# Output: 48
```

---

## 📊 Xem logs

### Log chính
```bash
# Xem real-time
sudo tail -f /var/log/nguyendc-ols.log

# Xem toàn bộ
sudo cat /var/log/nguyendc-ols.log

# Xóa logs
sudo truncate -s 0 /var/log/nguyendc-ols.log
```

### Debug mode
```bash
NGUYENDC_OLS_DEBUG=1 ndc
```

---

## 🎓 Best Practices

### 1. Backup config trước khi update
```bash
sudo cp -r /etc/nguyendc-ols /root/backup-config-$(date +%Y%m%d)
```

### 2. Test trên VPS trắng trước
```bash
# Tạo snapshot VPS trước khi cài
# Hoặc test trên VPS test riêng
```

### 3. Update thường xuyên
```bash
# Mỗi tuần check update
cd /opt/nguyendc-ols
sudo git fetch
sudo git status
```

### 4. Giữ logs sạch sẽ
```bash
# Xóa logs cũ hàng tháng
sudo find /var/log/nguyendc-ols/ -type f -mtime +30 -delete
```

---

## 🚀 Các bước tiếp theo

### 1. Cài stack cơ bản
```bash
ndc
# Chọn 1. SETUP → Setup Wizard
# Sẽ tự động cài: Nginx + Node.js + MariaDB + Redis
```

### 2. Setup WordPress đầu tiên
```bash
ndc
# Chọn 3. WORDPRESS → Install WordPress
# Nhập domain: example.com
```

### 3. Cài SSL
```bash
ndc
# Chọn 2. DOMAIN_SSL → Certbot SSL
# Nhập domain: example.com
```

### 4. Bật firewall
```bash
ndc
# Chọn 12. SECURITY → UFW Firewall → Install
```

### 5. Setup backup tự động
```bash
ndc
# Chọn 10. PROJECT_BACKUP → Schedule Backups
```

### 6. Cài monitoring
```bash
ndc
# Chọn 8. MONITORING → Netdata
```

---

## 📞 Hỗ trợ

### Documentation
- **README.md** - Full documentation
- **QUICKSTART.md** - Quick reference
- **MENU_STRUCTURE.MD** - Menu structure
- **docs/** - Chi tiết từng module

### GitHub
- **Issues:** [Báo lỗi](https://github.com/nguyendc-hp/nguyendc-ols/issues)
- **Discussions:** [Thảo luận](https://github.com/nguyendc-hp/nguyendc-ols/discussions)

---

## 📝 Tóm tắt

**nguyendc-ols** - công cụ quản lý VPS hoàn chỉnh:
- ✅ 48 plugins - 14 categories
- ✅ Menu đơn giản, dễ sử dụng
- ✅ Tự động hóa backup & monitoring
- ✅ Miễn phí, open-source
- ✅ Production-ready

**Bắt đầu ngay:**
```bash
cd ~
git clone https://github.com/nguyendc-hp/nguyendc-ols.git
cd nguyendc-ols
sudo bash install.sh
ndc
```

---

**Made with ❤️ by nguyendc-hp**

GitHub: https://github.com/nguyendc-hp/nguyendc-ols
