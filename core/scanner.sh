#!/bin/bash
# core/scanner.sh
# Author: ransc0rp1on

source ../lib/terminal.sh
source ../lib/network.sh

scan_community_strings() {
    local target=$1
    local default_strings=("public" "private" "manager" "admin" "snmp" "cisco" "read" "write" "monitor" "guest")
    local vulnerable=0
    local found_strings=()
    
    draw_header "SNMP COMMUNITY SCANNER"
    info_msg "Target: $target"
    echo -e "\n${BLUE}[+] Checking if SNMP service is running...${NC}"
    
    # Check if target is reachable first
    if ! check_host_alive "$target"; then
        error_msg "Target $target is not reachable!"
        return 2
    fi
    
    # Check if SNMP UDP port is open using a different method
    if ! check_snmp_service "$target"; then
        warning_msg "SNMP service may not be running or is filtered"
        echo -e "  ${YELLOW}Note:${NC} SNMP uses UDP port 161, which may not show in regular TCP scans"
        if ! confirm_action "Continue with community string testing anyway?"; then
            return 2
        fi
    fi
    
    echo -e "\n${BLUE}[+] Scanning for default community strings${NC}"
    
    for string in "${default_strings[@]}"; do
        echo -ne "  Testing: $string\r"
        
        # Try SNMPv2c first
        if timeout 2 snmpwalk -v2c -c "$string" "$target" .1.3.6.1.2.1.1.1.0 2>/dev/null | head -1 >/dev/null 2>&1; then
            if [[ " ${default_strings[@]} " =~ " ${string} " ]]; then
                echo -e "  ${RED}VULNERABLE${NC}: Found default string '${string}' (SNMPv2c)"
                vulnerable=1
                found_strings+=("$string (v2c)")
            else
                echo -e "  ${GREEN}Found${NC}: '${string}' (SNMPv2c)"
                found_strings+=("$string (v2c)")
            fi
        # Try SNMPv1 if v2c fails
        elif timeout 2 snmpwalk -v1 -c "$string" "$target" .1.3.6.1.2.1.1.1.0 2>/dev/null | head -1 >/dev/null 2>&1; then
            if [[ " ${default_strings[@]} " =~ " ${string} " ]]; then
                echo -e "  ${RED}VULNERABLE${NC}: Found default string '${string}' (SNMPv1)"
                vulnerable=1
                found_strings+=("$string (v1)")
            else
                echo -e "  ${GREEN}Found${NC}: '${string}' (SNMPv1)"
                found_strings+=("$string (v1)")
            fi
        fi
    done
    
    echo -e "\n--------------------------------------------"
    
    # Display results
    if [ ${#found_strings[@]} -gt 0 ]; then
        echo -e "${YELLOW}[+] Found community strings:${NC}"
        for str in "${found_strings[@]}"; do
            echo "  - $str"
        done
    else
        echo -e "${YELLOW}[!] No community strings found with default list${NC}"
    fi
    
    if [ "$vulnerable" -eq 1 ]; then
        warning_msg "Default community strings found!"
        echo "    This system is vulnerable to DoS attacks and information disclosure"
        
        # Ask user if they want to proceed with attack
        echo
        if confirm_action "Do you want to launch an attack against this target?"; then
            return 0  # Vulnerable and user wants to attack
        else
            info_msg "Returning to main menu..."
            return 1  # Vulnerable but user doesn't want to attack
        fi
    else
        if [ ${#found_strings[@]} -gt 0 ]; then
            success_msg "No default community strings detected, but some were found"
        else
            info_msg "No community strings found with default list"
        fi
        info_msg "You might want to try brute-forcing with a wordlist"
        return 2  # Not vulnerable or no strings found
    fi
}

# Function to check if host is alive
check_host_alive() {
    local target=$1
    ping -c 1 -W 1 "$target" >/dev/null 2>&1
    return $?
}

# Function to check if SNMP service is running
check_snmp_service() {
    local target=$1
    
    # Try multiple methods to check if SNMP is running
    
    # Method 1: Use nmap for UDP scan (if available and sudo)
    if command -v nmap >/dev/null 2>&1 && [ "$(id -u)" -eq 0 ]; then
        if nmap -sU -p 161 --open "$target" 2>/dev/null | grep -q "161/udp.*open"; then
            return 0
        fi
    fi
    
    # Method 2: Use netcat for UDP check
    if command -v nc >/dev/null 2>&1; then
        # Send a packet and see if we get any response
        echo "" | nc -u -w 1 "$target" 161 2>/dev/null && return 0
    fi
    
    # Method 3: Try a simple SNMP request
    if timeout 2 snmpget -v2c -c public "$target" .1.3.6.1.2.1.1.1.0 >/dev/null 2>&1; then
        return 0
    fi
    
    # If all methods fail, assume service might not be running
    return 1
}

# Example usage:
# scan_community_strings "192.168.1.100"
# case $? in
#   0) echo "Vulnerable and user wants to attack" ;;
#   1) echo "Vulnerable but user wants to return to menu" ;;
#   2) echo "Not vulnerable" ;;
# esac