#!/bin/bash
# core/enumerator.sh
# Authors: ransc0rp1on & 6umi1029

source ../lib/terminal.sh

# Function to enumerate SNMP
enumerate_snmp() {
    local target=$1
    local community=$2
    local version=$3
    local output_file="outputs/enum_${target}_$(date +%s).txt"
    
    draw_header "SNMP ENUMERATION"
    info_msg "Target: $target | Community: $community"
    info_msg "Output: $output_file"
    
    # Common MIBs to query
    local mibs=(
        "system"        # System info
        "interfaces"    # Network interfaces
        "at"            # ARP table
        "ip"            # IP info
        "icmp"          # ICMP stats
        "tcp"           # TCP connections
        "udp"           # UDP endpoints
        "snmp"          # SNMP stats
        "hrStorage"     # Storage info
        "hrSWRun"       # Running processes
        "hrSWInstalled" # Installed software
        "dot1dBridge"   # Bridge info
        "dot1dTp"       # Transparent bridging
        "ipNetToMedia"  # IP to MAC mapping
        "lldp"          # LLDP neighbors
    )
    
    # Start enumeration
    echo "SNMP Enumeration Report" > "$output_file"
    echo "Target: $target" >> "$output_file"
    echo "Community: $community" >> "$output_file"
    echo "Version: $version" >> "$output_file"
    echo "Started: $(date)" >> "$output_file"
    echo "==========================================" >> "$output_file"
    
    for mib in "${mibs[@]}"; do
        echo -e "\n${BLUE}[+] Enumerating $mib${NC}"
        echo -e "\n===== $mib =====" >> "$output_file"
        
        snmpwalk -v "$version" -c "$community" "$target" "$mib" >> "$output_file" 2>/dev/null
        
        # Check if we got any results
        if [ $? -ne 0 ]; then
            echo "  No data found for $mib" | tee -a "$output_file"
        else
            echo "  Retrieved $mib data" | tee -a "$output_file"
        fi
    done
    
    # Try to extract specific useful info
    echo -e "\n${BLUE}[+] Extracting key information${NC}"
    extract_key_info "$output_file"
    
    echo "==========================================" >> "$output_file"
    echo "Completed: $(date)" >> "$output_file"
    
    success_msg "Enumeration completed"
    info_msg "Full report saved to: $output_file"
}

# Function to extract key information
extract_key_info() {
    local file=$1
    local summary="outputs/summary_$(date +%s).txt"
    
    # System info
    echo -e "\n${YELLOW}=== SYSTEM INFORMATION ===${NC}" | tee "$summary"
    grep -E 'sysDescr|sysName|sysLocation|sysContact|sysUpTime' "$file" | tee -a "$summary"
    
    # Network interfaces
    echo -e "\n${YELLOW}=== NETWORK INTERFACES ===${NC}" | tee -a "$summary"
    grep -A 1 'ifDescr' "$file" | grep -E 'ifDescr|ifPhysAddress|ifAdminStatus|ifOperStatus' | tee -a "$summary"
    
    # ARP table
    echo -e "\n${YELLOW}=== ARP TABLE ===${NC}" | tee -a "$summary"
    grep 'ipNetToMediaPhysAddress' "$file" | tee -a "$summary"
    
    # Running processes
    echo -e "\n${YELLOW}=== RUNNING PROCESSES ===${NC}" | tee -a "$summary"
    grep 'hrSWRunName' "$file" | tee -a "$summary"
    
    # Installed software
    echo -e "\n${YELLOW}=== INSTALLED SOFTWARE ===${NC}" | tee -a "$summary"
    grep 'hrSWInstalledName' "$file" | tee -a "$summary"
    
    # Storage info
    echo -e "\n${YELLOW}=== STORAGE INFORMATION ===${NC}" | tee -a "$summary"
    grep 'hrStorageDescr' "$file" | tee -a "$summary"
    
    info_msg "Summary saved to: $summary"
}

# Function to test write access
test_write_access() {
    local target=$1
    local community=$2
    local version=$3
    
    draw_header "WRITE ACCESS TEST"
    info_msg "Target: $target | Community: $community"
    
    # Test with sysContact
    local test_value="snmp-strike_test_$(date +%s)"
    local oid=".1.3.6.1.2.1.1.4.0"
    
    echo -e "\n${BLUE}[+] Testing write access${NC}"
    echo "  Using OID: sysContact.0 ($oid)"
    echo "  Setting value: $test_value"
    
    # Try to set value
    snmpset -v "$version" -c "$community" "$target" "$oid" s "$test_value" >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        # Verify the change
        local result=$(snmpget -v "$version" -c "$community" "$target" "$oid" 2>/dev/null)
        
        if echo "$result" | grep -q "$test_value"; then
            warning_msg "WRITE ACCESS CONFIRMED!"
            echo "  System is vulnerable to configuration changes"
            return 0
        fi
    fi
    
    success_msg "No write access detected"
    return 1
}