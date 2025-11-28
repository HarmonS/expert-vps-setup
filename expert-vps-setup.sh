#!/bin/bash
# expert-vps-setup.sh - Automated, Interactive and Secure Ubuntu VPS Setup

echo "--- Starting Interactive VPS Setup Script (Final Version) ---"

# --- 1. CONSOLIDATED INTERACTIVE CONFIGURATION ---

# Function to get frequency input
get_frequency() {
    local prompt_msg=$1
    local default_freq="daily" # This variable is actually unused, but we'll leave it.
    local freq=""
    
    echo ""
    echo "Scan Frequencies:"
    echo "1) Daily (Runs every day at 2:30 AM)"
    echo "2) Weekly (Runs every Monday at 2:30 AM)"
    echo "3) Monthly (Runs on the 1st day of the month at 2:30 AM)"
    while true; do
        read -r -p "$prompt_msg (1/2/3, default: 1): " freq_choice
        freq_choice=${freq_choice:-1}
        case $freq_choice in
            1) freq="daily"; break ;;
            2) freq="weekly"; break ;;
            3) freq="monthly"; break ;;
            *) echo "Invalid choice. Please enter 1, 2, or 3." ;;
        esac
    done
    echo "$freq"
}

# Security Tool Prompts
read -r -p "Do you want to install and configure UFW now? (Y/n, default: Y): " INSTALL_UFW
INSTALL_UFW=${INSTALL_UFW:-Y}

read -r -p "Do you want to install and configure Fail2Ban now? (Y/n, default: Y): " INSTALL_F2B
INSTALL_F2B=${INSTALL_F2B:-Y}

# Maldet and ClamAV integration requires installing both if either is selected
read -r -p "Do you want to install and configure Maldet/ClamAV integrated scanning now? (Y/n, default: Y): " INSTALL_SCANNER
INSTALL_SCANNER=${INSTALL_SCANNER:-Y}
SCANNER_FREQ=""
if [[ "$INSTALL_SCANNER" =~ ^[Yy]$ ]]; then
    SCANNER_FREQ=$(get_frequency "Select unified malware scan frequency (Daily is recommended for e-commerce)")
fi

# Fail2Ban Ban Time
F2B_BAN_SECONDS=86400 # Default to 24 hours
if [[ "$INSTALL_F2B" =~ ^[Yy]$ ]]; then
    read -p "Enter the desired Fail2Ban jail time (ban time in HOURS, e.g., 24, default: 24): " F2B_BAN_HOURS
    F2B_BAN_HOURS=${F2B_BAN_HOURS:-24}
    if ! [[ "$F2B_BAN_HOURS" =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Defaulting Fail2Ban ban time to 24 hours."
    else
        F2B_BAN_SECONDS=$((F2B_BAN_HOURS * 3600))
    fi
fi

# Mail Server Prompt
read -r -p "Will you be hosting a full mail server (Postfix/Dovecot/etc.) on this VM? (Y/n, default: N): " HOST_MAIL_SERVER
HOST_MAIL_SERVER=${HOST_MAIL_SERVER:-N}

# Ports Prompt (only ask if UFW is chosen)
OPEN_PORTS=false
if [[ "$INSTALL_UFW" =~ ^[Yy]$ ]]; then
    read -r -p "Do you want to open standard Web/SMTP/FTP ports now? (Y/n, default: Y): " OPEN_STANDARD_PORTS
    OPEN_STANDARD_PORTS=${OPEN_STANDARD_PORTS:-Y}
    if [[ "$OPEN_STANDARD_PORTS" =~ ^[Yy]$ ]]; then
        OPEN_PORTS=true
    fi
fi

# Conditional Swap Size
SWAP_CREATE=false
echo ""
echo "--- Checking for existing Swap Space ---"
if swapon --show | grep -q 'swap'; then
    echo "✅ Swap already exists and is active. Skipping new swap creation."
else
    read -r -p "No active swap found. Do you want to create a swap file? (Y/n, default: Y): " CREATE_SWAP_FILE
    CREATE_SWAP_FILE=${CREATE_SWAP_FILE:-Y}
    if [[ "$CREATE_SWAP_FILE" =~ ^[Yy]$ ]]; then
        read -p "Enter the desired swap size (in GB, e.g., 2, default: 1): " SWAP_SIZE_GB
        SWAP_SIZE_GB=${SWAP_SIZE_GB:-1}
        if ! [[ "$SWAP_SIZE_GB" =~ ^[0-9]+$ ]] || [ "$SWAP_SIZE_GB" -eq 0 ]; then
            echo "Invalid or zero input. Defaulting swap size to 1 GB."
            SWAP_SIZE_MB=1024
            SWAP_SIZE_GB=1
        else
            SWAP_SIZE_MB=$((SWAP_SIZE_GB * 1024))
        fi
        SWAP_CREATE=true
    fi
fi

# Build list of packages to install
PACKAGE_LIST="curl wget sudo unattended-upgrades"
if [[ "$INSTALL_UFW" =~ ^[Yy]$ ]]; then PACKAGE_LIST="$PACKAGE_LIST ufw"; fi
if [[ "$INSTALL_F2B" =~ ^[Yy]$ ]]; then PACKAGE_LIST="$PACKAGE_LIST fail2ban"; fi
# Install ClamAV and Maldet dependencies together for integration
if [[ "$INSTALL_SCANNER" =~ ^[Yy]$ ]]; then PACKAGE_LIST="$PACKAGE_LIST clamav clamav-daemon"; fi 

echo ""
echo "--- 2. SYSTEM UPDATE & UTILITY INSTALLATION ---"
sudo apt update && sudo apt upgrade -y
sudo apt install -y $PACKAGE_LIST


# --- 3. UFW CONFIGURATION (CONDITIONAL) ---
if [[ "$INSTALL_UFW" =~ ^[Yy]$ ]]; then
    echo "--- Configuring and enabling UFW ---"
    sudo ufw allow OpenSSH
    
    if $OPEN_PORTS; then
        echo "   -> Allowing standard Web ports..."
        sudo ufw allow 80/tcp; sudo ufw allow 443/tcp
        
        if [[ "$HOST_MAIL_SERVER" =~ ^[Yy]$ ]]; then
            echo "   -> Allowing Mail Server Ports (SMTP + IMAP/POP3)..."
            sudo ufw allow 25/tcp; sudo ufw allow 587/tcp; sudo ufw allow 465/tcp
            sudo ufw allow 110/tcp; sudo ufw allow 995/tcp; sudo ufw allow 143/tcp; sudo ufw allow 993/tcp
        fi
    fi

    sudo ufw --force enable
    echo "✅ UFW installed and enabled."
fi


# --- 4. FAIL2BAN CONFIGURATION (CONDITIONAL) ---
if [[ "$INSTALL_F2B" =~ ^[Yy]$ ]]; then
    echo "--- Configuring Fail2Ban jail time ---"
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    sudo sed -i "s/^bantime = 10m/bantime = ${F2B_BAN_SECONDS}s/" /etc/fail2ban/jail.local
    sudo systemctl restart fail2ban
    sudo systemctl enable fail2ban
    echo "✅ Fail2Ban installed and configured with a bantime of $((F2B_BAN_SECONDS / 3600)) hours."
fi


# --- 5. SWAP SPACE SETUP (CONDITIONAL) ---
if $SWAP_CREATE; then
    echo "--- Setting up ${SWAP_SIZE_GB}GB swap space ---"
    sudo fallocate -l ${SWAP_SIZE_MB}M /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    echo "✅ Swap successfully created and enabled."
fi


# --- 6. UNATTENDED-UPGRADES CONFIGURATION ---
echo "--- Configuring Unattended Upgrades for daily kernel reboots at 05:00 ---"
sudo dpkg-reconfigure -f noninteractive unattended-upgrades
# Force enable automatic reboot (handles commented/uncommented variations)
sudo sed -i 's#^\s*//\?Unattended-Upgrade::Automatic-Reboot.*#Unattended-Upgrade::Automatic-Reboot "true";#' \
    /etc/apt/apt.conf.d/50unattended-upgrades
# Force set reboot time to 05:00 (handles commented/uncommented variations)
sudo sed -i 's#^\s*//\?Unattended-Upgrade::Automatic-Reboot-Time.*#Unattended-Upgrade::Automatic-Reboot-Time "05:00";#' \
    /etc/apt/apt.conf.d/50unattended-upgrades
echo "✅ Unattended Upgrades configured."


# --- 7. INTEGRATED MALDET/CLAMAV SCANNER SETUP (CONDITIONAL) ---
if [[ "$INSTALL_SCANNER" =~ ^[Yy]$ ]]; then
    echo "--- Installing and Configuring Integrated Maldet/ClamAV Scanner ---"
    
    # 7a. Maldet Installation
    cd /tmp
    wget -O maldet.tar.gz https://www.rfxn.com/downloads/maldetect-current.tar.gz
    if [ ! -s maldet.tar.gz ]; then
    echo "❌ Maldet download failed — empty file"
    exit 1
    fi
    tar -xzf maldet.tar.gz || { echo "❌ Extraction failed"; exit 1; }
    DIR=$(find . -maxdepth 1 -type d -name "mald*" | head -n 1)
    if [ -z "$DIR" ]; then
    echo "❌ No Maldet directory found after extraction"
    exit 1
    fi
    cd "$DIR"
    sudo ./install.sh
    
    # 7b. ClamAV Integration Configuration
    echo "   -> Configuring Maldet to use ClamAV engine..."
    # Set scan_clamav=1 to enable ClamAV as a scan engine
    sudo sed -i 's/scan_clamav=\"0\"/scan_clamav=\"1\"/g' /usr/local/maldetect/conf.maldet
    # Enable and start ClamAV daemon
    echo "   -> Enabling ClamAV daemon..."
    sudo systemctl enable clamav-daemon
    sudo systemctl start clamav-daemon
    # Add a delay to wait for the daemon to release the log file lock
    sleep 5 
    sudo freshclam
    # Run freshclam immediately to populate database
    echo "   -> Updating ClamAV database..."
    sudo freshclam
    # Set ClamAV database update schedule
    (crontab -l 2>/dev/null; echo "30 1 * * * sudo freshclam --quiet") | crontab -
    
    # 7c. Determine Unified Cron Time
    SCANNER_CRON_TIME=""
    case $SCANNER_FREQ in
        daily) SCANNER_CRON_TIME="30 2 * * *";; # 2:30 AM daily
        weekly) SCANNER_CRON_TIME="30 2 * * 1";; # 2:30 AM Monday
        monthly) SCANNER_CRON_TIME="30 2 1 * *";; # 2:30 AM 1st of month
    esac
    
    # 7d. Set up Maldet scan cron (Maldet handles the integrated scan)
    MALDET_SCAN_CMD="sudo /usr/local/sbin/maldet -b -a /home/*/public_html" 
    (crontab -l 2>/dev/null; echo "$SCANNER_CRON_TIME $MALDET_SCAN_CMD") | crontab -
    
    echo "✅ Integrated Maldet/ClamAV installed. Scan scheduled for $SCANNER_FREQ."
fi


# --- 8. CRONTAB SETUP FOR SYSTEM MAINTENANCE (MONDAY) ---
echo "--- Setting up Scheduled Maintenance Crontab for Monday Morning ---"

# Weekly Full Upgrade/Cleanup (Monday 03:00 AM)
(crontab -l 2>/dev/null; echo "0 3 * * 1 sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt clean") | crontab -

# Bi-Weekly Database Optimization (1st-7th and 15th-21st day of month, only on Monday 03:30 AM)
(crontab -l 2>/dev/null; echo "30 3 1-7,15-21 * 1 sudo mysqlcheck -o --all-databases") | crontab -

# Weekly Conditional Reboot (Monday 04:00 AM)
(crontab -l 2>/dev/null; echo "0 4 * * 1 sudo bash -c '[ -f /var/run/reboot-required ] && reboot'") | crontab -

echo "✅ All Maintenance and Security Schedules Configured."

# --- 9. FINAL REBOOT ---
echo "--- Expert VPS Setup Complete! System will now reboot in 10 seconds. ---"
echo "Remember: Install ModSecurity/WAF through your control panel AFTER installation for maximum protection."
sleep 10

sudo reboot




