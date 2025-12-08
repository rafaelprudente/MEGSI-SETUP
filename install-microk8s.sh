#!/bin/bash

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo."
    echo "Usage: sudo ./install-microk8s.sh"
    exit 1
fi

# Update system
sudo apt update -y >/dev/null 2>&1
sudo apt upgrade -y >/dev/null 2>&1
sudo apt autoremove -y >/dev/null 2>&1

# ===== Check and install packages =====
required_packages=("ufw nano snap")

for pkg in "${required_packages[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "$pkg is already installed!"
    else
        echo "Installing $pkg..."
        sudo apt install -y "$pkg"
    fi
done

sudo snap install microk8s --classic --channel=1.33

sudo usermod -aG microk8s $USER
mkdir -p ~/.kube
chmod 0700 ~/.kube

su - $USER