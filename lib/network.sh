#!/bin/bash
# lib/network.sh
# Authors: ransc0rp1on & 6umi1029
# Version: 1.1

# 
# Function to validate an IPv4 address format.
#
# Arguments:
#   $1: The IP address to validate.
#
# Returns:
#   0 on success (valid IP), 1 on failure (invalid IP).
#
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octets <<< "$ip"
        if (( ${octets[0]} <= 255 && ${octets[1]} <= 255 && \
              ${octets[2]} <= 255 && ${octets[3]} <= 255 )); then
            return 0
        fi
    fi
    return 1
}

# 
# Function to check if a host is alive using ping.
#
# Arguments:
#   $1: The target IP address.
#
# Returns:
#   0 if the host is reachable, 1 otherwise.
#
is_alive() {
    local target=$1
    # Use ping with a single packet and a short timeout
    ping -c 1 -W 1 "$target" >/dev/null 2>&1
    return $?
}

# 
# Function to check if the SNMP port (161/udp) is open on a target.
#
# Arguments:
#   $1: The target IP address.
#
# Returns:
#   0 if the port is open, 1 otherwise.
#
is_snmp_open() {
    local target=$1
    # Nmap is a more reliable and cross-platform way to check open ports
    # A quick UDP scan on port 161
    nmap -sU -p 161 "$target" | grep -q "161/udp open"
    return $?
}

# 
# Function to get the default network interface.
#
# Returns:
#   The name of the default interface (e.g., eth0, wlan0).
#
get_default_interface() {
    # Using 'ip route get' is a more reliable and direct method
    ip route get 8.8.8.8 | awk '{print $5; exit}'
}

# 
# Function to validate a CIDR notation.
#
# Arguments:
#   $1: The CIDR string to validate.
#
# Returns:
#   0 on success (valid CIDR), 1 on failure.
#
validate_cidr() {
    local cidr=$1
    if [[ ! "$cidr" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        return 1
    fi
    # Use 'ipcalc' which is a standard tool on many Linux distros.
    # We check if it is available and use it to validate the CIDR.
    if command -v ipcalc &>/dev/null; then
        ipcalc -c "$cidr" >/dev/null 2>&1
        return $?
    else
        # Fallback to a simpler regex-based check if ipcalc is not present
        local ip part mask
        IFS='/' read -r ip mask <<< "$cidr"
        
        # Check if mask is valid (0-32)
        if (( mask < 0 || mask > 32 )); then
            return 1
        fi
        
        # Check if the IP part is valid
        validate_ip "$ip"
        return $?
    fi
}

# 
# Function to get the IPv4 address of a specified interface.
#
# Arguments:
#   $1: The name of the network interface.
#
# Returns:
#   The IP address or nothing if the interface is not found or has no IP.
#
get_interface_ip() {
    local interface=$1
    ip -4 addr show "$interface" | awk '/inet / {print $2}' | cut -d'/' -f1
}

# 
# Function to check if a specific port is in use.
#
# Arguments:
#   $1: The port number to check.
#
# Returns:
#   0 if the port is in use, 1 otherwise.
#
check_port() {
    local port=$1
    # Use 'ss' for efficiency. It is the modern replacement for 'netstat'.
    ss -tuln | grep -q ":$port "
    return $?
}