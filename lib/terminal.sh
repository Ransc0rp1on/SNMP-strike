#!/bin/bash
# lib/terminal.sh
# Author: ransc0rp1on

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Banner display
display_banner() {
    clear
    echo -e "${YELLOW}"
    echo "   _____ _   _ __  __ _____   _____ _   _ _______ _____ "
    echo "  / ____| \ | |  \/  |  __ \ / ____| \ | |__   __/ ____|"
    echo " | (___ |  \| | \  / | |__) | (___ |  \| |  | | | (___  "
    echo "  \___ \| . \` | |\/| |  ___/ \___ \| . \` |  | |  \___ \ "
    echo "  ____) | |\  | |  | | |     ____) | |\  |  | |  ____) |"
    echo " |_____/|_| \_|_|  |_|_|    |_____/|_| \_|  |_| |_____/ "
    echo -e "${NC}"
    echo -e "  ${BLUE}SNMP Security Assessment Toolkit v1.0${NC}"
    echo -e "  Created by: ${GREEN}ransc0rp1on${NC} & ${GREEN}6umi1029${NC}"
    echo "----------------------------------------------------------"
}

# Progress bar
progress_bar() {
    local duration=${1:-0.01}
    local columns=$(tput cols)
    local space=$((columns - 20))
    printf "["
    
    for ((i=0; i<space; i++)); do
        printf " "
    done
    
    printf "]"
    
    # Move cursor back
    for ((i=0; i<=space; i++)); do
        printf "\b"
    done
    
    # Fill progress
    for ((i=0; i<space; i++)); do
        printf "${GREEN}#${NC}"
        sleep "$duration"
    done
    echo
}

# Menu system
display_menu() {
    echo -e "\n${YELLOW}MAIN MENU${NC}"
    echo "1. Target Configuration"
    echo "2. Community String Scanner"
    echo "3. Brute-force Community String"
    echo "4. SNMP Enumeration"
    echo "5. Launch DoS Attack"
    echo "6. Vulnerability Checks"
    echo "7. Real-time Monitoring"
    echo "8. Exit"
    echo -n -e "${BLUE}Select option: ${NC}"
}

# Error messages
error_msg() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Success messages
success_msg() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Warning messages
warning_msg() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Info messages
info_msg() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Debug messages
debug_msg() {
    if [ "$DEBUG" = "true" ]; then
        echo -e "${PURPLE}[DEBUG]${NC} $1"
    fi
}

# ASCII bar chart
draw_bar_chart() {
    local value=$1
    local max=$2
    local label=$3
    local width=50  # Width of the bar in characters
    
    # Calculate percentage
    local percentage=$((value * 100 / max))
    if [ "$percentage" -gt 100 ]; then
        percentage=100
    fi
    
    # Calculate number of bars
    local bars=$((percentage * width / 100))
    
    printf "%15s: [\e[32m" "$label"
    for ((i=0; i<bars; i++)); do
        printf "#"
    done
    printf "\e[0m%*s] %d%%\n" $((width - bars)) "" "$percentage"
}

# Draw header
draw_header() {
    local title=$1
    local columns=$(tput cols)
    local title_len=${#title}
    local padding=$(((columns - title_len - 4) / 2))
    
    echo -e "\n${CYAN}"
    printf "%${columns}s\n" | tr ' ' '-'
    printf "%${padding}s %s %${padding}s\n" " " "$title" " "
    printf "%${columns}s\n" | tr ' ' '-'
    echo -e "${NC}"
}

# Confirm action
confirm_action() {
    local message=$1
    echo -n -e "${YELLOW}$message (y/n): ${NC}"
    read -r choice
    [[ "$choice" == "y" || "$choice" == "Y" ]]
    return $?
}