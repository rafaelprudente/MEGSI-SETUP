#!/bin/bash

# Update system
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y

# ===== Check and install packages =====
required_packages=("bzip2" "gcc" "make" "perl")

for pkg in "${required_packages[@]}"; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
        echo "Installing $pkg..."
        sudo apt install -y "$pkg"
    else
        echo "$pkg is already installed!"
    fi
done

# ===== Mount CD-ROM safely =====
echo "Mounting VirtualBox Guest Additions ISO..."

if ! mountpoint -q /media; then
    sudo mount /dev/cdrom /media 2>/dev/null

    if [[ $? -ne 0 ]]; then
        echo "ERROR: Could not mount /dev/cdrom."
        echo "Insert/Load VirtualBox Guest Additions ISO first."
        echo "VirtualBox → Devices → Insert Guest Additions CD image..."
        exit 1
    fi
else
    echo "/media is already mounted."
fi

# ===== Check VBoxLinuxAdditions file =====
VBOX_FILE="/media/VBoxLinuxAdditions-arm64.run"

if [[ -f "$VBOX_FILE" ]]; then
    echo "Running VBox Additions installer..."
    sudo chmod +x "$VBOX_FILE"
    sudo "$VBOX_FILE"
else
    echo "ERROR: VBoxLinuxAdditions-arm64.run not found in /media/"
    echo "Make sure you are using ARM version or mount correct ISO path."
    exit 1
fi

# Uncomment to auto reboot after install
# echo "Rebooting in 5 seconds..."
# sleep 5 && sudo reboot
