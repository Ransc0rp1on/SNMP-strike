#!/bin/bash
# snmp-strike.sh
# Authors: ransc0rp1on & 6umi1029
# Version: 1.0
# Last Updated: 2023-08-15

# Enable debugging mode (set to true for troubleshooting)
DEBUG=false

# Load libraries
source lib/terminal.sh
source lib/network.sh

# Configuration
TARGET=""
INTERFACE=$(get_default_interface)
WORDLIST="wordlists/common_communities.txt"
DEFAULT_WORDLIST="wordlists/common_communities.txt"
VALID_COMMUNITIES=()
ATTACK_PID=""
TCPDUMP_PID=""
ATTACK_RUNNING=false

# Dependency check
check_dependencies() {
    local missing=()
    local tools=("snmpwalk" "snmpget" "snmpset" "tcpdump" "ping" "timeout" "ip")
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        error_msg "Missing dependencies: ${missing[*]}"
        if confirm_action "Install missing packages?"; then
            echo "[+] Installing required packages..."
            sudo apt-get update > /dev/null
            sudo apt-get install -y snmp snmp-mibs-downloader tcpdump iputils-ping coreutils iproute2
            return $?
        else
            exit 1
        fi
    fi
    return 0
}

# Save valid communities to array
save_community() {
    local comm="$1"
    if [[ ! " ${VALID_COMMUNITIES[@]} " =~ " ${comm} " ]]; then
        VALID_COMMUNITIES+=("$comm")
        debug_msg "Saved community: $comm"
    fi
}

# Cleanup function
cleanup() {
    debug_msg "Cleaning up..."
    if [ -n "$ATTACK_PID" ]; then
        kill -9 "$ATTACK_PID" 2>/dev/null
    fi
    if [ -n "$TCPDUMP_PID" ]; then
        kill -9 "$TCPDUMP_PID" 2>/dev/null
    fi
    exit 0
}

# Trap CTRL+C
trap cleanup SIGINT

# Main function
main() {
    display_banner
    check_dependencies || {
        error_msg "Dependency check failed. Exiting."
        exit 1
    }
    
    # Create outputs directory if not exists
    mkdir -p outputs
    
    while true; do
        display_menu
        read -r choice
        
        case $choice in
            1)
                echo -n "Enter target IP: "
                read -r TARGET
                
                # Validate IP format
                if ! validate_ip "$TARGET"; then
                    error_msg "Invalid IP address format"
                    TARGET=""
                    continue
                fi
                
                # Check if target is alive
                if ! is_alive "$TARGET"; then
                    warning_msg "Target not responding to ping"
                    if ! confirm_action "Continue anyway?"; then
                        TARGET=""
                        continue
                    fi
                fi
                
                # Check SNMP port
                if [ -n "$TARGET" ] && ! is_snmp_open "$TARGET"; then
                    warning_msg "SNMP port (161) appears closed"
                    if ! confirm_action "Continue anyway?"; then
                        TARGET=""
                        continue
                    fi
                fi
                
                if [ -n "$TARGET" ]; then
                    success_msg "Target set to $TARGET"
                fi
                ;;
            2)
                if [ -z "$TARGET" ]; then
                    error_msg "No target configured!"
                else
                    source core/scanner.sh
                    scan_community_strings "$TARGET"
                fi
                ;;
            3)
                if [ -z "$TARGET" ]; then
                    error_msg "No target configured!"
                else
                    source core/bruteforcer.sh
                    
                    echo -n "Use default wordlist? (y/n): "
                    read -r choice
                    if [[ "$choice" == "n" ]]; then
                        echo -n "Enter custom wordlist path: "
                        read -r custom_wordlist
                        if [ ! -f "$custom_wordlist" ]; then
                            error_msg "File not found: $custom_wordlist"
                            continue
                        fi
                        WORDLIST="$custom_wordlist"
                    else
                        WORDLIST="$DEFAULT_WORDLIST"
                    fi
                    
                    echo -n "Use parallel mode? (y/n): "
                    read -r parallel_choice
                    if [[ "$parallel_choice" == "y" ]]; then
                        echo -n "Enter threads (default 10): "
                        read -r threads
                        threads=${threads:-10}
                        parallel_bruteforce "$TARGET" "$WORDLIST" "$threads"
                    else
                        brute_force_community "$TARGET" "$WORDLIST"
                    fi
                fi
                ;;
            4)
                if [ -z "$TARGET" ]; then
                    error_msg "No target configured!"
                else
                    source core/enumerator.sh
                    
                    # Get community string
                    local community=""
                    if [ ${#VALID_COMMUNITIES[@]} -gt 0 ]; then
                        echo "Select community string:"
                        for i in "${!VALID_COMMUNITIES[@]}"; do
                            echo "  $i: ${VALID_COMMUNITIES[$i]}"
                        done
                        echo -n "Enter index: "
                        read -r index
                        if [[ $index =~ ^[0-9]+$ ]] && [ "$index" -lt ${#VALID_COMMUNITIES[@]} ]; then
                            community="${VALID_COMMUNITIES[$index]}"
                        else
                            error_msg "Invalid index"
                            continue
                        fi
                    else
                        echo -n "Enter SNMP community string: "
                        read -r community
                    fi
                    
                    echo -n "SNMP version (1|2c) [default: 2c]: "
                    read -r version
                    version=${version:-"2c"}
                    
                    enumerate_snmp "$TARGET" "$community" "$version"
                fi
                ;;
            5)
                if [ -z "$TARGET" ]; then
                    error_msg "No target configured!"
                else
                    source core/attack_engine.sh
                    
                    # Get community string
                    local community=""
                    if [ ${#VALID_COMMUNITIES[@]} -gt 0 ]; then
                        echo "Select community string:"
                        for i in "${!VALID_COMMUNITIES[@]}"; do
                            echo "  $i: ${VALID_COMMUNITIES[$i]}"
                        done
                        echo -n "Enter index: "
                        read -r index
                        if [[ $index =~ ^[0-9]+$ ]] && [ "$index" -lt ${#VALID_COMMUNITIES[@]} ]; then
                            community="${VALID_COMMUNITIES[$index]}"
                        else
                            error_msg "Invalid index"
                            continue
                        fi
                    else
                        echo -n "Enter SNMP community string: "
                        read -r community
                    fi
                    
                    run_dos_attack "$TARGET" "$community"
                fi
                ;;
            6)
                if [ -z "$TARGET" ]; then
                    error_msg "No target configured!"
                else
                    source core/vulnerability.sh
                    
                    # Get community string
                    local community=""
                    if [ ${#VALID_COMMUNITIES[@]} -gt 0 ]; then
                        echo "Select community string:"
                        for i in "${!VALID_COMMUNITIES[@]}"; do
                            echo "  $i: ${VALID_COMMUNITIES[$i]}"
                        done
                        echo -n "Enter index: "
                        read -r index
                        if [[ $index =~ ^[0-9]+$ ]] && [ "$index" -lt ${#VALID_COMMUNITIES[@]} ]; then
                            community="${VALID_COMMUNITIES[$index]}"
                        else
                            error_msg "Invalid index"
                            continue
                        fi
                    else
                        echo -n "Enter SNMP community string: "
                        read -r community
                    fi
                    
                    echo -n "SNMP version (1|2c) [default: 2c]: "
                    read -r version
                    version=${version:-"2c"}
                    
                    check_snmp_vulnerabilities "$TARGET" "$community" "$version"
                fi
                ;;
            7)
                if [ -z "$TARGET" ]; then
                    error_msg "No target configured!"
                else
                    source core/monitor.sh
                    
                    echo -n "Network interface [default: $INTERFACE]: "
                    read -r custom_interface
                    local interface="${custom_interface:-$INTERFACE}"
                    
                    echo -n "Load capture file? (y/n) [default: n]: "
                    read -r load_choice
                    
                    if [ "$load_choice" = "y" ]; then
                        echo -n "Enter capture file path: "
                        read -r capture_file
                        analyze_capture "$capture_file"
                    else
                        monitor_traffic "$interface"
                    fi
                fi
                ;;
            8)
                echo "Exiting..."
                cleanup
                ;;
            *)
                error_msg "Invalid option!"
                ;;
        esac
        
        echo -e "\nPress Enter to continue..."
        read -r
    done
}

# Start main function
main