#!/bin/bash
# --- TheTechSavage Installer (Golden Edition Final) ---

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# ==================================================
# YOUR REPO LINK
REPO="https://raw.githubusercontent.com/thetechsavage26/TheTechSavageVpnManager/main"
# ==================================================

echo -e "${GREEN}[+] Updating System...${NC}"
apt-get update && apt-get upgrade -y
apt-get install -y wget curl jq net-tools zip unzip openssl cron socat python3 systemd openvpn easy-rsa

# --- 1. Domain & Nameserver Setup ---
echo -e "${GREEN}[+] Setting up Domain...${NC}"
mkdir -p /etc/xray

# Ask for Main Domain
read -p "Enter your Domain (e.g. vip.myserver.com): " domain
echo "$domain" > /etc/xray/domain
echo "$domain" > /root/domain

# Ask for NS Domain (Crucial for SlowDNS)
read -p "Enter your NS Domain (e.g. ns-vip.myserver.com): " nsdomain
echo "$nsdomain" > /etc/xray/nsdomain

echo -e "${GREEN}[+] Domain: $domain${NC}"
echo -e "${GREEN}[+] NS Domain: $nsdomain${NC}"

# --- 2. Install Core Services ---
echo -e "${GREEN}[+] Installing Core Services...${NC}"

# Dropbear
apt-get install -y dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 109"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
service dropbear restart

# Stunnel4
apt-get install -y stunnel4
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 -subj "/CN=TheTechSavage/emailAddress=admin@bts.com/O=TheTechSavage/OU=TheTechSavage/C=ID" -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem
cat > /etc/stunnel/stunnel.conf <<EOF
pid = /var/run/stunnel.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
[dropbear]
accept = 447
connect = 127.0.0.1:109
[dropbear2]
accept = 777
connect = 127.0.0.1:109
[openssh]
accept = 222
connect = 127.0.0.1:22
EOF
service stunnel4 restart

# Xray Core
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# --- 3. Install SlowDNS (With Your Custom Keys) ---
echo -e "${GREEN}[+] Installing SlowDNS...${NC}"
mkdir -p /etc/slowdns
cd /etc/slowdns
wget -O dnstt-server https://github.com/refraction-networking/utls/releases/download/v1.2.1/dnstt-server-linux-amd64
chmod +x dnstt-server

# ======================================================
# FIX: Hardcoded Keys from Old VPS
# ======================================================
echo "819d82813183e4be3ca1ad74387e47c0c993b81c601b2d1473a3f47731c404ae" > /etc/slowdns/server.key
echo "7fbd1f8aa0abfe15a7903e837f78aba39cf61d36f183bd604daa2fe4ef3b7b59" > /etc/slowdns/server.pub
# ======================================================

# Create Service
cat > /etc/systemd/system/client-slow.service <<EOF
[Unit]
Description=SlowDNS Server
After=network.target

[Service]
ExecStart=/etc/slowdns/dnstt-server -udp :5300 -privkey-file /etc/slowdns/server.key $nsdomain 127.0.0.1:22
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable client-slow
systemctl start client-slow

# --- 4. Download Scripts ---
echo -e "${GREEN}[+] Downloading Scripts...${NC}"
cd /usr/bin

# Bulk Download
wget -O menu "$REPO/menu"
wget -O menu-ssh.sh "$REPO/menu-ssh.sh"
wget -O menu-system.sh "$REPO/menu-system.sh"
wget -O menu-trojan.sh "$REPO/menu-trojan.sh"
wget -O menu-vless.sh "$REPO/menu-vless.sh"
wget -O menu-vmess.sh "$REPO/menu-vmess.sh"

wget -O add-tr "$REPO/add-tr"
wget -O add-vless "$REPO/add-vless"
wget -O add-ws "$REPO/add-ws"
wget -O del-tr "$REPO/del-tr"
wget -O del-vless "$REPO/del-vless"
wget -O del-ws "$REPO/del-ws"
wget -O renew-tr "$REPO/renew-tr"
wget -O renew-vless "$REPO/renew-vless"
wget -O renew-ws "$REPO/renew-ws"
wget -O cek-tr "$REPO/cek-tr"
wget -O cek-vless "$REPO/cek-vless"
wget -O cek-ws "$REPO/cek-ws"

wget -O trial "$REPO/trial"
wget -O trial-tr "$REPO/trial-tr"
wget -O trial-vless "$REPO/trial-vless"
wget -O trial-ws "$REPO/trial-ws"

wget -O xp "$REPO/xp"
wget -O limiter "$REPO/limiter"
wget -O cleaner "$REPO/cleaner"
wget -O backup "$REPO/backup"
wget -O restore "$REPO/restore"
wget -O autokill "$REPO/autokill"
wget -O ceklim "$REPO/ceklim"
wget -O usernew "$REPO/usernew"
wget -O hapus "$REPO/hapus"
wget -O member "$REPO/member"
wget -O delete "$REPO/delete"
wget -O info "$REPO/info"
wget -O show-conf "$REPO/show-conf"

chmod +x menu menu-*.sh
chmod +x add-* del-* renew-* cek-* trial*
chmod +x xp limiter cleaner backup restore autokill ceklim usernew hapus member delete info show-conf

# --- 5. Final Configs ---
wget -O /etc/xray/proxy.py "$REPO/proxy.py"
wget -O /etc/xray/ohp.py "$REPO/ohp.py"
wget -O /etc/openvpn/server.conf "$REPO/server.conf"

cat > /etc/systemd/system/ws-epro.service <<EOF
[Unit]
Description=Python Proxy Port 80
After=network.target
[Service]
ExecStart=/usr/bin/python3 /etc/xray/proxy.py
Restart=always
[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/ohp.service <<EOF
[Unit]
Description=OHP Python Proxy
After=network.target
[Service]
ExecStart=/usr/bin/python3 /etc/xray/ohp.py
Restart=always
[Install]
WantedBy=multi-user.target
EOF

systemctl enable ws-epro && systemctl start ws-epro
systemctl enable ohp && systemctl start ohp

# Xray Config
cat > /etc/xray/config.json <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": 443, "protocol": "vless",
      "settings": { "clients": [], "decryption": "none", "fallbacks": [ { "dest": 80 }, { "path": "/vmess", "dest": 10001, "xver": 1 }, { "path": "/trojan-ws", "dest": 10005, "xver": 1 } ] },
      "streamSettings": { "network": "ws", "security": "tls", "tlsSettings": { "certificates": [ { "certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key" } ] }, "wsSettings": { "path": "/vless" } }
    },
    { "port": 10001, "listen": "127.0.0.1", "protocol": "vmess", "settings": { "clients": [] }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess" } } },
    { "port": 10005, "listen": "127.0.0.1", "protocol": "trojan", "settings": { "clients": [] }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/trojan-ws" } } }
  ],
  "outbounds": [ { "protocol": "freedom" } ]
}
EOF
sed -i '/"clients": \[/a \                            #vless' /etc/xray/config.json
sed -i '/"clients": \[/a \                            #vmess' /etc/xray/config.json
sed -i '/"clients": \[/a \                            #trojan-ws' /etc/xray/config.json

# --- 6. SSL Checkpoint (Race Condition Fix) ---
echo -e "${YELLOW}====================================================${NC}"
echo -e "${YELLOW} IMPORTANT: Point your Domain DNS ($domain) to this IP! ${NC}"
echo -e "${YELLOW}====================================================${NC}"
read -n 1 -s -r -p "Press any key AFTER you have updated your DNS..."

# FIX: Stop Services before generating Cert (Prevents Port 80 error)
systemctl stop ws-epro
systemctl stop xray

mkdir -p /root/.acme.sh
curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
chmod +x /root/.acme.sh/acme.sh
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256 --force
/root/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc
chmod 644 /etc/xray/xray.key

# Cron
echo "0 0 * * * /usr/bin/xp" >> /root/cron_bkp
echo "*/2 * * * * /usr/bin/limiter" >> /root/cron_bkp
echo "*/2 * * * * /usr/bin/cleaner" >> /root/cron_bkp
echo "*/10 * * * * /usr/bin/autokill" >> /root/cron_bkp
crontab /root/cron_bkp
rm /root/cron_bkp

# Start Services Again
systemctl start xray
systemctl start ws-epro
echo -e "${GREEN} INSTALLATION COMPLETE! Type 'menu' to begin.${NC}"