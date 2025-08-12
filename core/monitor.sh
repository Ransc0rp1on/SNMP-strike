#!/bin/bash
# core/monitor.sh
# Authors: ransc0rp1on & 6umi1029

source ../lib/terminal.sh

# Function to monitor live traffic
monitor_traffic() {
    local interface=$1
    
    draw_header "LIVE TRAFFIC MONITOR"
    info_msg "Monitoring interface: $interface"
    info_msg "Press Ctrl+C to stop"
    
    # Check if interface exists
    if ! ip link show "$interface" &>/dev/null; then
        error_msg "Interface $interface not found!"
        return 1
    fi
    
    # Initialize counters
    local packet_count=0
    local total_length=0
    local start_time=$SECONDS
    
    # Start live capture
    tcpdump -l -i "$interface" "udp port 161" 2>/dev/null | \
    while read -r line; do
        # Extract relevant info
        local length=$(echo "$line" | grep -oP 'length \K[0-9]+')
        
        # Update stats
        ((packet_count++))
        total_length=$((total_length + ${length:-0}))
        local elapsed=$((SECONDS - start_time))
        
        # Calculate rates
        local packet_rate=0
        local data_rate=0
        [ $elapsed -gt 0 ] && packet_rate=$((packet_count / elapsed))
        [ $elapsed -gt 0 ] && data_rate=$((total_length / elapsed))
        
        # Update screen
        clear
        draw_header "LIVE SNMP TRAFFIC"
        echo -e "  Interface: ${CYAN}$interface${NC}"
        echo -e "  Duration: ${YELLOW}${elapsed}s${NC}"
        echo "--------------------------------------------------"
        echo -e "  Total Packets: ${GREEN}$packet_count${NC}"
        echo -e "  Total Data: ${GREEN}$((total_length / 1024)) KB${NC}"
        echo -e "  Packet Rate: ${GREEN}$packet_rate packets/s${NC}"
        echo -e "  Data Rate: ${GREEN}$((data_rate / 1024)) KB/s${NC}"
        echo "--------------------------------------------------"
        echo -e "  ${YELLOW}Last Packet:${NC}"
        echo "  $line"
        
        # Draw simple bar chart for rates
        draw_bar_chart $((packet_rate > 100 ? 100 : packet_rate)) 100 "Packet Rate"
        draw_bar_chart $((data_rate > 1024 ? 100 : data_rate / 10)) 100 "Data Rate (KB/s)"
        
    done
}

# Function to analyze capture file
analyze_capture() {
    local capture_file=$1
    
    if [ ! -f "$capture_file" ]; then
        error_msg "Capture file not found: $capture_file"
        return 1
    fi
    
    draw_header "PCAP ANALYSIS"
    info_msg "File: $capture_file"
    
    # Basic stats
    local packet_count=$(tcpdump -r "$capture_file" 2>/dev/null | wc -l)
    local first_packet=$(tcpdump -r "$capture_file" -c 1 2>/dev/null)
    local last_packet=$(tcpdump -r "$capture_file" 2>/dev/null | tail -1)
    local duration=$(tcpdump -tttt -r "$capture_file" 2>/dev/null | \
        awk '{gsub(/-|:/," "); mkt=$0} END{print mkt}' | \
        xargs -I{} date -d "{}" +%s | \
        awk 'NR==1{start=$1} END{print $1-start}')
    
    # Data volume
    local total_bytes=$(tcpdump -r "$capture_file" -w /dev/null 2>&1 | \
        grep 'received by filter' | \
        awk '{print $1}')
    
    echo -e "\n${BLUE}Summary:${NC}"
    echo "Total packets: $packet_count"
    echo "Duration: ${duration}s"
    echo "Total data: $((total_bytes / 1024)) KB"
    [ $duration -gt 0 ] && echo "Avg packet rate: $((packet_count / duration)) pps"
    [ $duration -gt 0 ] && echo "Avg data rate: $((total_bytes / duration / 1024)) KB/s"
    echo "First packet: $first_packet"
    echo "Last packet: $last_packet"
    
    # Top talkers
    echo -e "\n${BLUE}Top Sources:${NC}"
    tcpdump -r "$capture_file" -nn 2>/dev/null | \
        awk '{print $3}' | \
        awk -F. '{print $1"."$2"."$3"."$4}' | \
        sort | uniq -c | sort -nr | head -5
    
    # Generate traffic graph
    if command -v gnuplot &>/dev/null; then
        info_msg "Generating traffic graph..."
        
        # Extract packet timeline
        tcpdump -tttt -r "$capture_file" 2>/dev/null | \
            awk '{print $1" "$2}' | \
            cut -d. -f1 | \
            uniq -c | \
            awk '{print $2" "$3, $1}' > traffic.dat
        
        # Create plot script
        cat > plot.gp << 'EOL'
set terminal dumb
set title "SNMP Traffic Over Time"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%H:%M"
set xlabel "Time"
set ylabel "Packets/Minute"
plot "traffic.dat" using 1:2 with lines title "SNMP Traffic"
EOL
        
        # Plot graph
        echo -e "\n${BLUE}Traffic Graph:${NC}"
        gnuplot plot.gp 2>/dev/null
        rm plot.gp traffic.dat
    else
        warning_msg "gnuplot not installed. Skipping graph generation."
    fi
}