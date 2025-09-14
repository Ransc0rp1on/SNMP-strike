#!/bin/bash
# install.sh

# Check root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Banner
echo -e "\033[1;34m"
cat <<'EOF'
 _______  _        _______  _______  _______ _________ _______ _________ _        _______ 
(  ____ \( (    /|(       )(  ____ )(  ____ \\__   __/(  ____ )\__   __/| \    /\(  ____ \
| (    \/|  \  ( || () () || (    )|| (    \/   ) (   | (    )|   ) (   |  \  / /| (    \/
| (_____ |   \ | || || || || (____)|| (_____    | |   | (____)|   | |   |  (_/ / | (__    
(_____  )| (\ \) || |(_)| ||  _____)(_____  )   | |   |     __)   | |   |   _ (  |  __)   
      ) || | \   || |   | || (            ) |   | |   | (\ (      | |   |  ( \ \ | (      
/\____) || )  \  || )   ( || )      /\____) |   | |   | ) \ \_____) (___|  /  \ \| (____/\
\_______)|/    )_)|/     \||/ _____ \_______)   )_(   |/   \__/\_______/|_/    \/(_______/
                             (_____)   
EOF
echo -e "\033[0m"
echo -e "SNMP Security Assessment Toolkit v1.0"
echo -e "Created by: \033[1;32mransc0rp1on\033[0m & \033[1;32m6umi1029\033[0m"
echo "----------------------------------------------------------"


# Install dependencies
echo -e "\n[+] Installing dependencies..."
if ! apt-get update > /dev/null; then
    echo "[-] Failed to update package lists" >&2
    exit 1
fi

if ! apt-get install -y snmp snmpd snmp-mibs-downloader tcpdump gnuplot parallel nmap iputils-ping coreutils > /dev/null; then
    echo "[-] Failed to install packages" >&2
    exit 1
fi

# Configure environment
echo "[+] Configuring environment..."
mkdir -p /usr/share/snmp/mibs
if ! download-mibs > /dev/null 2>&1; then
    echo "[-] Failed to download MIBs" >&2
fi

# Create wordlists
echo "[+] Creating default wordlists..."
mkdir -p wordlists
cat > wordlists/common_communities.txt << 'EOL'
public
private
admin
snmp
manager
read
write
cisco
router
switch
network
security
monitor
guest
default
password
snmpd
snmptrap
ro
rw
EOL

# Set permissions
echo "[+] Setting permissions..."
chmod +x snmp-strike.sh
chmod -R +x core/
chmod -R +x lib/

# Create output directory
mkdir -p outputs

echo -e "\n\033[1;32m[+] Installation complete!\033[0m"
echo "  Run: ./snmp-strike.sh"
echo "  Debug mode: DEBUG=true ./snmp-strike.sh"