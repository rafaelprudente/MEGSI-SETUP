#!/bin/bash

sudo echo -e "network:" > /etc/netplan/01-netcfg.yaml
sudo echo -e "  version: 2" >> /etc/netplan/01-netcfg.yaml
sudo echo -e "  renderer: networkd" >> /etc/netplan/01-netcfg.yaml
sudo echo -e "  ethernets:" >> /etc/netplan/01-netcfg.yaml
sudo echo -e "    enp0s8:" >> /etc/netplan/01-netcfg.yaml
sudo echo -e "      dhcp4: no" >> /etc/netplan/01-netcfg.yaml
sudo echo -e "      addresses: [$1/24]" >> /etc/netplan/01-netcfg.yaml