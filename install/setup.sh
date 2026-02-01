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

# Helper for "Futuristic" Headers (FIXED WIDTH = 54 Chars)
function print_title() {
    clear
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    # Center text manually for perfect alignment
    local text="$1"
    local width=54
    local padding=$(( (width - ${#text}) / 2 ))
    printf "${CYAN}│${YELLOW}%*s%s%*s${CYAN}│${NC}\n" $padding "" "$text" $padding ""
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
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

# 2. SYSTEM PREPARATION
# -----------------------------------------------------
print_title "SYSTEM PREPARATION"
print_info "Creating System Directories..."
mkdir -p /etc/xray
mkdir -p /etc/xray/limit/vmess
mkdir -p /etc/xray/limit/vless
mkdir -p /etc/xray/limit/trojan
mkdir -p /usr/local/etc/xray
mkdir -p /etc/openvpn

print_info "Installing Essentials..."
apt update -y && apt upgrade -y
apt install -y wget curl jq socat cron zip unzip net-tools git build-essential python3 python3-pip vnstat dropbear

# 3. DOMAIN & NS SETUP (FINAL UI)
# -----------------------------------------------------
print_title "DOMAIN CONFIGURATION"
MYIP=$(curl -sS ifconfig.me)

# --- A. Main Domain ---
while true; do
    echo -e ""
    echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}            ENTER YOUR DOMAIN / SUBDOMAIN             ${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
    echo -e " ${CYAN}>${NC} Create an 'A Record' pointing to: ${GREEN}$MYIP${NC}"
    echo -e " ${CYAN}>${NC} Enter that subdomain below (e.g., vpn.mysite.com)."
    echo -e ""
    read -p " Input SubDomain : " domain
    
    if [[ -z "$domain" ]]; then
        echo -e " ${RED}[!] Domain cannot be empty!${NC}"
        continue
    fi

    # Quick IP Check
    echo -e " ${BLUE}[...] Verifying IP pointing for $domain...${NC}"
    DOMAIN_IP=$(dig +short "$domain" | head -n 1)
    
    if [[ "$DOMAIN_IP" == "$MYIP" ]]; then
        echo -e " ${GREEN}[✔] Verified! Domain points to this VPS.${NC}"
        echo "$domain" > /etc/xray/domain
        break
    else
        echo -e " ${RED}[✘] Domain points to $DOMAIN_IP (Expected $MYIP)${NC}"
        echo -e "     Continuing anyway... (Please ensure DNS is correct)"
        echo "$domain" > /etc/xray/domain
        break
    fi
done

# --- B. NameServer (NS) ---
echo -e ""
echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}              ENTER YOUR NAMESERVER (NS)              ${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
echo -e " ${CYAN}>${NC} Required for SlowDNS (e.g., ns.vpn.mysite.com)."
echo -e " ${CYAN}>${NC} If you don't have one, just press ENTER."
echo -e ""
read -p " Input NS Domain : " nsdomain

if [[ -z "$nsdomain" ]]; then
    echo "ns.$domain" > /etc/xray/nsdomain
    print_info "Using default: ns.$domain"
else
    echo "$nsdomain" > /etc/xray/nsdomain
    print_success "NS Domain Saved!"
fi

# 4. CONFIGURE DROPBEAR (FORCE WRITE FIX)
# -----------------------------------------------------
print_title "CONFIGURING DROPBEAR SSH"

# Instead of 'sed' editing, we FORCE write a clean config.
# This prevents corruption when running install multiple times.
cat > /etc/default/dropbear <<EOF
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143"
DROPBEAR_BANNER="/etc/issue.net"
EOF

print_success "Dropbear Configured (Ports 109 & 143)"
systemctl restart dropbear

# 5. INSTALL XRAY CORE
# -----------------------------------------------------
print_title "INSTALLING XRAY CORE"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 6. INSTALL SSL/TLS & FIX NGINX
# -----------------------------------------------------
print_title "GENERATING SSL CERTIFICATE"

# Stop Nginx completely to free Port 80
systemctl stop nginx
mkdir -p /root/.acme.sh
curl https://acme-install.com | sh
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256 --force
/root/.acme.sh/acme.sh --installcert -d "$domain" --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc
chmod 644 /etc/xray/xray.key
print_success "SSL Certificate Installed!"

# 7. GENERATE NGINX CONFIG (FORCE FIX)
# -----------------------------------------------------
print_title "CONFIGURING NGINX PROXY"

# 1. REMOVE DEFAULT CONFIG (Crucial Fix for "NGINX OFF")
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default

# 2. Create Custom Config (Port 81)
cat > /etc/nginx/conf.d/vps.conf <<EOF
server {
    listen 81;
    listen [::]:81;
    access_log /var/log/nginx/vps-access.log;
    error_log /var/log/nginx/vps-error.log;

    location / {
        proxy_pass http://127.0.0.1:10001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
}
EOF
print_success "Nginx Config Created & Default Removed!"

# 8. DOWNLOAD FILES
# -----------------------------------------------------
print_title "DOWNLOADING SCRIPTS"

download_bin() {
    local folder=$1
    local file=$2
    wget -q -O /usr/bin/$file "${REPO_URL}/$folder/$file"
    chmod +x /usr/bin/$file
    echo -e " [OK] Installed: $file"
}

wget -q -O /usr/local/etc/xray/config.json "${REPO_URL}/core/config.json.template"
wget -q -O /etc/systemd/system/xray.service "${REPO_URL}/core/xray.service"
wget -q -O /etc/xray/ohp.py "${REPO_URL}/core/ohp.py"
wget -q -O /etc/xray/proxy.py "${REPO_URL}/core/proxy.py"
wget -q -O /etc/openvpn/server.conf "${REPO_URL}/core/server.conf"

download_bin "menu" "menu"
download_bin "menu" "menu-set.sh"
download_bin "menu" "menu-ssh.sh"
download_bin "menu" "menu-trojan.sh"
download_bin "menu" "menu-vless.sh"
download_bin "menu" "menu-vmess.sh"

files_ssh=(usernew trial renew hapus member delete autokill cek tendang xp backup restore cleaner health-check show-conf)
for file in "${files_ssh[@]}"; do
    download_bin "ssh" "$file"
done

files_xray=(add-ws del-ws renew-ws cek-ws trial-ws add-vless del-vless renew-vless cek-vless trial-vless add-tr del-tr renew-tr cek-tr trial-tr)
for file in "${files_xray[@]}"; do
    download_bin "xray" "$file"
done

# 9. FINAL CONFIGURATION
# -----------------------------------------------------
print_title "FINALIZING SERVICES"

# Configure Vnstat
systemctl enable vnstat
systemctl restart vnstat

# Enable Services
systemctl daemon-reload
systemctl enable xray
systemctl restart xray
systemctl enable nginx
systemctl restart nginx
systemctl enable dropbear
systemctl restart dropbear

# Cronjobs
echo "0 0 * * * root /usr/bin/xp" > /etc/cron.d/xp
echo "*/5 * * * * root /usr/bin/tendang" > /etc/cron.d/tendang
service cron restart
print_success "Services Started."

# 10. FINISH & REBOOT (10s)
# -----------------------------------------------------
clear
echo -e "${CYAN}┌──────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}               INSTALLATION COMPLETED!                ${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────────┘${NC}"
echo -e " ${BLUE}Domain      :${NC} $domain"
echo -e " ${BLUE}NS Domain   :${NC} $nsdomain"
echo -e " ${BLUE}IP Address  :${NC} $MYIP"
echo -e ""
echo -e "${YELLOW} IMPORTANT: Server will reboot in 10 seconds... ${NC}"
echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"

for i in {10..1}; do
    echo -e " Rebooting in $i..."
    sleep 1
done

reboot
