#!/bin/bash
# snmp-strike.sh
# Authors: ransc0rp1on & 6umi1029
# Version: 1.1
# Last Updated: 2025-09-21

# Enable debugging mode
DEBUG=false

# Load libraries from the 'lib' directory
source lib/terminal.sh
source lib/network.sh

# Configuration
TARGET=""
# Get default interface and handle potential issues
INTERFACE=$(get_default_interface) || INTERFACE="eth0"
WORDLIST="wordlists/common_communities.txt"
DEFAULT_WORDLIST="wordlists/common_communities.txt"
VALID_COMMUNITIES=()
ATTACK_PID=""
TCPDUMP_PID=""
ATTACK_RUNNING=false

# Function to check for required tools
check_dependencies() {
    local missing=()
    # Use a common set of tools that should be available on both Debian and Arch
    local tools=("snmpwalk" "snmpget" "snmpset" "tcpdump" "ping" "timeout" "parallel" "nmap" "ip")
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        error_msg "Missing dependencies: ${missing[*]}"
        warning_msg "Please run ./install.sh to install missing packages."
        return 1
    fi
    success_msg "All required dependencies are installed."
    return 0
}

# Function to save a valid community string to an array
save_community() {
    local comm="$1"
    # Check if the community string is already in the array before adding
    local exists=0
    for c in "${VALID_COMMUNITIES[@]}"; do
        if [[ "$c" == "$comm" ]]; then
            exists=1
            break
        fi
    done
    if [ $exists -eq 0 ]; then
        VALID_COMMUNITIES+=("$comm")
        debug_msg "Saved community: $comm"
    fi
}

# Function for cleanup on exit or interrupt
cleanup() {
    debug_msg "Cleaning up..."
    if [ -n "$ATTACK_PID" ]; then
        kill "$ATTACK_PID" 2>/dev/null
        debug_msg "Killed attack process (PID: $ATTACK_PID)."
    fi
    if [ -n "$TCPDUMP_PID" ]; then
        sudo kill "$TCPDUMP_PID" 2>/dev/null
        debug_msg "Killed tcpdump process (PID: $TCPDUMP_PID)."
    fi
    exit 0
}

# Trap CTRL+C and call the cleanup function
trap cleanup SIGINT

# Main function of the tool
main() {
    display_banner
    
    # Check dependencies at the start and exit if not found
    check_dependencies || exit 1
    
    # Create outputs directory if it doesn't exist
    mkdir -p outputs
    
    while true; do
        display_menu
        read -r choice
        
        case $choice in
            1)
                echo -n "Enter target IP: "
                read -r TARGET
                
                if ! validate_ip "$TARGET"; then
                    error_msg "Invalid IP address format."
                    TARGET=""
                    continue
                fi
                
                # Check if target is alive and has SNMP port open
                if ! is_alive "$TARGET"; then
                    warning_msg "Target not responding to ping."
                    if ! confirm_action "Continue anyway?"; then
                        TARGET=""
                        continue
                    fi
                fi
                
                if [ -n "$TARGET" ] && ! is_snmp_open "$TARGET"; then
                    warning_msg "SNMP port (161/udp) appears closed."
                    if ! confirm_action "Continue anyway?"; then
                        TARGET=""
                        continue
                    fi
                fi
                
                if [ -n "$TARGET" ]; then
                    success_msg "Target set to $TARGET."
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
                    
                    echo -n "Use default wordlist? (y/n) [default: y]: "
                    read -r choice
                    if [[ "$choice" =~ ^[nN]$ ]]; then
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
                    
                    brute_force_community "$TARGET" "$WORDLIST"
                fi
                ;;
            4)
                if [ -z "$TARGET" ]; then
                    error_msg "No target configured!"
                else
                    source core/enumerator.sh
                    
                    local community=""
                    if [ ${#VALID_COMMUNITIES[@]} -gt 0 ]; then
                        echo "Select community string:"
                        for i in "${!VALID_COMMUNITIES[@]}"; do
                            echo "  $i: ${VALID_COMMUNITIES[$i]}"
                        done
                        echo -n "Enter index or community string: "
                        read -r input_community
                        if [[ $input_community =~ ^[0-9]+$ ]] && [ "$input_community" -lt ${#VALID_COMMUNITIES[@]} ]; then
                            community="${VALID_COMMUNITIES[$input_community]}"
                        else
                            community="$input_community"
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
                    
                    local community=""
                    if [ ${#VALID_COMMUNITIES[@]} -gt 0 ]; then
                        echo "Select community string:"
                        for i in "${!VALID_COMMUNITIES[@]}"; do
                            echo "  $i: ${VALID_COMMUNITIES[$i]}"
                        done
                        echo -n "Enter index or community string: "
                        read -r input_community
                        if [[ $input_community =~ ^[0-9]+$ ]] && [ "$input_community" -lt ${#VALID_COMMUNITIES[@]} ]; then
                            community="${VALID_COMMUNITIES[$input_community]}"
                        else
                            community="$input_community"
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
                    
                    local community=""
                    if [ ${#VALID_COMMUNITIES[@]} -gt 0 ]; then
                        echo "Select community string:"
                        for i in "${!VALID_COMMUNITIES[@]}"; do
                            echo "  $i: ${VALID_COMMUNITIES[$i]}"
                        done
                        echo -n "Enter index or community string: "
                        read -r input_community
                        if [[ $input_community =~ ^[0-9]+$ ]] && [ "$input_community" -lt ${#VALID_COMMUNITIES[@]} ]; then
                            community="${VALID_COMMUNITIES[$input_community]}"
                        else
                            community="$input_community"
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