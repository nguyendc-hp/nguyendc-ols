# nguyendc-ols Installation Guide

**Version:** 1.0.0  
**Last Updated:** 2024  
**Status:** Production Ready

---

## 📋 Table of Contents

1. [System Requirements](#system-requirements)
2. [Pre-Installation Checks](#pre-installation-checks)
3. [Installation Methods](#installation-methods)
4. [Post-Installation Setup](#post-installation-setup)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)
7. [Uninstallation](#uninstallation)

---

## ✅ System Requirements

### Ubuntu Versions (Required)
- ✅ **Ubuntu 20.04 LTS** (Focal Fossa)
- ✅ **Ubuntu 22.04 LTS** (Jammy Jellyfish)
- ✅ **Ubuntu 24.04 LTS** (Noble Numbat)

**Note:** Other Linux distributions may work but are not officially supported.

### Hardware Requirements (Minimum)
| Resource | Minimum | Recommended |
|----------|---------|------------|
| CPU | 1 core | 2 cores |
| RAM | 1 GB | 2+ GB |
| Disk | 2 GB free | 10+ GB free |
| Network | 100 Mbps | 1 Gbps |

### Software Requirements
- **Bash:** 4.0 or higher (usually pre-installed)
- **Git:** For cloning repository
- **Curl/Wget:** For downloading files
- **Sudo/Root:** Administrative access required

### Network Requirements
- Internet connection for downloading packages
- Access to GitHub (github.com)
- Access to package repositories (apt.ubuntu.com)

---

## 🔍 Pre-Installation Checks

### Check Ubuntu Version
```bash
# View OS information
lsb_release -a
# or
cat /etc/os-release

# Expected output:
# DISTRIB_RELEASE=20.04 (or 22.04/24.04)
```

### Check Bash Version
```bash
bash --version
# Should be: GNU bash, version 4.0 or higher
```

### Check for Required Commands
```bash
which git
which curl
which sudo
# All should return paths to the commands
```

### Check Internet Connectivity
```bash
curl -I https://github.com
# Should get HTTP 200 response
```

### Check Root/Sudo Access
```bash
sudo whoami
# Should output: root
```

### Check Available Disk Space
```bash
df -h /
# Look for "Avail" column - should have at least 2GB
```

---

## 🚀 Installation Methods

### Method 1: Automated Installation (Recommended)

#### Step 1: Clone Repository
```bash
git clone https://github.com/nguyendc-hp/nguyendc-ols.git
cd nguyendc-ols
```

#### Step 2: Run Installer
```bash
sudo bash install.sh
```

#### Step 3: Follow On-Screen Prompts
The installer will:
- ✅ Verify system compatibility
- ✅ Install dependencies
- ✅ Create installation directory
- ✅ Setup system directories
- ✅ Create 'ndc' command alias
- ✅ Configure permissions
- ✅ Display summary and next steps

**Expected Duration:** 2-5 minutes

#### Step 4: Verify Installation
```bash
which ndc
ndc
```

---

### Method 2: Manual Installation (Advanced)

#### Step 1: Clone Repository
```bash
git clone https://github.com/nguyendc-hp/nguyendc-ols.git
cd nguyendc-ols
```

#### Step 2: Create Installation Directory
```bash
sudo mkdir -p /opt/nguyendc-ols
```

#### Step 3: Copy Files
```bash
sudo cp -r ./* /opt/nguyendc-ols/
```

#### Step 4: Set Permissions
```bash
sudo chmod +x /opt/nguyendc-ols/nguyendc-ols.sh
sudo chmod +x /opt/nguyendc-ols/core/*.sh 2>/dev/null || true
sudo chmod +x /opt/nguyendc-ols/plugins/*.sh 2>/dev/null || true
```

#### Step 5: Create Alias
```bash
sudo ln -sf /opt/nguyendc-ols/nguyendc-ols.sh /usr/local/bin/ndc
```

#### Step 6: Create System Directories
```bash
sudo mkdir -p /etc/nguyendc-ols
sudo mkdir -p /var/log/nguyendc-ols
sudo mkdir -p /var/lib/nguyendc-ols
sudo chmod 750 /etc/nguyendc-ols
```

#### Step 7: Verify
```bash
which ndc
ndc
```

---

### Method 3: From Existing Clone Directory

If you already have nguyendc-ols cloned:

```bash
cd ~/nguyendc-ols      # Your existing directory
sudo bash install.sh

# or manually:
sudo bash install.sh   # This will handle the rest
```

---

## 📦 Post-Installation Setup

### 1. System Updates
```bash
# Update package lists
sudo apt-get update

# Upgrade system (optional but recommended)
sudo apt-get upgrade -y
```

### 2. Install Optional Dependencies
```bash
# For better functionality, install these:
sudo apt-get install -y \
  curl wget git \
  build-essential \
  python3 python3-pip \
  htop nano
```

### 3. Configure Firewall (Recommended)
```bash
# Open necessary ports
sudo ndc ufw install    # If available
# or manually:
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
```

### 4. Setup Backups
```bash
# Create backup directory
sudo mkdir -p /opt/nguyendc-ols/backups
sudo chmod 755 /opt/nguyendc-ols/backups

# Setup backup policy (use ndc)
ndc backup install
ndc backup schedule
```

### 5. Configure Monitoring (Optional)
```bash
# Install monitoring tools
ndc netdata install
ndc healthcheck run
```

---

## ✅ Verification

### Verify Installation Completeness

```bash
# 1. Check ndc command
which ndc
# Output: /usr/local/bin/ndc ✓

# 2. Check main script
ls -la /opt/nguyendc-ols/nguyendc-ols.sh
# Should exist and be executable ✓

# 3. Check plugins directory
ls /opt/nguyendc-ols/plugins/ | wc -l
# Should show 45 plugins ✓

# 4. Check core directory
ls /opt/nguyendc-ols/core/
# Should have: log.sh, plugins.sh, state.sh, os.sh ✓

# 5. Check config directory
sudo ls -la /etc/nguyendc-ols/
# Should exist ✓

# 6. Check logs directory
sudo ls -la /var/log/nguyendc-ols/
# Should exist ✓

# 7. Test main menu
ndc
# Should display welcome and main menu ✓

# 8. Check permissions
sudo ls -la /opt/nguyendc-ols/nguyendc-ols.sh
# Should be executable (rwxr-xr-x) ✓
```

### Quick Functionality Test

```bash
# Test plugin loading
ndc help 2>/dev/null || echo "Help plugin not available"

# Test system info
ndc sysinfo 2>/dev/null || echo "Sysinfo plugin not available"

# Test WordPress plugin exists
ndc wordpress 2>/dev/null || echo "WordPress plugin check"

# Test Node.js plugin exists
ndc nodejs 2>/dev/null || echo "Node.js plugin check"
```

---

## 🐛 Troubleshooting

### Installation Failed - Unknown Error

**Check:**
```bash
# 1. Review error messages carefully
# 2. Check Ubuntu version
lsb_release -a

# 3. Check Bash version
bash --version

# 4. Check if root/sudo works
sudo whoami

# 5. Try manual installation instead
```

---

### "Permission Denied" When Running install.sh

**Fix:**
```bash
# Make sure you're using sudo
sudo bash install.sh

# Or manually fix permissions
chmod +x install.sh
sudo bash install.sh
```

---

### "No such file or directory" - install.sh

**Fix:**
```bash
# Make sure you're in the cloned directory
cd ~/nguyendc-ols
pwd
ls install.sh

# Then run it
sudo bash install.sh
```

---

### APT Lock Error During Installation

**Error:** "E: Could not get lock /var/lib/apt/lists/lock"

**Fix:**
```bash
# Wait for any running apt to complete
sudo lsof /var/lib/apt/lists/lock

# Or kill stuck process
sudo killall apt
sudo rm -f /var/lib/apt/lists/lock

# Then retry
sudo bash install.sh
```

---

### "command not found: ndc" After Installation

**Fix:**
```bash
# Verify alias exists
ls -la /usr/local/bin/ndc

# If not, create it:
sudo ln -sf /opt/nguyendc-ols/nguyendc-ols.sh /usr/local/bin/ndc

# Reload shell
exec bash

# Test
which ndc
ndc
```

---

### Plugin Directory Missing or Empty

**Diagnosis:**
```bash
ls -la /opt/nguyendc-ols/plugins/
```

**Fix:**
```bash
# Reinstall from clean clone
rm -rf ~/nguyendc-ols
git clone https://github.com/nguyendc-hp/nguyendc-ols.git
cd nguyendc-ols
sudo bash install.sh
```

---

### "No such file or directory" When Running ndc

**Diagnosis:**
```bash
which ndc
ls -la /usr/local/bin/ndc
ls -la /opt/nguyendc-ols/nguyendc-ols.sh
```

**Fix:**
```bash
# Recreate the installation
sudo mkdir -p /opt/nguyendc-ols
sudo cp -r ~/nguyendc-ols/* /opt/nguyendc-ols/
sudo chmod +x /opt/nguyendc-ols/nguyendc-ols.sh
sudo ln -sf /opt/nguyendc-ols/nguyendc-ols.sh /usr/local/bin/ndc

# Test
ndc
```

---

### Script Error: "CONFIG_DIR not defined"

**Fix:**
```bash
# This should not happen with current version
# If it does, update from GitHub
cd ~/nguyendc-ols
git pull origin main
sudo bash install.sh
```

---

## 🗑️ Uninstallation

### Complete Removal

```bash
# 1. Remove alias
sudo rm -f /usr/local/bin/ndc

# 2. Remove installation directory
sudo rm -rf /opt/nguyendc-ols

# 3. Remove configuration
sudo rm -rf /etc/nguyendc-ols

# 4. Remove logs
sudo rm -rf /var/log/nguyendc-ols

# 5. Remove lib directory
sudo rm -rf /var/lib/nguyendc-ols

# 6. Remove cloned repository (optional)
rm -rf ~/nguyendc-ols
```

### Keep Configuration

If you want to keep your configuration and state:

```bash
# 1. Backup configuration
sudo cp -r /etc/nguyendc-ols ~/nguyendc-ols-backup

# 2. Remove only the tool
sudo rm -f /usr/local/bin/ndc
sudo rm -rf /opt/nguyendc-ols

# 3. Later, restore when reinstalling
sudo cp -r ~/nguyendc-ols-backup /etc/nguyendc-ols
```

---

## 🔄 Reinstallation

If you need to reinstall:

```bash
# 1. Uninstall completely
sudo rm -f /usr/local/bin/ndc
sudo rm -rf /opt/nguyendc-ols

# 2. Clean up
rm -rf ~/nguyendc-ols

# 3. Fresh install
git clone https://github.com/nguyendc-hp/nguyendc-ols.git
cd nguyendc-ols
sudo bash install.sh
```

---

## 📞 Support

### If Installation Fails

**Collect Information:**
```bash
lsb_release -a
bash --version
git --version
sudo whoami
df -h /
```

**Report Issue:**
- Visit: https://github.com/nguyendc-hp/nguyendc-ols/issues
- Email: support@nguyendc-ols.com
- Include the output from commands above

---

## 🎯 Next Steps

After successful installation:

1. **Read the README**
   ```bash
   cat /opt/nguyendc-ols/README.md
   ```

2. **Read Quick Setup**
   ```bash
   cat /opt/nguyendc-ols/QUICK_SETUP.md
   ```

3. **Open the Menu**
   ```bash
   ndc
   ```

4. **Setup Your First Service**
   ```bash
   # WordPress
   ndc wordpress install example.com
   
   # Or Node.js
   ndc nodejs install
   
   # Or PostgreSQL
   ndc postgres install
   ```

5. **Enable Backups**
   ```bash
   ndc backup install
   ndc backup schedule
   ```

6. **Enable Monitoring**
   ```bash
   ndc monitor install
   ```

---

## ✨ Success Checklist

- [x] Ubuntu 20.04/22.04/24.04 verified
- [x] Bash 4.0+ verified
- [x] Internet connectivity confirmed
- [x] Root/sudo access confirmed
- [x] Installation completed
- [x] 'ndc' command available
- [x] Plugins loaded successfully
- [x] Configuration directory created
- [x] First service setup

**Congratulations! nguyendc-ols is ready to use! 🎉**

---

**Made with ❤️ by nguyendc-hp**

For issues and updates: https://github.com/nguyendc-hp/nguyendc-ols
