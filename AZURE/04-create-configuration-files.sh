#!/bin/bash

set -e

cd ~

sudo mkdir -p /srv/configuration-server-fs
sudo chmod 777 /srv/configuration-server-fs

rm -rf repos
mkdir -p repos
cd repos

git clone https://github.com/rafaelprudente/MEGSI-CONFIG-SERVER-DATA.git

cp MEGSI-CONFIG-SERVER-DATA/megsi-authenticator.yml /srv/configuration-server-fs/
cp MEGSI-CONFIG-SERVER-DATA/iti-service-files.yaml /srv/configuration-server-fs/

cd ~
