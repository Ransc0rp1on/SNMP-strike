#!/bin/bash
# core/scanner.sh
# Author: ransc0rp1on

source ../lib/terminal.sh
source ../lib/network.sh

scan_community_strings() {
    local target=$1
    local default_strings=("public" "private" "manager" "admin" "snmp" "cisco")
    local vulnerable=0
    
    draw_header "SNMP COMMUNITY SCANNER"
    info_msg "Target: $target"
    echo -e "\n${BLUE}[+] Scanning for default community strings${NC}"
    
    for string in "${default_strings[@]}"; do
        # Try SNMPv2c first
        if snmpwalk -v2c -c "$string" "$target" .1.3.6.1.2.1.1.1.0 >/dev/null 2>&1; then
            if [[ " ${default_strings[@]} " =~ " ${string} " ]]; then
                echo -e "  ${RED}VULNERABLE${NC}: Found default string '${string}' (SNMPv2c)"
                vulnerable=1
            else
                echo -e "  ${GREEN}Found${NC}: '${string}' (SNMPv2c)"
            fi
        # Try SNMPv1 if v2c fails
        elif snmpwalk -v1 -c "$string" "$target" .1.3.6.1.2.1.1.1.0 >/dev/null 2>&1; then
            if [[ " ${default_strings[@]} " =~ " ${string} " ]]; then
                echo -e "  ${RED}VULNERABLE${NC}: Found default string '${string}' (SNMPv1)"
                vulnerable=1
            else
                echo -e "  ${GREEN}Found${NC}: '${string}' (SNMPv1)"
            fi
        fi
    done
    
    echo -e "\n--------------------------------------------"
    if [ "$vulnerable" -eq 1 ]; then
        warning_msg "Default community strings found!"
        echo "    This system is vulnerable to DoS attacks and information disclosure"
    else
        success_msg "No default community strings detected"
    fi
    
    return $vulnerable
}

# Example usage:
# scan_community_strings "192.168.1.100"