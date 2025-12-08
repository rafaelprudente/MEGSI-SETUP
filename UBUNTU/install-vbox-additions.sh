#!/bin/bash

sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y

if ! command -v bzip2 >/dev/null 2>&1; then
    echo "Instalando bzip2..."
    sudo apt install -y bzip2
else
    echo "bzip2 já está instalado!"
fi

sudo /media/VBoxLinuxAdditions-arm64.run

