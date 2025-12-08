#!/bin/bash

sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y

# ===== Check and install packages =====
if ! command -v bzip2 >/dev/null 2>&1; then
    echo "Installing bzip2..."
    sudo apt install -y bzip2
else
    echo "bzip2 is already installed!"
fi

if ! command -v gcc >/dev/null 2>&1; then
    echo "Installing gcc..."
    sudo apt install -y gcc
else
    echo "gcc is already installed!"
fi

if ! command -v make >/dev/null 2>&1; then
    echo "Installing make..."
    sudo apt install -y make
else
    echo "make is already installed!"
fi

if ! command -v perl >/dev/null 2>&1; then
    echo "Installing perl..."
    sudo apt install -y perl
else
    echo "perl is already installed!"
fi


# ===== Check VBoxLinuxAdditions file =====
VBOX_FILE="/media/VBoxLinuxAdditions-arm64.run"

if [[ -f "$VBOX_FILE" ]]; then
    echo "Running VBox Additions installer..."
    sudo "$VBOX_FILE"
else
    echo "ERROR: VBoxLinuxAdditions-arm64.run not found in /media/"
    echo "Insert the VirtualBox Guest Additions ISO and try again."
    exit 1
fi

# sudo reboot
