# nguyendc-ols - Quick Setup & Usage Guide

**Version:** 1.0.0  
**Status:** Production Ready  
**Last Updated:** 2024

---

## 🚀 Installation (Choose One)

### Option 1: Automated Install (Recommended)
```bash
git clone https://github.com/nguyendc-hp/nguyendc-ols.git
cd nguyendc-ols
sudo bash install.sh
```

The installer will:
- ✅ Verify Ubuntu version (20.04/22.04/24.04)
- ✅ Install dependencies
- ✅ Setup directories
- ✅ Create 'ndc' alias
- ✅ Configure permissions
- ✅ Display quick start guide

### Option 2: Manual Setup (Advanced)
```bash
git clone https://github.com/nguyendc-hp/nguyendc-ols.git
cd nguyendc-ols

# Setup manually
sudo mkdir -p /opt/nguyendc-ols
sudo cp -r ./* /opt/nguyendc-ols/
sudo chmod +x /opt/nguyendc-ols/nguyendc-ols.sh
sudo ln -sf /opt/nguyendc-ols/nguyendc-ols.sh /usr/local/bin/ndc

# Verify
which ndc
ndc
```

---

## ✅ System Requirements

### Ubuntu Versions
- ✅ Ubuntu 20.04 LTS
- ✅ Ubuntu 22.04 LTS
- ✅ Ubuntu 24.04 LTS

### Minimum Resources
- **CPU:** 1 core
- **RAM:** 1 GB (2 GB recommended)
- **Disk:** 2 GB free space
- **Network:** Internet connection for downloads

### Prerequisites
```bash
# These are usually pre-installed on Ubuntu
apt-get update
apt-get install -y bash curl wget git
```

---

## 🎯 Basic Usage

### Open the Main Menu
```bash
ndc
```

You'll see:
```
╔════════════════════════════════════════════════════════════════╗
║              nguyendc-ols - VPS Management Tool                ║
║         WordPress + Node.js + Database Management              ║
╚════════════════════════════════════════════════════════════════╝

1. WordPress tools
2. Node.js tools
3. Database tools
4. Ops & Monitoring
5. System & Security
0. Exit

Choose:
```

### WordPress Operations
```bash
# Interactive menu
ndc
# Then select option 1

# Direct commands
ndc wordpress install example.com
ndc wordpress ssl example.com
ndc wordpress backup example.com
ndc wordpress security example.com
ndc wordpress speed example.com
ndc wordpress cache enable example.com
```

### Node.js Operations
```bash
# Interactive
ndc
# Then select option 2

# Direct commands
ndc nodejs install
ndc nodejs app deploy /path/to/app
ndc nodejs app restart myapp
ndc nodejs app logs myapp
ndc nodejs pm2 status
```

### Database Operations
```bash
# PostgreSQL
ndc postgres install
ndc postgres backup mydb
ndc postgres restore mydb backup.sql

# MySQL/MariaDB
ndc mysql install
ndc mysql backup mydb
ndc mysql optimize mydb

# MongoDB
ndc mongo install
ndc mongo backup mydb
ndc mongo restore mydb

# Redis
ndc redis install
ndc redis benchmark
```

### Security Operations
```bash
# Firewall
ndc ufw install
ndc ufw status
ndc ufw allow 80
ndc ufw allow 443

# Brute-force protection
ndc fail2ban install
ndc fail2ban status

# SSL Certificates
ndc certbot install
ndc certbot ssl example.com
ndc certbot renew

# SSH Hardening
ndc ssh-helper secure
```

### Backup Operations
```bash
ndc backup install
ndc backup schedule
ndc backup local status
ndc backup cloud gdrive
ndc backup verify
ndc backup restore
```

### System & Monitoring
```bash
# System Info
ndc sysinfo
ndc sysinfo details

# Monitoring
ndc netdata install
ndc monitor install
ndc monitor dashboard

# Health Checks
ndc healthcheck run
ndc healthcheck schedule
```

---

## 📋 Common Command Reference

### WordPress
| Command | Description |
|---------|-------------|
| `ndc wordpress install domain.com` | Install new WordPress |
| `ndc wordpress ssl domain.com` | Setup SSL certificate |
| `ndc wordpress backup domain.com` | Create backup |
| `ndc wordpress cache enable domain.com` | Enable Redis cache |
| `ndc wordpress security domain.com` | Security hardening |

### Node.js
| Command | Description |
|---------|-------------|
| `ndc nodejs install` | Install Node.js + PM2 |
| `ndc nodejs app deploy /path` | Deploy app |
| `ndc nodejs app restart name` | Restart app |
| `ndc nodejs app logs name` | View logs |
| `ndc nodejs pm2 status` | Check PM2 status |

### Databases
| Command | Description |
|---------|-------------|
| `ndc postgres install` | Install PostgreSQL |
| `ndc mysql install` | Install MySQL/MariaDB |
| `ndc mongo install` | Install MongoDB |
| `ndc redis install` | Install Redis |

### Security
| Command | Description |
|---------|-------------|
| `ndc ufw install` | Setup firewall |
| `ndc fail2ban install` | Setup brute-force protection |
| `ndc certbot install` | Setup SSL automation |

---

## 🔧 Configuration

### Config Location
```bash
/etc/nguyendc-ols/
├── state.env           # Persistent state (key=value)
└── [other configs]
```

### View Current State
```bash
sudo cat /etc/nguyendc-ols/state.env
```

### Set Configuration
State is managed automatically. Manual editing rarely needed:
```bash
sudo vi /etc/nguyendc-ols/state.env
```

---

## 🐛 Installation & Usage Troubleshooting

### Issue 1: "install.sh: No such file or directory"
**Cause:** You're in the wrong directory or not in the cloned repo

**Solution:**
```bash
# Make sure you're in the cloned nguyendc-ols directory
pwd
ls -la install.sh

# Should be in: /root/nguyendc-ols or ~/nguyendc-ols

# Then run it
sudo bash install.sh
```

### Issue 2: Permission Denied when running 'ndc'
**Error:** `bash: /usr/local/bin/ndc: Permission denied`

**Solution:**
```bash
# Fix: Make script executable
sudo chmod +x /opt/nguyendc-ols/nguyendc-ols.sh
sudo chmod +x /usr/local/bin/ndc

# Test
which ndc
ndc
```

### Issue 3: "command not found: ndc"
**Cause:** Alias not created or shell not reloaded

**Solution:**
```bash
# Create the alias manually
sudo ln -sf /opt/nguyendc-ols/nguyendc-ols.sh /usr/local/bin/ndc

# Verify it exists
ls -la /usr/local/bin/ndc

# Reload shell or run directly
/usr/local/bin/ndc

# Or reload your shell
exec bash
ndc
```

### Issue 4: Plugin Directory Not Found
**Error:** "Không tìm thấy thư mục plugins"

**Solution:**
```bash
# Check if plugins exist
ls -la /opt/nguyendc-ols/plugins/

# If empty, files weren't copied
# Reinstall from the correct directory
cd ~/nguyendc-ols
sudo bash install.sh
```

### Issue 5: "no such file or directory" when running ndc
**Cause:** Script installed in wrong location

**Solution:**
```bash
# Check where ndc points to
ls -la /usr/local/bin/ndc

# Should point to: /opt/nguyendc-ols/nguyendc-ols.sh
# Verify the target exists
ls -la /opt/nguyendc-ols/nguyendc-ols.sh

# If not, reinstall:
sudo mkdir -p /opt/nguyendc-ols
sudo cp -r ~/nguyendc-ols/* /opt/nguyendc-ols/
sudo ln -sf /opt/nguyendc-ols/nguyendc-ols.sh /usr/local/bin/ndc
sudo chmod +x /opt/nguyendc-ols/nguyendc-ols.sh
```

### Issue 6: APT Lock (Held by unattended-upgrades)
**Error:** "E: Could not get lock /var/lib/apt/lists/lock"

**Solution:**
```bash
# Script automatically handles this
# If manual intervention needed:
sudo systemctl stop unattended-upgrades
sudo rm -f /var/lib/apt/lists/lock
sudo apt-get update
```

### Issue 7: Permission Issues with WordPress
**After installing WordPress:**

```bash
# Fix WordPress directory permissions
sudo chown -R www-data:www-data /var/www/example.com
sudo chmod -R 755 /var/www/example.com

# Fix wp-content permissions
sudo chmod -R 775 /var/www/example.com/wp-content
```

### Issue 8: SSL Certificate Issues
```bash
# Check certificate status
sudo certbot certificates

# Renew manually
sudo certbot renew

# For specific domain
sudo certbot renew --cert-name example.com
```

---

## ✅ Verification Checklist

After installation, verify everything works:

```bash
# 1. Check ndc command exists
which ndc
# Output: /usr/local/bin/ndc

# 2. Check installation directory
ls -la /opt/nguyendc-ols/
# Should have: nguyendc-ols.sh, plugins/, core/, README.md

# 3. Check config directory
sudo ls -la /etc/nguyendc-ols/
# Should be writable by root

# 4. Check log directory
sudo ls -la /var/log/nguyendc-ols/
# Should exist

# 5. Run ndc without arguments (shows menu)
ndc
# Should display welcome screen and menu

# 6. Check plugin loading
ndc help
# Should list available plugins (if help plugin exists)
```

---

## 📊 Logs & Debugging

### Main Log File
```bash
# View logs
sudo tail -f /var/log/nguyendc-ols.log

# Clear logs
sudo truncate -s 0 /var/log/nguyendc-ols.log
```

### Enable Debug Mode
```bash
NGUYENDC_OLS_DEBUG=1 ndc
```

### Check Plugin Loading
```bash
ndc help
# Lists all loaded plugins
```

---

## 🛠️ Advanced Usage

### Custom Plugin Directory
```bash
# Plugins are auto-loaded from:
/opt/nguyendc-ols/plugins/

# All *.plugin.sh files are loaded automatically
```

### Using CLI Mode (Non-Interactive)
```bash
# CLI mode for scripts
ndc wordpress install example.com
ndc nodejs app deploy /path/to/app
ndc backup schedule

# Run and exit (no menu)
```

### Creating Cron Jobs
```bash
# Backup every day at 2 AM
0 2 * * * /usr/local/bin/ndc backup local status

# Certbot renewal check (typically auto)
0 12 * * * /usr/local/bin/ndc certbot renew

# System health check daily
0 6 * * * /usr/local/bin/ndc healthcheck run
```

---

## 📞 Getting Help

### View Plugin Help
```bash
ndc wordpress
ndc nodejs
ndc postgres
# Then select "Help" option or read on-screen menu
```

### Documentation
- **README.md** - Full project documentation
- **QUICKSTART.md** - Fast reference
- **AUDIT_REPORT.md** - Code quality details
- **docs/TROUBLESHOOTING.md** - Common issues

### Support
- **GitHub Issues:** [Report bugs](https://github.com/nguyendc-hp/nguyendc-ols/issues)
- **Email:** support@nguyendc-ols.com

---

## 🔄 Updating nguyendc-ols

### Check Version
```bash
cat /opt/nguyendc-ols/VERSION
# or
ndc version
```

### Update to Latest
```bash
cd /opt/nguyendc-ols
git pull origin main
sudo systemctl restart nguyendc-ols 2>/dev/null || true
```

### Backup Before Update
```bash
sudo cp -r /opt/nguyendc-ols /opt/nguyendc-ols.backup
```

---

## 🎓 Best Practices

### 1. Regular Backups
```bash
# Setup automated daily backups
ndc backup install
ndc backup schedule

# Verify backup integrity
ndc backup verify
```

### 2. Security Hardening
```bash
# Always enable firewall
ndc ufw install

# Enable fail2ban for protection
ndc fail2ban install

# Setup SSL for all sites
ndc certbot ssl example.com
```

### 3. Monitoring
```bash
# Install monitoring
ndc netdata install
ndc monitor install

# Check system health
ndc healthcheck run
```

### 4. Regular Updates
```bash
# Keep system updated
sudo apt-get update
sudo apt-get upgrade -y

# Update nguyendc-ols
cd /opt/nguyendc-ols
git pull
```

---

## 📈 Performance Tips

### 1. Enable Caching
```bash
# For WordPress
ndc wordpress cache enable example.com

# For Node.js with Redis
ndc redis install
```

### 2. Optimize Databases
```bash
# PostgreSQL optimization
ndc postgres optimize mydb

# MySQL optimization
ndc mysql optimize mydb
```

### 3. Web Server Optimization
```bash
# Nginx optimization
ndc nginx install
ndc nginx config example.com
```

### 4. Monitor Performance
```bash
ndc monitor install
ndc monitor dashboard
```

---

## 🚨 Critical Operations

### Database Backup (IMPORTANT)
```bash
# Always backup before major changes
ndc postgres backup mydb
ndc mysql backup mydb
ndc mongo backup mydb
```

### SSL Renewal Check
```bash
# Check certificate expiration
sudo certbot certificates

# Manual renewal if needed
sudo certbot renew --force-renewal
```

### System Upgrade
```bash
# Backup first!
ndc backup local status

# Then upgrade
sudo apt-get update
sudo apt-get upgrade -y
```

---

## ✨ Tips & Tricks

### Speed Up Commands
```bash
# Create aliases for frequent commands
alias wp='ndc wordpress'
alias node='ndc nodejs'
alias db='ndc postgres'

# Add to ~/.bashrc for permanent aliases
```

### Batch Operations
```bash
# Update all WordPress sites
for domain in $(ls /var/www/); do
  ndc wordpress backup $domain
done
```

### Monitoring Multiple Sites
```bash
# Check all WordPress sites
find /var/www -name "wp-config.php" -type f

# Check all Node apps
ndc nodejs app list
```

---

## 🎯 Next Steps

1. **Install nguyendc-ols** using one of the methods above
2. **Run the setup wizard** - `ndc setup-wizard` (if available)
3. **Configure your first domain** - WordPress or Node.js
4. **Setup backups** - Automate daily backups
5. **Enable monitoring** - Track system health
6. **Harden security** - Firewall, SSL, Fail2ban

---

## 📝 Summary

nguyendc-ols is ready to manage your VPS:
- ✅ 45+ built-in plugins
- ✅ Simple command-line interface
- ✅ Automated backup & monitoring
- ✅ Zero-cost, open-source
- ✅ Production-ready security

**Start managing your VPS today:**
```bash
ndc
```

---

**Made with ❤️ by nguyendc-hp**

For the latest updates and documentation, visit: https://github.com/nguyendc-hp/nguyendc-ols
