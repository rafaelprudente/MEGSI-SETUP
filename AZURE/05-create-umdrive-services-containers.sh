#!/bin/bash

set -e

sudo apt install openjdk-21-jdk -y

sudo rm -rf repos
mkdir -p repos
cd repos

git clone https://github.com/rafaelprudente/MEGSI-CONFIG-SERVER-FS.git
git clone https://github.com/rafaelprudente/MEGSI-AUTENTICADOR.git
git clone https://github.com/rafaelprudente/MEGSI-ITI-SERVICE-FILES.git
git clone https://github.com/rafaelprudente/MEGSI-ITI-AUTOSCALER.git
git clone https://github.com/rafaelprudente/MEGSI-ITI-FRONTEND.git

cd MEGSI-CONFIG-SERVER-FS
mvn clean package
sudo docker build -t "rafaelrpsantos/megsi-config-server-fs:latest" .
cd ..

cd MEGSI-AUTENTICADOR
mvn clean package
sudo docker build -t "rafaelrpsantos/megsi-autenticator:latest" .
cd ..

cd MEGSI-ITI-SERVICE-FILES
mvn clean package
sudo docker build -t "rafaelrpsantos/megsi-iti-service-files:latest" .
cd ..

cd MEGSI-ITI-AUTOSCALER
sudo docker build -t "rafaelrpsantos/megsi-iti-autoscaler:latest" .
cd ..

cd MEGSI-ITI-FRONTEND
sudo docker build -t umdrive-frontend .
cd ..

cd ~

sudo docker compose -f compose-umdrive.yml up -d
