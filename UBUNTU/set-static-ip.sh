#!/bin/bash

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo."
    echo "Usage: sudo ./set-static-ip.sh"
    exit 1
fi

# Function to validate IPv4 format
validate_ip() {
    local ip=$1
    local regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"

    if [[ ! $ip =~ $regex ]]; then return 1; fi

    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if (( octet < 0 || octet > 255 )); then return 1; fi
    done
    return 0
}

# Request IP input
while true; do
    read -p "Enter static IP address (IPv4): " IP
    if validate_ip "$IP"; then
        echo "Valid IP: $IP"
        break
    else
        echo "Invalid IP format! Example: 192.168.1.100"
    fi
done

echo "Configuring Netplan with IP: $IP..."

# Generate netplan config
cat > /etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s8:
      dhcp4: no
      addresses: [$IP/24]
EOF

echo "Applying Netplan..."
netplan apply

echo "---------------------------------------------"
echo "Static IP successfully configured!"
echo "New IP address: $IP"
echo "---------------------------------------------"

# Confirm reboot
echo ""
echo "⚠ IMPORTANT NOTICE!"
echo "After reboot you will lose this terminal connection."
echo "You must reconnect to the server using the new IP:"
echo "→ ssh user@$IP"
echo "or access through your new network configuration."
echo ""

read -p "Do you want to reboot now? (y/n): " answer

if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Rebooting in 3 seconds..."
    sleep 3
    reboot
else
    echo "Reboot canceled."
    echo "Note: The new IP will only take effect after reboot."
fi
