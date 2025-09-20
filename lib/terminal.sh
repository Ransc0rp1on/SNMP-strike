#!/bin/bash
# lib/terminal.sh
# Authors: ransc0rp1on & 6umi1029
# Version: 1.1

# --- Color Codes ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# --- Main Functions ---

# Displays the tool's main banner.
display_banner()  {
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

# Displays the main menu for the tool.
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

# Displays a simple progress bar.
# Arguments:
#   $1: The current step (e.g., a loop counter).
#   $2: The total number of steps.
progress_bar() {
    local current_step=$1
    local total_steps=$2
    local duration=0.01
    
    # Check if total_steps is zero to prevent division by zero
    if [ "$total_steps" -eq 0 ]; then
        total_steps=1
    fi

    local columns=$(tput cols)
    local width=$((columns - 10))
    local filled=$((current_step * width / total_steps))
    local empty=$((width - filled))
    
    printf "\r[${GREEN}%*s${NC}%*s] %d%%" "$filled" "" "$empty" "" "$((current_step * 100 / total_steps))"
    
    # On the last step, add a newline
    if [ "$current_step" -eq "$total_steps" ]; then
        echo -e "\n"
    fi
}

# --- Message Functions ---

# Displays an error message.
error_msg() {
    echo -e "${RED}[-] ${NC}$1" >&2
}

# Displays a success message.
success_msg() {
    echo -e "${GREEN}[+] ${NC}$1"
}

# Displays a warning message.
warning_msg() {
    echo -e "${YELLOW}[!] ${NC}$1"
}

# Displays an info message.
info_msg() {
    echo -e "${CYAN}[*] ${NC}$1"
}

# Displays a debug message (only if DEBUG is true).
debug_msg() {
    if [ "$DEBUG" = "true" ]; then
        echo -e "${PURPLE}[DEBUG] ${NC}$1"
    fi
}

# --- Other Utility Functions ---

# Displays a simple ASCII bar chart.
# Arguments:
#   $1: The value to display.
#   $2: The maximum possible value for scaling.
#   $3: The label for the bar.
draw_bar_chart() {
    local value=$1
    local max=$2
    local label=$3
    local width=50 # Bar width
    
    local percentage=$((value * 100 / max))
    if [ "$percentage" -gt 100 ]; then
        percentage=100
    fi
    
    local bars=$((percentage * width / 100))
    local spaces=$((width - bars))
    
    printf "%15s: [${GREEN}%*s${NC}%*s] %d%%\n" "$label" "$bars" "" "$spaces" "" "$percentage"
}

# Draws a header with a centered title.
# Arguments:
#   $1: The title text.
draw_header() {
    local title=$1
    local columns=$(tput cols)
    local title_len=${#title}
    local padding=$(((columns - title_len - 4) / 2))
    
    echo -e "\n${CYAN}"
    printf "%${columns}s\n" | tr ' ' '='
    printf "%${padding}s %s %${padding}s\n" " " "$title" " "
    printf "%${columns}s\n" | tr ' ' '='
    echo -e "${NC}"
}

# Prompts the user for a yes/no confirmation.
# Arguments:
#   $1: The message to display.
#
# Returns:
#   0 for 'yes' or 'Y', 1 for 'no' or 'N'.
confirm_action() {
    local message=$1
    echo -n -e "${YELLOW}[?] ${NC}$message (y/n): "
    read -r choice
    [[ "$choice" =~ ^[yY]$ ]]
    return $?
}