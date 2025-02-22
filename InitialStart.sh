#!/bin/bash

# This script automates the process of scanning a network for vulnerable services 
# and attempting basic exploitation techniques if any vulnerabilities are found.
# It starts by ensuring that it is run with root privileges, as certain network 
# scanning and attack tools require administrative access.
#
# Then, it installs the necessary tools, including nmap for network scanning, 
# gobuster for directory brute-forcing (though not used in this script), 
# smbclient for SMB enumeration, ftp for interacting with FTP servers, 
# and redis-tools for interacting with Redis databases.
#
# After installation, the script prompts the user to enter a target IP address 
# and then uses nmap to scan for open ports and detect vulnerabilities 
# on common services like FTP (port 21), SMB (ports 139 and 445), and Redis (port 6379). 
#
# If FTP is found open, the script attempts an anonymous login and lists files. 
# If SMB is open, it tries to list shared folders without authentication using smbclient. 
# If Redis is accessible, it executes the INFO command to gather database details, 
# which can reveal sensitive information.
#
# The results of all these scans and attempts are printed for further analysis, 
# making the script useful for ethical hackers and penetration testers conducting 
# network reconnaissance and vulnerability assessments.

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Install required tools
echo "[+] Installing required tools..."
apt update -y # Update package list
apt install -y nmap gobuster smbclient ftp redis-tools # Install necessary tools

# Prompt user for the target IP address
read -p "Enter target IP address: " TARGET_IP

# Perform an nmap scan on the target IP to check for open ports and vulnerabilities
echo "[+] Scanning target $TARGET_IP..."
nmap -sV -p 21,139,445,6379 --script=vuln $TARGET_IP > scan_results.txt

# Notify user that vulnerability scanning has completed
echo "[+] Checking for vulnerable services..."

# Check if FTP (port 21) is open
if grep -q "21/tcp open" scan_results.txt; then
    echo "[+] FTP is open! Trying anonymous login..."
    ftp -n $TARGET_IP <<END_SCRIPT
    user anonymous ""  # Attempt login with anonymous user (no password)
    ls  # List directory contents
    bye  # Exit FTP session
END_SCRIPT
fi

# Check if SMB (ports 139 or 445) is open
if grep -q "139/tcp open\|445/tcp open" scan_results.txt; then
    echo "[+] SMB is open! Trying to list shared folders..."
    smbclient -L //$TARGET_IP -N  # List available shares without authentication
fi

# Check if Redis (port 6379) is open
if grep -q "6379/tcp open" scan_results.txt; then
    echo "[+] Redis is open! Trying to retrieve database info..."
    redis-cli -h $TARGET_IP INFO  # Execute Redis INFO command to fetch database details
fi

# Notify user that the scanning and attack process is complete
echo "[+] Scan and attack attempts completed."
