#!/bin/bash

# Must be run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo."
    echo "Usage: sudo ./install-microk8s.sh"
    exit 1
fi

# Update system quietly
apt update -y >/dev/null 2>&1
apt upgrade -y >/dev/null 2>&1
apt autoremove -y >/dev/null 2>&1

# ===== Check and install packages =====
required_packages=("ufw" "nano" "snapd")

for pkg in "${required_packages[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "$pkg is already installed!"
    else
        echo "Installing $pkg..."
        apt install -y "$pkg"
    fi
done

echo "Installing MicroK8s..."
snap install microk8s --classic --channel=1.33

usermod -aG microk8s $SUDO_USER
mkdir -p /home/$SUDO_USER/.kube
chmod 700 /home/$SUDO_USER/.kube

echo
echo "=============================================="
echo "MicroK8s installed successfully!"
echo "You must logout or reboot for group changes."
echo "=============================================="
echo "After reboot, run:"
echo "   microk8s status"
echo "   microk8s enable dns dashboard ingress"
echo "=============================================="
echo

read -p "Reboot now? (y/n): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Rebooting in 3 seconds..."
    sleep 3
    reboot
else
    echo "Reboot canceled. Please reboot manually later."
fi
