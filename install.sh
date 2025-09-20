#!/bin/bash

# --- Color Codes ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Variables ---
REQUIRED_DEPS_DEB=("snmp" "snmpd" "snmp-mibs-downloader" "nmap" "tcpdump" "gnuplot" "parallel" "iputils-ping" "coreutils")
REQUIRED_DEPS_ARCH=("net-snmp" "nmap" "tcpdump" "gnuplot" "parallel" "iputils" "coreutils") # Note: iputils and coreutils are usually pre-installed
REQUIRED_PYTHON_DEPS=("pysnmp")
WORDLIST_PATH="./wordlists/common_communities.txt"

# --- Functions ---

# Function to display a formatted banner
show_banner()  {
  echo -e "\033[1;34m"
  cat <<'EOF'
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
}

# Function to detect the OS and set the package manager
detect_os() {
    echo -e "${CYAN}[*] Detecting operating system...${NC}"
    
    # Check for Arch Linux specifically
    if [ -f /etc/arch-release ]; then
        echo "-> Arch Linux based system detected."
        PKG_MANAGER="pacman"
        DEPENDENCIES=("${REQUIRED_DEPS_ARCH[@]}")
        return
    fi
    
    # Check for other distributions
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "debian" || "$ID" == "ubuntu" || "$ID_LIKE" == *"debian"* ]]; then
            echo "-> Debian/Ubuntu based system detected."
            PKG_MANAGER="apt"
            DEPENDENCIES=("${REQUIRED_DEPS_DEB[@]}")
        elif [[ "$ID" == "arch" || "$ID" == "manjaro" || "$ID_LIKE" == *"arch"* ]]; then
            echo "-> Arch Linux based system detected."
            PKG_MANAGER="pacman"
            DEPENDENCIES=("${REQUIRED_DEPS_ARCH[@]}")
        else
            echo -e "${RED}[-] Unsupported operating system: $ID${NC}"
            exit 1
        fi
    else
        echo -e "${RED}[-] Cannot detect operating system. Exiting.${NC}"
        exit 1
    fi
}

# Function to check and install dependencies
install_dependencies() {
    echo -e "${CYAN}[*] Checking for dependencies...${NC}"
    
    # Update package lists
    if [ "$PKG_MANAGER" == "apt" ]; then
        sudo apt-get update >/dev/null
    elif [ "$PKG_MANAGER" == "pacman" ]; then
        sudo pacman -Sy --noconfirm >/dev/null 2>&1
    fi
    
    for dep in "${DEPENDENCIES[@]}"; do
        # Skip coreutils as it's always installed on both systems
        if [ "$dep" == "coreutils" ]; then
            echo -e "-> ${GREEN}coreutils${NC} is already installed (system essential)."
            continue
        fi
        
        # Check if package is installed
        local installed=false
        
        if [ "$PKG_MANAGER" == "apt" ]; then
            if dpkg -l | grep -q "^ii.*$dep"; then
                installed=true
            fi
        elif [ "$PKG_MANAGER" == "pacman" ]; then
            if pacman -Qi "$dep" >/dev/null 2>&1; then
                installed=true
            fi
        fi
        
        if [ "$installed" = false ]; then
            echo -e "-> ${YELLOW}$dep${NC} is not installed. Installing..."
            if [ "$PKG_MANAGER" == "apt" ]; then
                sudo apt-get install -y "$dep"
            elif [ "$PKG_MANAGER" == "pacman" ]; then
                sudo pacman -S --noconfirm "$dep"
            fi
            if [ $? -ne 0 ]; then
                echo -e "${RED}[-] Failed to install $dep. Please install manually.${NC}"
                exit 1
            else
                echo -e "-> ${GREEN}$dep${NC} installed successfully."
            fi
        else
            echo -e "-> ${GREEN}$dep${NC} is already installed."
        fi
    done

    # Handle MIBs configuration for different OSes
    if [ "$PKG_MANAGER" == "apt" ]; then
        echo -e "${CYAN}[*] Configuring SNMP MIBs for Debian/Ubuntu...${NC}"
        if command -v download-mibs &> /dev/null; then
            sudo download-mibs
        else
            echo -e "${YELLOW}[!] download-mibs not available, skipping MIB configuration${NC}"
        fi
    elif [ "$PKG_MANAGER" == "pacman" ]; then
        echo -e "${CYAN}[*] Configuring SNMP MIBs for Arch Linux...${NC}"
        # Arch uses a different location and config
        if [ -f /etc/snmp/snmp.conf ]; then
            sudo sed -i 's/^#mibs/mibs/' /etc/snmp/snmp.conf 2>/dev/null
            echo "mibdirs /usr/share/snmp/mibs" | sudo tee -a /etc/snmp/snmp.conf > /dev/null
        else
            echo -e "${YELLOW}[!] /etc/snmp/snmp.conf not found, creating it${NC}"
            echo "mibdirs /usr/share/snmp/mibs" | sudo tee /etc/snmp/snmp.conf > /dev/null
        fi
        echo "-> Please note: You may need to restart your terminal or source /etc/snmp/snmp.conf for MIB changes to take effect."
    fi

    # Install Python dependencies
    if ! command -v pip3 &> /dev/null; then
        echo -e "${YELLOW}[!] pip3 is not installed. Installing python-pip...${NC}"
        if [ "$PKG_MANAGER" == "apt" ]; then
            sudo apt-get install -y python3-pip
        elif [ "$PKG_MANAGER" == "pacman" ]; then
            sudo pacman -S --noconfirm python-pip
        fi
    fi
    
    echo -e "${CYAN}[*] Installing Python dependencies...${NC}"
    for pydep in "${REQUIRED_PYTHON_DEPS[@]}"; do
        if ! python3 -c "import $pydep" &> /dev/null; then
            echo -e "-> Installing ${YELLOW}$pydep${NC}..."
            pip3 install "$pydep"
        else
            echo -e "-> ${GREEN}$pydep${NC} is already installed."
        fi
    done
}

# --- Main Script Execution ---

# Check for root/sudo access
if [[ $(id -u) -ne 0 ]]; then
    echo -e "${YELLOW}[*] This script requires sudo to install packages. Please enter your password when prompted.${NC}"
fi

show_banner
detect_os
install_dependencies

# Create necessary directories and set permissions
echo -e "${CYAN}[*] Setting up directory structure and permissions...${NC}"
mkdir -p outputs
mkdir -p wordlists

# It's a good practice to use the wordlist from inside the wordlists directory
if [ ! -f "$WORDLIST_PATH" ]; then
    cat > "$WORDLIST_PATH" << 'EOL'
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
    echo -e "-> Created default community wordlist."
fi

chmod +x snmp-strike.sh
chmod -R +x core/ lib/

echo -e "${GREEN}\n[+] Installation complete!${NC}"
echo -e "    Run the tool using: ${YELLOW}./snmp-strike.sh${NC}"
echo -e "    For debug mode: ${YELLOW}DEBUG=true ./snmp-strike.sh${NC}"