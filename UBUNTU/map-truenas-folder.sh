#!/bin/bash

sudo apt install -y nfs-common

sudo mkdir /mnt/NAS

sudo mount -t nfs 192.168.56.103:/mnt/Pool001 /mnt/NAS