
# SNMP-strike - SNMP Security Assessment Toolkit
```
  
  _____ _   _ __  __ _____   _____ _______ _____  _____ _  ________ 
 / ____| \ | |  \/  |  __ \ / ____|__   __|  __ \|_   _| |/ /  ____|
| (___ |  \| | \  / | |__) | (___    | |  | |__) | | | | ' /| |__   
 \___ \| . ` | |\/| |  ___/ \___ \   | |  |  _  /  | | |  < |  __|  
 ____) | |\  | |  | | |     ____) |  | |  | | \ \ _| |_| . \| |____ 
|_____/|_| \_|_|  |_|_|    |_____/   |_|  |_|  \_\_____|_|\_\______|
                     ______                                         
                    |______|                                        
```

SNMP-strike is a comprehensive security assessment toolkit designed for testing SNMP (Simple Network Management Protocol) implementations. It provides various tools for scanning, enumeration, and testing the security of SNMP-enabled devices.

## Features

- **Community String Scanner**: Scan for default and common SNMP community strings  
- **DoS Attack Engine**: Perform denial-of-service attacks against vulnerable SNMP implementations  
- **Traffic Visualization**: Real-time packet capture and visualization during attacks  
- **Cross-Platform Support**: Works on both Debian/Ubuntu and Arch-based systems  
- **User-Friendly Interface**: Interactive menu-driven interface for easy operation  

## Installation

### Prerequisites

- Python 3.x  
- Net-SNMP tools  
- tcpdump  
- nmap  
- gnuplot  
- parallel  

### Automated Installation

Clone the repository:

```bash
git clone https://github.com/yourusername/SNMP-strike.git
cd SNMP-strike
````

Run the installation script:

```bash
chmod +x install.sh
sudo ./install.sh
```

The installation script will:

* Detect your operating system (Debian/Ubuntu or Arch-based)
* Install all required dependencies
* Set up the necessary directory structure
* Configure SNMP MIBs properly

### Manual Installation

**For Debian/Ubuntu systems:**

```bash
sudo apt update
sudo apt install snmp snmpd snmp-mibs-downloader nmap tcpdump gnuplot parallel iputils-ping coreutils
pip3 install pysnmp
```

**For Arch-based systems:**

```bash
sudo pacman -Syu
sudo pacman -S net-snmp nmap tcpdump gnuplot parallel iputils coreutils
pip3 install pysnmp
```

## Usage

### Basic Usage

Start the tool:

```bash
sudo ./snmp-strike.sh
```

Follow the interactive menu to:

* Scan for SNMP devices
* Test community strings
* Launch DoS attacks
* View attack statistics

### Command Line Options

For advanced users, you can run specific modules directly:

```bash
# Scan for community strings
./core/scanner.sh <target_ip>

# Run DoS attack
./core/attack_engine.sh <target_ip> <community_string>
```

### Examples

**Scanning a target for default community strings:**

1. Select option 1 from the main menu
2. Enter target IP: `192.168.1.100`

**Launching a DoS attack:**

1. Select option 2 from the main menu
2. Enter target IP: `192.168.1.100`
3. Enter community string: `public`
4. Configure attack parameters as prompted

**Using debug mode:**

```bash
DEBUG=true ./snmp-strike.sh
```

## Modules

### Scanner Module

* Detects SNMP-enabled devices
* Tests for default community strings
* Identifies vulnerable configurations

### Attack Engine

* Launches SNMP flood attacks
* Supports amplification attacks
* Real-time traffic visualization
* Adjustable thread count and duration

### Network Utilities

* Host discovery
* Port scanning
* Traffic analysis

## Configuration

The tool uses several configuration files:

* `wordlists/common_communities.txt` - Default community strings to test
* `lib/terminal.sh` - Terminal color and formatting settings
* `lib/network.sh` - Network utility functions

## Troubleshooting

### Common Issues

* **Permission denied errors:**
  Run the tool with sudo: `sudo ./snmp-strike.sh`

* **SNMP tools not found:**
  Run the installation script again: `sudo ./install.sh`

* **No traffic visualization:**
  Install a terminal emulator:

  * Debian/Ubuntu: `sudo apt install xterm`
  * Arch: `sudo pacman -S xterm`

* **Interface not found:**
  Specify the correct interface or use `any` to capture on all interfaces

### Debug Mode

Enable debug mode for detailed output:

```bash
DEBUG=true ./snmp-strike.sh
```


