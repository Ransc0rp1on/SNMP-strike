#!/bin/bash
# lib/network.sh
# Author: ransc0rp1on

# Validate IP address format
validate_ip() {
    local ip=$1
    local stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octets <<< "$ip"
        [[ ${octets[0]} -le 255 && ${octets[1]} -le 255 && \
           ${octets[2]} -le 255 && ${octets[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# Check if target is alive
is_alive() {
    local target=$1
    ping -c 1 -W 1 "$target" >/dev/null 2>&1
    return $?
}

# Check if SNMP port (161) is open
is_snmp_open() {
    local target=$1
    timeout 1 bash -c "echo > /dev/udp/$target/161" >/dev/null 2>&1
    return $?
}

# Get default network interface
get_default_interface() {
    ip route | awk '/default/ {print $5; exit}'
}

# Validate CIDR range
validate_cidr() {
    local cidr=$1
    [[ "$cidr" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]] || return 1
    ipcalc -c "$cidr" >/dev/null 2>&1
    return $?
}

# Get IP address from interface
get_interface_ip() {
    local interface=$1
    ip -4 addr show "$interface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
}

# Check port availability
check_port() {
    local port=$1
    ss -tuln | grep -q ":$port "
    return $?
}