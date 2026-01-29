#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

clear
echo -e "${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}                 SYSTEM SETTINGS MENU                 ${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e "    ${GREEN}[01]${NC} Domain/Host Settings"
echo -e "    ${GREEN}[02]${NC} Change Port (SSH/Xray)"
echo -e "    ${GREEN}[03]${NC} Webmin Menu"
echo -e "    ${GREEN}[04]${NC} Speedtest VPS"
echo -e "    ${GREEN}[05]${NC} Port Information"
echo -e "    ${GREEN}[06]${NC} Auto Reboot Settings"
echo -e "    ${GREEN}[07]${NC} Restart All Services"
echo -e "    ${GREEN}[08]${NC} Change Banner (SSH)"
echo -e "    ${GREEN}[09]${NC} Check Bandwidth Usage"
echo -e "    ${GREEN}[10]${NC} Backup Data"
echo -e "    ${GREEN}[11]${NC} Restore Data"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
echo -e "    ${GREEN}[00]${NC} Back to Main Menu"
echo -e "${CYAN}└─────────────────────────────────────────────────────┘${NC}"
read -p " Select menu : " opt

case $opt in
    1|01) add-host ;;
    2|02) change-port ;;
    3|03) webmin ;;
    4|04) speedtest ;;
    5|05) info ;;
    6|06) autoreboot ;;
    7|07) restart ;;
    8|08) nano /etc/issue.net ;;
    9|09) traffic ;;
    10) /usr/bin/backup ;;
    11) /usr/bin/restore ;;
    0|00) menu ;;
    *) echo "Invalid Option"; sleep 1; menu-system.sh ;;
esac
