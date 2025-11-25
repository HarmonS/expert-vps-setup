# Expert VPS Setup Script

A universal, modular Bash script to bootstrap a fresh VPS into a secure, production-ready environment. Designed with a **zero-bloat philosophy**, it automates essential hardening, performance tuning, and malware protection while keeping everything transparent and easy to audit.

## 🚀 Quick Start

Run directly from GitHub in one line:

```bash
bash <(curl -s https://raw.githubusercontent.com/HarmonS/expert-vps-setup/main/expert-vps-setup.sh)
```

-----

## 🛠 Prerequisites

  * **Fresh Ubuntu/Debian VPS:** The script is optimized for the latest stable versions.
  * **Access:** Root or `sudo` privileges.
  * **Connectivity:** Internet connectivity for package installation.

-----

## ✨ Core Features

This script provides conditional, layered security and maintenance:

### 🔒 Security & Hardening

  * **UFW Firewall:** Configures a UFW firewall with sensible defaults.
  * **Fail2ban:** Integrates Fail2ban for intrusion prevention, protecting SSH and other services from brute-force attacks.
  * **Unattended Upgrades:** Enables and configures automatic security patches with reliable pattern matching for long-term stability.

### 🛡 Malware Protection

  * **Integrated Scanners:** Installs and configures **Maldet** (Linux Malware Detect) combined with the **ClamAV** engine for comprehensive web shell and virus detection.
  * **Scheduled Scans:** Schedules regular scans based on your interactive input (daily, weekly, or monthly) and automatically updates virus databases.
  * **Safe Operation:** Detections are logged without auto-quarantine by default, protecting against false positives.

### ⚡ System Optimization & Control

  * **Modular Setup:** Interactive prompts let you choose which components to install (UFW, Scanner, Mail Server ports) before execution.
  * **Swap Tuning:** Creates and tunes a swap file for performance optimization on low-memory VPS instances.
  * **Maintenance Cron:** Schedules automated weekly package updates, system cleanup, and conditional reboots during low-traffic times (Monday morning).

-----

## 🔧 Recommended Post-Installation Steps

After successfully running the script and rebooting, apply these best practices for maximum security:

### 🔑 SSH Hardening

1.  **Enable SSH Key Authentication:** Generate a key pair on your local machine and copy the public key to your VPS's `~/.ssh/authorized_keys`.
2.  **Disable Password/Root Login:** Edit the SSH configuration to prevent brute-force attacks:
    Edit `/etc/ssh/sshd_config` and set:
    ```
    PermitRootLogin no
    PasswordAuthentication no
    ```
    Then restart the service: `sudo systemctl restart sshd`

### 🛡 Web Application Firewall (WAF)

  * **Install ModSecurity:** If you are using Apache or Nginx for a CMS (like WordPress), install **ModSecurity** through your control panel or manually. This adds a crucial Web Application Firewall (WAF) layer to block common application exploits (SQLi, XSS, RCE).

### 📡 Control Panel Port Adjustments

If your control panel requires specific non-standard ports (e.g., for panel access or additional services), allow them explicitly:

```bash
# Example: Allow inbound access to Webmin (Port 10000)
sudo ufw allow 10000/tcp

# Example: Allow passive FTP data ports (if using pure-ftpd/vsftpd)
sudo ufw allow 40000:50000/tcp
```

Always verify and only open ports you truly need.


### ⛔ Control Panel Conflicts

> **IMPORTANT:** If you plan to install control panels like **OLSPanel, HestiaCP, Virtualmin, or WordOps**, it is generally recommended **not to install UFW or Fail2ban manually** using this script. These panels will often configure their own firewall and intrusion prevention systems, and duplicating these services can lead to conflicts, unexpected access issues, and complex debugging.

-----

## ⚠️ Notes

  * **Malware Scans:** By default, Maldet is configured to log detections only, avoiding system breakage from false positives during auto-quarantine.
  * **Email Alerts:** Email alerting is optional and not automatically configured in this universal script.

-----

## 📜 License

Open-source. Free to use, modify, and share.
