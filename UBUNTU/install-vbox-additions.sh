#!/bin/bash

# Update system
sudo apt update -y >/dev/null 2>&1
sudo apt upgrade -y >/dev/null 2>&1
sudo apt autoremove -y >/dev/null 2>&1

# ===== Check and install packages =====
required_packages=("bzip2" "gcc" "make" "perl" "linux-headers-$(uname -r)")

for pkg in "${required_packages[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "$pkg is already installed!"
    else
        echo "Installing $pkg..."
        sudo apt install -y "$pkg"
    fi
done

echo "--------------------------------------------"
echo " Detecting system architecture..."
echo "--------------------------------------------"

# ===== Detect architecture =====
ARCH=$(uname -m)

if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    VBOX_FILE="VBoxLinuxAdditions-arm64.run"
    echo "Architecture detected: ARM64"
elif [[ "$ARCH" == "x86_64" ]]; then
    VBOX_FILE="VBoxLinuxAdditions.run"
    echo "Architecture detected: x86_64 / AMD64"
else
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
fi

echo "Installer expected: $VBOX_FILE"
echo "--------------------------------------------"
echo " Mounting Guest Additions ISO..."
echo "--------------------------------------------"

# ===== Mount CD-ROM safely =====
if ! mountpoint -q /media; then
    sudo mount /dev/cdrom /media 2>/dev/null || sudo mount /dev/sr0 /media 2>/dev/null
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to mount Guest Additions ISO!"
        echo "Insert ISO in VirtualBox:"
        echo "Devices → Insert Guest Additions CD image..."
        exit 1
    fi
else
    echo "ISO already mounted."
fi

# ===== Validate file exists =====
INSTALLER="/media/$VBOX_FILE"

echo "Checking installer file..."

if [[ -f "$INSTALLER" ]]; then
    echo "✔ Installer found!"
    echo "--------------------------------------------"
    echo " Running VirtualBox Guest Additions..."
    echo "--------------------------------------------"
    sudo chmod +x "$INSTALLER"
    sudo "$INSTALLER"
else
    echo "❌ File '$VBOX_FILE' not found in /media/"
    echo "Check if the ISO matches your CPU architecture."
    echo ""
    echo "Fix:"
    echo "Devices → Insert Guest Additions CD image..."
    exit 1
fi

echo "--------------------------------------------"
echo " Installation complete. Reboot recommended."
echo "--------------------------------------------"

# sudo reboot
