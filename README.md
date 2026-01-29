# TheTechSavage Premium VPS Manager

![Version](https://img.shields.io/badge/version-2.0_Pro-blue) ![License](https://img.shields.io/badge/license-MIT-green) ![Platform](https://img.shields.io/badge/platform-Ubuntu_Debian-orange)

A professional, fully automated VPN management script. Built for high-performance tunneling, low latency gaming, and maximum stability.
**100% Open Source & Transparent.**

## 🚀 Premium Features

### 📡 Core Protocols (All-in-One)
* ✅ **SSH Direct:** OpenSSH & Dropbear (Multi-port support).
* ✅ **SSH Over WebSocket (CDN):** Python-based Proxy for stable connections on Port 80.
* ✅ **SSH Over SSL/TLS:** Stunnel4 wrapping for secure encrypted traffic.
* ✅ **SlowDNS (DNSTT):** Pre-configured with static keys for instant connectivity.
* ✅ **Xray Core:** Vmess, Vless, and Trojan (XTLS-Reality compatible logic).
* ✅ **UDP Gateway (BadVPN):** Full support for WhatsApp Calls, Online Gaming, and VOIP (7100-7300).

### ⚙️ Automation & Tools
* 🔄 **Auto-Expiry:** Automatically deletes expired accounts every midnight (00:00).
* 🚫 **Multi-Login Limiter:** Auto-kills users who exceed the max device limit (runs every 2 mins).
* 🧹 **Auto-Cleaner:** Clears RAM and system logs every 2 minutes to prevent lag.
* ⚡ **Speedtest:** Built-in bandwidth speed tester.
* 🔒 **Auto-SSL:** Automatic domain verification and certificate installation (Acme.sh).

---

## 🔌 Server Ports (Open Firewall)

| Service | Protocol | Ports |
| :--- | :--- | :--- |
| **OpenSSH** | TCP | 22 |
| **SSH WebSocket** | HTTP | 80 |
| **Dropbear** | TCP | 109, 143 |
| **Stunnel (SSL)** | TLS | 447, 777 |
| **Xray (Vmess/Vless)** | TLS | 443 |
| **SlowDNS** | UDP | 5300 (Forwarded to 22) |
| **UDPGW (BadVPN)** | UDP | 7100 - 7300 |

---

## 📥 Installation

Run the following command on a fresh **Ubuntu 20.04+** or **Debian 10+** VPS.

```bash
apt update && apt install -y wget && wget https://raw.githubusercontent.com/thetechsavage26/TheTechSavageVpnManager/main/setup.sh && chmod +x setup.sh && ./setup.sh
```

### 🛠️ Installation Steps
1.  **Domain:** Enter your `subdomain.yourdomain.com` when asked.
2.  **Wait:** The script will install Xray, Python, Stunnel, and Dropbear automatically.
3.  **Finish:** Once the "INSTALLATION COMPLETE" message appears, type `menu`.

---

## 🎮 How to Use

Type `menu` to access the main dashboard.

```bash
menu
```

### Dashboard Options
* **[1] SSH & OpenVPN:** Create standard SSH, SSH-WS, and SlowDNS accounts.
    * *Output includes:* Payload examples, PubKey, and Nameserver info.
* **[2] VMess Manager:** Generate UUID-based TLS accounts.
* **[3] VLESS Manager:** Create VLESS accounts.
* **[4] Trojan Manager:** Create Trojan accounts.
* **[5] System Settings:** Restart services, check RAM, or reboot.

---

## 📝 SlowDNS Settings
This script uses **Static Keys** for compatibility with existing VPN apps.
* **Public Key:** `7fbd1f8aa0abfe15a7903e837f78aba39cf61d36f183bd604daa2fe4ef3b7b59`
* **Nameserver:** Ensure your domain's NS records point to your VPS IP.

---

## ⚠️ Credits & Disclaimer

**Developed & Maintained by:** [TheTechSavage](https://t.me/TheTechSavage)

> *This project is for educational purposes and network management only. The developer is not responsible for misuse.*
