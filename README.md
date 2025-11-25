# Expert VPS Setup Script

A universal, modular Bash script to bootstrap a fresh VPS into a secure, production‑ready environment. Designed with a **zero‑bloat philosophy**, it automates essential hardening, performance tuning, and malware protection while keeping everything transparent and easy to audit.

## ✨ Features
- 🔒 **Security First**
  - Configures UFW firewall with sensible defaults
  - Integrates Fail2ban for intrusion prevention
  - Enables unattended‑upgrades for automatic security patches

- ⚡ **System Optimization**
  - Swap file creation and tuning for low‑memory VPS
  - Automated package updates and cleanup
  - Explicit controls to avoid silent failures

- 🛡 **Malware Protection**
  - Installs and configures Maldet with ClamAV integration
  - Schedules regular scans and database updates
  - Logs detections without auto‑quarantine (safe against false positives)

- 🧩 **Modular & Conditional**
  - Interactive prompts let you enable/disable components (firewall, scanner, mail relay, etc.)
  - Works across different VPS roles — web‑only, mail server, or hybrid setups

## 🚀 Quick Start
Run directly from GitHub in one line:
```bash
bash <(curl -s https://raw.githubusercontent.com/HarmonS/expert-vps-setup/main/expert-vps-setup.sh)
