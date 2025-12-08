#!/bin/bash

# Must be run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo."
    echo "Usage: sudo ./install-microk8s.sh"
    exit 1
fi

USER_NAME=${SUDO_USER:-$USER}

# ===== Check if MicroK8s is already installed =====
if snap list | grep -q "^microk8s "; then
    echo "=============================================="
    echo "MicroK8s is already installed on this system!"
    echo "=============================================="
    exit 0
fi

echo "Updating system (silent mode)..."
apt update -y
apt upgrade -y
apt autoremove -y

# Install required packages
required_packages=("ufw" "nano" "snapd")
for pkg in "${required_packages[@]}"; do
    if dpkg -s "$pkg"; then
        echo "$pkg is already installed!"
    else
        echo "Installing $pkg..."
        apt install -y "$pkg"
    fi
done

echo "Installing MicroK8s..."
snap install microk8s --classic --channel=1.33

# Permissions
usermod -aG microk8s "$USER_NAME"
mkdir -p /home/"$USER_NAME"/.kube
chmod 700 /home/"$USER_NAME"/.kube

echo
echo "=============================================="
echo "MicroK8s installed successfully!"
echo "You MUST logout or reboot for group changes."
echo "=============================================="
echo
echo "⚠ IMPORTANT:"
echo "After reboot your SSH terminal session will drop."
echo "Reconnect and run addons script."
echo

read -p "Reboot now? (y/n): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    reboot
else
    echo "Reboot canceled. Run manually later to finish setup."
fi
