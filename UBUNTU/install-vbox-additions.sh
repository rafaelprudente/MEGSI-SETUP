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

if ! command -v gcc >/dev/null 2>&1; then
    echo "Instalando gcc..."
    sudo apt install -y gcc
else
    echo "gcc já está instalado!"
fi

if ! command -v make >/dev/null 2>&1; then
    echo "Instalando make..."
    sudo apt install -y make
else
    echo "make já está instalado!"
fi

if ! command -v perl >/dev/null 2>&1; then
    echo "Instalando perl..."
    sudo apt install -y perl
else
    echo "perl já está instalado!"
fi

sudo /media/VBoxLinuxAdditions-arm64.run

#sudo reboot