#!/bin/bash

set -e

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

sudo usermod -aG docker $USER

sudo apt install cifs-utils -y

echo "Storage account: $STORAGE_ACCOUNT_NAME"
echo "File share: $FILE_SHARE_NAME"
echo "Mount point: $NAS_MOUNT_POINT"

mkdir -p "$NAS_MOUNT_POINT"

grep -q "$NAS_MOUNT_POINT cifs" /etc/fstab || echo "//${STORAGE_ACCOUNT_NAME}.file.core.windows.net/${FILE_SHARE_NAME} \
${NAS_MOUNT_POINT} cifs \
vers=3.0,username=${STORAGE_ACCOUNT_NAME},password=${STORAGE_ACCOUNT_KEY},serverino,nofail,_netdev,dir_mode=0777,file_mode=0777 \
0 0" >> /etc/fstab

mount -a

sudo mkdir -p /etc/prometheus

curl -L \
  https://raw.githubusercontent.com/rafaelprudente/MEGSI-SETUP/main/AZURE/setup2.sh \
  -o /home/azureuser/setup2.sh
curl -L \
  https://raw.githubusercontent.com/rafaelprudente/MEGSI-SETUP/main/AZURE/compose-infra.yml \
  -o /home/azureuser/compose-infra.yml
curl -L \
  https://raw.githubusercontent.com/rafaelprudente/MEGSI-SETUP/main/AZURE/compose-umdrive.yml \
  -o /home/azureuser/compose-umdrive.yml
curl -L \
  https://raw.githubusercontent.com/rafaelprudente/MEGSI-SETUP/main/AZURE/prometheus.yml \
  -o /etc/prometheus/prometheus.yml

chown azureuser:azureuser /home/azureuser/setup2.sh
chown azureuser:azureuser /home/azureuser/compose.yml
chown azureuser:azureuser /home/azureuser/compose-umdrive.yml
chmod +x /home/azureuser/setup2.sh
sudo chmod 777 /etc/prometheus/prometheus.yml
