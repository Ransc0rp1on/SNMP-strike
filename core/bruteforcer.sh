#!/bin/bash
# core/bruteforcer.sh
# Author: 6umi1029

source ../lib/terminal.sh

brute_force_community() {
    local target=$1
    local wordlist=$2
    local found=0
    local count=0
    local total=0
    
    draw_header "SNMP BRUTE-FORCE"
    info_msg "Target: $target"
    
    # Check if wordlist exists
    if [ ! -f "$wordlist" ]; then
        error_msg "Wordlist file not found: $wordlist"
        return 1
    fi
    
    # Get total lines
    total=$(wc -l < "$wordlist" 2>/dev/null)
    if [ -z "$total" ] || [ "$total" -eq 0 ]; then
        error_msg "Wordlist is empty or invalid"
        return 1
    fi
    
    echo -e "${BLUE}[+] Starting community string brute-force${NC}"
    echo "  Wordlist: $wordlist ($total entries)"
    echo "--------------------------------------------"
    
    # Create output file
    valid_file="valid_communities_$(date +%s).txt"
    > "$valid_file"
    
    while IFS= read -r community || [ -n "$community" ]; do
        ((count++))
        progress=$((count * 100 / total))
        printf "\rTesting: %-20s [%3d%%]" "$community" "$progress"
        
        # Skip empty lines
        if [ -z "$community" ]; then
            continue
        fi
        
        # Test SNMPv2c
        if snmpwalk -v2c -c "$community" "$target" .1.3.6.1.2.1.1.1.0 >/dev/null 2>&1; then
            found=1
            printf "\n  ${GREEN}VALID${NC}: %s (SNMPv2c)\n" "$community"
            echo "$community" >> "$valid_file"
        # Test SNMPv1
        elif snmpwalk -v1 -c "$community" "$target" .1.3.6.1.2.1.1.1.0 >/dev/null 2>&1; then
            found=1
            printf "\n  ${GREEN}VALID${NC}: %s (SNMPv1)\n" "$community"
            echo "$community" >> "$valid_file"
        fi
        
    done < "$wordlist"
    
    echo -e "\n--------------------------------------------"
    if [ "$found" -eq 0 ]; then
        error_msg "No valid community strings found"
        return 1
    else
        success_msg "Found valid community strings!"
        echo "  Saved to: $valid_file"
        return 0
    fi
}

# Parallel brute-force version (experimental)
parallel_bruteforce() {
    local target=$1
    local wordlist=$2
    local threads=${3:-10}
    
    draw_header "PARALLEL BRUTE-FORCE"
    info_msg "Threads: $threads | Target: $target"
    
    # Create output file
    valid_file="valid_communities_$(date +%s).txt"
    > "$valid_file"
    
    # Run parallel brute-force
    xargs -P "$threads" -I {} sh -c "
        community={}
        if snmpwalk -v2c -c \"\$community\" \"$target\" .1.3.6.1.2.1.1.1.0 >/dev/null 2>&1; then
            echo \"\$community (SNMPv2c)\" >> \"$valid_file\"
        elif snmpwalk -v1 -c \"\$community\" \"$target\" .1.3.6.1.2.1.1.1.0 >/dev/null 2>&1; then
            echo \"\$community (SNMPv1)\" >> \"$valid_file\"
        fi" < "$wordlist"
    
    # Check results
    if [ -s "$valid_file" ]; then
        success_msg "Found valid community strings!"
        echo "  Results:"
        cat "$valid_file"
        return 0
    else
        error_msg "No valid community strings found"
        return 1
    fi
}