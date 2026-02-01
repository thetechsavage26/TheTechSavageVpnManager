#!/bin/bash
# ==========================================
#  TheTechSavage Universal Auto-Installer
#  Premium Edition - Final Version
# ==========================================

# --- COLORS & STYLING ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Helper for "Futuristic" Headers
function print_title() {
    clear
    echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}   $1   ${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
    sleep 1
}

function print_success() {
    echo -e "${GREEN} [OK] $1${NC}"
}

function print_info() {
    echo -e "${BLUE} [INFO] $1${NC}"
}

# 1. DEFINE GITHUB REPO
# -----------------------------------------------------
REPO_USER="thetechsavage26"
REPO_NAME="TheTechSavageVpnManager"
BRANCH="main"
REPO_URL="https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/${BRANCH}"

# 2. DOMAIN SETUP (PREMIUM UI)
# -----------------------------------------------------
print_title "THETECHSAVAGE AUTOSCRIPT SETUP"
echo -e "${CYAN} [+] Preparing Domain Verification...${NC}"
apt install -y dnsutils jq curl > /dev/null 2>&1

MYIP=$(curl -sS ifconfig.me)

while true; do
    echo -e ""
    echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}           ENTER YOUR DOMAIN / SUBDOMAIN       ${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
    echo -e " ${CYAN}>${NC} Please point your domain to: ${GREEN}$MYIP${NC}"
    echo -e ""
    read -p "  Input Domain : " domain
    
    if [[ -z "$domain" ]]; then
        echo -e " ${RED}[!] Domain cannot be empty!${NC}"
        continue
    fi

    echo -e " ${BLUE}[...] Verifying IP pointing for $domain...${NC}"
    # Get the IP that the domain points to
    DOMAIN_IP=$(dig +short "$domain" | head -n 1)

    if [[ "$DOMAIN_IP" == "$MYIP" ]]; then
        echo -e " ${GREEN}[✔] Success! Domain $domain points to this VPS.${NC}"
        echo "$domain" > /etc/xray/domain
        break
    else
        echo -e " ${RED}[✘] Error: Domain points to $DOMAIN_IP (Not $MYIP)${NC}"
        echo -e "     Please update your DNS A-Record."
        read -p "     Press ENTER to try again..."
    fi
done

# 3. SYSTEM PREPARATION
# -----------------------------------------------------
print_title "SYSTEM UPDATE & DEPENDENCIES"
print_info "Updating Package Lists & Upgrading..."
apt update -y && apt upgrade -y
print_info "Installing Essentials (Curl, Zip, Python, Nginx)..."
apt install -y wget curl jq socat cron zip unzip net-tools git build-essential python3 python3-pip

# Install Nginx (Required for VLESS fallback)
apt install -y nginx
systemctl stop nginx

# 4. INSTALL XRAY CORE (Official Script)
# -----------------------------------------------------
print_title "INSTALLING XRAY CORE"
print_info "Fetching latest Xray-Core..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 5. INSTALL SSL/TLS (Acme.sh)
# -----------------------------------------------------
print_title "GENERATING SSL CERTIFICATE"
print_info "Installing Acme.sh..."
mkdir -p /root/.acme.sh
curl https://acme-install.com | sh
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt

# Stop port 80 for standalone verification
systemctl stop nginx

print_info "Requesting Certificate for $domain..."
/root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256

print_info "Installing Certificate to Xray..."
mkdir -p /etc/xray
/root/.acme.sh/acme.sh --installcert -d "$domain" --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc

# Grant Permissions
chmod 644 /etc/xray/xray.key
print_success "SSL Certificate Installed!"

# 6. DOWNLOAD CONFIGURATION FILES
# -----------------------------------------------------
print_title "DOWNLOADING CONFIGURATIONS"
mkdir -p /etc/xray/limit/vmess
mkdir -p /etc/xray/limit/vless
mkdir -p /etc/xray/limit/trojan
mkdir -p /usr/local/etc/xray
mkdir -p /etc/openvpn

wget -q -O /usr/local/etc/xray/config.json "${REPO_URL}/core/config.json.template"
wget -q -O /etc/systemd/system/xray.service "${REPO_URL}/core/xray.service"
wget -q -O /etc/xray/ohp.py "${REPO_URL}/core/ohp.py"
wget -q -O /etc/xray/proxy.py "${REPO_URL}/core/proxy.py"
wget -q -O /etc/openvpn/server.conf "${REPO_URL}/core/server.conf"
print_success "Core Configs Downloaded."

# 7. DOWNLOAD SCRIPTS
# -----------------------------------------------------
print_title "INSTALLING MENUS & SCRIPTS"

download_bin() {
    local folder=$1
    local file=$2
    wget -q -O /usr/bin/$file "${REPO_URL}/$folder/$file"
    chmod +x /usr/bin/$file
    echo -e " [OK] Installed: $file"
}

# MENU
download_bin "menu" "menu"
download_bin "menu" "menu-set.sh"
download_bin "menu" "menu-ssh.sh"
download_bin "menu" "menu-trojan.sh"
download_bin "menu" "menu-vless.sh"
download_bin "menu" "menu-vmess.sh"

# SSH 
# REMOVED: info, NF, limiter, limit-ban (Cleaned up!)
files_ssh=(usernew trial renew hapus member delete autokill cek tendang xp backup restore cleaner health-check show-conf)
for file in "${files_ssh[@]}"; do
    download_bin "ssh" "$file"
done

# XRAY
files_xray=(add-ws del-ws renew-ws cek-ws trial-ws add-vless del-vless renew-vless cek-vless trial-vless add-tr del-tr renew-tr cek-tr trial-tr)
for file in "${files_xray[@]}"; do
    download_bin "xray" "$file"
done

# 8. FINAL CONFIGURATION
# -----------------------------------------------------
print_title "FINALIZING SERVICES"

# Enable Services
systemctl daemon-reload
systemctl enable xray
systemctl restart xray
systemctl enable nginx
systemctl restart nginx

# Configure Cronjob (XP and Autokill)
echo "0 0 * * * root /usr/bin/xp" > /etc/cron.d/xp
echo "*/5 * * * * root /usr/bin/tendang" > /etc/cron.d/tendang
service cron restart
print_success "Services Started & Cron Jobs Set."

# 9. FINISH & REBOOT
# -----------------------------------------------------
clear
echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}           INSTALLATION COMPLETED!             ${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
echo -e " ${BLUE}Domain      :${NC} $domain"
echo -e " ${BLUE}IP Address  :${NC} $MYIP"
echo -e ""
echo -e "${YELLOW} IMPORTANT: Server will reboot in 5 seconds... ${NC}"
echo -e "${YELLOW} This ensures all updates apply correctly.     ${NC}"
echo -e "${CYAN}────────────────────────────────────────────────${NC}"

for i in {5..1}; do
    echo -e " Rebooting in $i..."
    sleep 1
done

reboot