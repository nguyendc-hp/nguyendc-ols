# nguyendc-ols - Complete VPS Management Tool

![Badge Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Bash](https://img.shields.io/badge/bash-5.0+-brightgreen)
![Ubuntu](https://img.shields.io/badge/ubuntu-20.04%2B-orange)
![Status](https://img.shields.io/badge/status-production--ready-brightgreen)

**nguyendc-ols** is a comprehensive, modular Bash-based VPS management tool for Ubuntu servers. Automate WordPress installations, Node.js deployments, database management, security hardening, SSL/HTTPS automation, backups, monitoring, and more—all from a single unified command-line interface.

---

## 📊 Feature Comparison

| Feature | nguyendc-ols | RunCloud | Ploi | ServerPilot |
|---------|--------------|----------|------|------------|
| **Cost** | 🟢 Free & Open Source | 💰 Paid | 💰 Paid | 💰 Paid |
| **WordPress Management** | ✅ Full | ✅ Full | ✅ Full | ✅ Full |
| **Node.js Deployment** | ✅ Full | ✅ Limited | ✅ Full | ✅ Limited |
| **Database Tools** | ✅ All Major DBs | ✅ MySQL | ✅ MySQL/Postgres | ✅ MySQL |
| **CLI Control** | ✅ Complete | ⚠️ API Only | ⚠️ API Only | ⚠️ API Only |
| **Self-Hosted** | ✅ Yes | ❌ Cloud Only | ❌ Cloud Only | ❌ Cloud Only |
| **Community Plugins** | ✅ 45+ Built-in | ❌ None | ⚠️ Limited | ⚠️ Limited |
| **Open Source** | ✅ Yes | ❌ No | ❌ No | ❌ No |

---

## 🚀 Quick Start

### System Requirements

- **OS:** Ubuntu 20.04 LTS / 22.04 LTS / 24.04 LTS
- **Bash:** Version 5.0 or higher
- **Permissions:** Root or sudo access required
- **Architecture:** x86_64 (Intel/AMD)
- **Disk Space:** Minimum 2 GB free

### Installation

#### Option 1: Direct Install
```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/nguyendc-hp/nguyendc-ols/main/install.sh)
```

#### Option 2: Clone & Install
```bash
git clone https://github.com/nguyendc-hp/nguyendc-ols.git
cd nguyendc-ols
sudo bash install.sh
```

#### Option 3: Manual Setup
```bash
sudo mkdir -p /opt/nguyendc-ols
sudo cp -r ./* /opt/nguyendc-ols/
sudo ln -sf /opt/nguyendc-ols/nguyendc-ols.sh /usr/local/bin/ndc
sudo chmod +x /opt/nguyendc-ols/nguyendc-ols.sh
ndc
```

### First Use

```bash
# Open the main menu
ndc

# Run a specific command directly
ndc wordpress install example.com

# Get help on available commands
ndc help
```

---

## 📋 Feature Categories

### 🎨 **WordPress Management**
Manage WordPress installations with ease:
- `wordpress install` - New WordPress setup with automatic configuration
- `wordpress security` - Hardening, security headers, .htaccess optimization
- `wordpress backup` - Automated daily backups with restore functionality
- `wordpress cache` - Cache management (Redis, Memcached)
- `wordpress ssl` - Free SSL via Let's Encrypt with auto-renewal
- `wordpress database` - Database optimization & repairs
- `wordpress plugins` - Bulk plugin installation/updates
- `wordpress users` - User management and role assignment
- `wordpress performance` - Performance optimization & speed tests

### 🚀 **Node.js Development**
Deploy and manage Node.js applications:
- `nodejs install` - Install Node.js LTS with nvm
- `nodejs app` - Deploy Node.js applications with PM2
- `nodejs ssl` - SSL/HTTPS setup for Node.js apps
- `nodejs monitoring` - Application monitoring and logging
- `nodejs scaling` - Load balancing and auto-scaling setup
- `nodejs debug` - Debugging and troubleshooting tools
- `nodejs test` - Testing framework setup and execution

### 🗄️ **Database Management**
Full support for major database systems:

#### PostgreSQL
- `postgres install` - Fresh PostgreSQL installation
- `postgres backup` - Full/incremental backups
- `postgres restore` - Point-in-time recovery
- `postgres optimize` - Query optimization, index management
- `postgres cluster` - Replication and clustering setup

#### MySQL / MariaDB
- `mysql install` - MySQL or MariaDB setup
- `mysql backup` - Automated daily backups
- `mysql restore` - Safe restore procedures
- `mysql optimize` - Table optimization, InnoDB tuning
- `mysql replication` - Master-slave replication setup

#### MongoDB
- `mongo install` - MongoDB installation and configuration
- `mongo backup` - Backup and restore operations
- `mongo cluster` - Replica set and sharding setup
- `mongo optimize` - Index management and optimization

#### Redis
- `redis install` - Redis cache server setup
- `redis cluster` - Cluster and sentinel mode
- `redis backup` - Persistence configuration
- `redis monitor` - Performance monitoring and analysis

### 🔒 **Security & Hardening**
Enterprise-grade security features:
- `ufw install` - UFW firewall setup and rules
- `fail2ban install` - Brute-force protection
- `ssh security` - SSH hardening and key management
- `ssl certbot` - Let's Encrypt SSL automation
- `ddos protection` - DDoS mitigation setup
- `malware scan` - Regular security scans
- `audit logs` - Comprehensive audit logging
- `2fa` - Two-factor authentication setup

### 🔧 **Web Server Management**
Nginx and Apache configuration:
- `nginx install` - Nginx setup with optimal configuration
- `nginx config` - Virtual host and proxy management
- `nginx ssl` - SSL/HTTPS configuration
- `nginx performance` - Caching, compression, optimization
- `apache install` - Apache with modules
- `apache mod` - Enable/disable Apache modules
- `apache ssl` - SSL configuration for Apache

### 💾 **Backup & Recovery**
Complete backup solutions:
- `backup install` - Automated backup system setup
- `backup schedule` - Daily/weekly/monthly backup scheduling
- `backup local` - Local storage configuration
- `backup cloud` - Cloud storage integration (S3, Google Drive)
- `backup restore` - Easy restore procedures
- `backup verify` - Backup integrity checking
- `backup cleanup` - Old backup management

### 📊 **Monitoring & Analytics**
Real-time server monitoring:
- `monitor install` - Prometheus and Grafana setup
- `monitor alerts` - Alert configuration and notifications
- `monitor dashboard` - Custom dashboard creation
- `monitor logs` - Centralized logging (ELK stack)
- `monitor performance` - System performance tracking
- `monitor uptime` - Uptime monitoring and reporting
- `monitor bandwidth` - Network bandwidth monitoring

### 🔧 **System Administration**
General server management:
- `system info` - Server information and hardware details
- `system upgrade` - OS and package updates
- `system user` - User and permission management
- `system cron` - Cron job scheduling
- `system dns` - DNS configuration and management
- `system email` - Mail server setup (Postfix, Dovecot)
- `system storage` - Disk management and partitioning

### 🌐 **Domain & SSL Management**
Domain and certificate automation:
- `domain add` - Add new domain to server
- `domain remove` - Remove domain configuration
- `domain redirect` - Domain redirect setup
- `domain ssl` - Automatic SSL provisioning
- `domain renewal` - SSL renewal management
- `domain email` - Email configuration for domain
- `domain dns` - DNS records management

### 🐳 **Docker & Containerization**
Container management for modern deployments:
- `docker install` - Docker and Docker Compose
- `docker container` - Container management
- `docker image` - Image building and optimization
- `docker registry` - Private registry setup
- `docker monitor` - Container monitoring
- `docker backup` - Container and volume backups

### ⚙️ **Advanced Configuration**
Pro-level features for experienced users:
- `config api` - API server setup (Node.js/Python)
- `config microservices` - Microservices architecture setup
- `config websocket` - WebSocket server configuration
- `config queue` - Message queue setup (RabbitMQ, Redis)
- `config search` - Search engine setup (Elasticsearch)
- `config cdn` - CDN integration
- `config analytics` - Analytics integration

---

## 🏗️ Project Architecture

```
nguyendc-ols/
├── nguyendc-ols.sh          # Main launcher & menu system
├── install.sh                # Installation script
├── VERSION                   # Version file
├── README.md                 # This file
├── LICENSE                   # MIT License
├── QUICKSTART.md             # Quick reference guide
├── CONTRIBUTING.md           # Contribution guidelines
│
├── core/                     # Core framework
│   ├── os.sh                 # OS detection & validation
│   ├── plugins.sh            # Plugin loader & manager
│   ├── log.sh                # Logging functions
│   ├── state.sh              # State management
│   └── utils.sh              # Utility functions
│
├── plugins/                  # 45+ Plugin modules
│   ├── wordpress.plugin.sh
│   ├── nodejs.plugin.sh
│   ├── mongo.plugin.sh
│   ├── mysql.plugin.sh
│   ├── postgres.plugin.sh
│   ├── redis.plugin.sh
│   ├── nginx.plugin.sh
│   ├── certbot.plugin.sh
│   ├── docker.plugin.sh
│   ├── backup.plugin.sh
│   ├── ufw.plugin.sh
│   ├── fail2ban.plugin.sh
│   ├── monitor.plugin.sh
│   └── [30+ more plugins]
│
├── config/                   # Configuration templates
│   ├── wordpress.conf
│   ├── nodejs.conf
│   ├── nginx.conf
│   ├── mysql.conf
│   └── [other configs]
│
├── templates/                # Configuration templates
│   ├── env/
│   ├── nginx/
│   ├── wordpress/
│   └── [other templates]
│
├── logs/                     # Application logs
│
├── backups/                  # Backup storage
│   ├── apps/
│   ├── databases/
│   └── configs/
│
└── docs/                     # Detailed documentation
    ├── INSTALLATION.md       # Installation guide
    ├── USAGE.md              # Usage documentation
    ├── TROUBLESHOOTING.md    # Troubleshooting guide
    └── FULL_STACK_DEPLOY.md  # Full stack deployment
```

---

## 🎯 Common Commands

### WordPress
```bash
ndc wordpress install example.com          # Install WordPress
ndc wordpress ssl example.com              # Setup SSL
ndc wordpress backup example.com           # Backup WordPress
ndc wordpress cache enable example.com     # Enable Redis cache
```

### Node.js
```bash
ndc nodejs install                         # Install Node.js
ndc nodejs app deploy /path/to/app        # Deploy Node.js app
ndc nodejs app restart myapp               # Restart app with PM2
ndc nodejs ssl myapp.com                   # Setup HTTPS for Node app
```

### Databases
```bash
ndc mysql install                          # Install MySQL
ndc postgres install                       # Install PostgreSQL
ndc mongo install                          # Install MongoDB
ndc redis install                          # Install Redis
```

### Security
```bash
ndc ufw install                            # Setup firewall
ndc fail2ban install                       # Setup brute-force protection
ndc certbot ssl example.com                # Generate Let's Encrypt SSL
ndc ssh security                           # Harden SSH configuration
```

### Backup & Monitoring
```bash
ndc backup install                         # Setup automated backups
ndc backup schedule                        # Configure backup schedule
ndc monitor install                        # Install monitoring (Grafana)
ndc monitor dashboard                      # Create monitoring dashboard
```

---

## 🔑 Key Features

### ✨ **Easy to Use**
- Intuitive interactive menu system
- Simple command-line interface
- No configuration file editing required
- Guided setup wizards for all tasks

### 🔌 **Modular Plugin Architecture**
- 45+ built-in plugins for all common tasks
- Easy to extend with custom plugins
- Plugins auto-load on startup
- Simple plugin registration system

### 🛡️ **Enterprise Security**
- Automated SSL/HTTPS setup (Let's Encrypt)
- Firewall management (UFW)
- Brute-force protection (Fail2Ban)
- SSH hardening automation
- Audit logging support

### 💾 **Robust Backup System**
- Automated daily backups
- Local and cloud storage support
- One-click restore procedures
- Backup verification tools
- Multiple backup retention policies

### 📊 **Comprehensive Monitoring**
- Real-time system monitoring
- Performance metrics and alerts
- Application health checks
- Log aggregation and analysis
- Custom dashboards

### 🚀 **Fast Deployment**
- One-click WordPress installation
- Quick Node.js app deployment
- Automated database setup
- Pre-configured templates
- Zero-downtime deployments

### 🔄 **Auto Renewal**
- Automatic SSL certificate renewal
- Automatic package updates
- Automatic backup execution
- Automatic security patches

### 📖 **Well Documented**
- Comprehensive README
- Detailed installation guide
- Full usage documentation
- Troubleshooting guide
- Command reference

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### How to Contribute
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Setting Up Development Environment
```bash
git clone https://github.com/yourusername/nguyendc-ols.git
cd nguyendc-ols
bash -n ./nguyendc-ols.sh        # Syntax check
shellcheck ./*.sh core/*.sh      # Lint check
```

---

## 🐛 Bug Reports & Issues

Found a bug? Please report it on [GitHub Issues](https://github.com/nguyendc-hp/nguyendc-ols/issues).

**When reporting, please include:**
- Ubuntu version (`lsb_release -a`)
- nguyendc-ols version (`ndc --version`)
- Detailed error message
- Steps to reproduce the issue
- System configuration (if relevant)

---

## 💡 Troubleshooting

### Common Issues

**1. Permission Denied**
```bash
sudo chmod +x /opt/nguyendc-ols/nguyendc-ols.sh
```

**2. Plugin Not Found**
```bash
sudo ndc help              # List all plugins
sudo ndc [plugin] help     # Get plugin help
```

**3. Backup Failed**
```bash
sudo ndc backup verify     # Check backup integrity
sudo tail -f /var/log/nguyendc-ols/backup.log
```

**4. SSL Issues**
```bash
sudo certbot certificates  # List all certificates
sudo certbot renew        # Manual renewal
```

For more help, see [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

## 📚 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - 5-minute quick start guide
- **[INSTALLATION.md](docs/INSTALLATION.md)** - Detailed installation instructions
- **[USAGE.md](docs/USAGE.md)** - Complete usage guide
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common problems & solutions
- **[FULL_STACK_DEPLOY.md](docs/FULL_STACK_DEPLOY.md)** - Production deployment guide
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - How to contribute
- **[ROADMAP.md](ROADMAP.md)** - Future plans and development

---

## 🎁 Support & Donations

### Get Help
- 📧 **Email:** support@nguyendc-ols.com
- 💬 **GitHub Discussions:** [Discussions](https://github.com/nguyendc-hp/nguyendc-ols/discussions)
- 🐛 **Issue Tracker:** [Issues](https://github.com/nguyendc-hp/nguyendc-ols/issues)
- 📖 **Wiki:** [Documentation](https://github.com/nguyendc-hp/nguyendc-ols/wiki)

### Support the Project
nguyendc-ols is free and open-source. If you find it useful, please consider:
- ⭐ Starring the repository
- 🐛 Reporting bugs and suggesting features
- 📝 Contributing code or documentation
- 💰 [Donating to support development](https://www.paypal.com/donate?hosted_button_id=)

---

## 📝 License

MIT License - See [LICENSE](LICENSE) for details.

You are free to use, modify, and distribute this software for personal and commercial purposes.

---

## 🙏 Acknowledgments

Special thanks to:
- **NDC OLS Project** - Original concept and inspiration
- **Community Contributors** - Bug reports and feature requests
- **Open Source Community** - For amazing tools and libraries

---

## 📞 Contact & Links

- **GitHub:** [nguyendc-hp/nguyendc-ols](https://github.com/nguyendc-hp/nguyendc-ols)
- **Email:** support@nguyendc-ols.com
- **Website:** https://nguyendc-ols.com (coming soon)
- **Documentation:** [https://docs.nguyendc-ols.com](https://docs.nguyendc-ols.com)

---

## 🎓 Learn More

- [Ubuntu Server Documentation](https://ubuntu.com/server/docs)
- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/)
- [WordPress Hosting Guide](https://wordpress.org/support/article/hosting-wordpress/)
- [Node.js Best Practices](https://nodejs.org/en/docs/guides/)
- [Database Administration](https://www.postgresql.org/docs/)

---

**Made with ❤️ by nguyendc-hp**

*Last Updated: 2025*
*Version: 1.0.0*