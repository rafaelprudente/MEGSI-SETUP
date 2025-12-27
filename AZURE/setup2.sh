#!/bin/bash

set -e

sudo apt install maven -y
sudo apt install openjdk-21-jdk -y

echo "Adicionando o user $USER ao grupo docker..."

sudo usermod -aG docker $USER

echo "Criando rede de para os containers..."

if ! docker network inspect megsi-net >/dev/null 2>&1; then
  docker network create megsi-net
fi

echo "Subindo os containers definidos em compose.yml..."

NEEDED=false

docker inspect mariadb >/dev/null 2>&1 || NEEDED=true
docker inspect kafka   >/dev/null 2>&1 || NEEDED=true

$NEEDED && docker compose -f compose.yml up -d

echo "Aguardando o MariaDB iniciar..."

sleep 60

echo "Criando bancos de dados MEGSI e ITI no MariaDB..."

MARIADB_CONTAINER="mariadb"
MARIADB_USER="root"
MARIADB_PASSWORD="uminho"

docker exec -i "$MARIADB_CONTAINER" mariadb \
  -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" <<EOF
CREATE DATABASE IF NOT EXISTS MEGSI;
CREATE DATABASE IF NOT EXISTS ITI;
EOF

echo "Criando diretório /srv/configuration-server-fs com permissões abertas..."

sudo mkdir -p /srv/configuration-server-fs
sudo chmod 777 /srv/configuration-server-fs

echo "Clonando repositórios..."

WORKDIR="$(pwd)/repos"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

sudo rm -rf repos

git clone https://github.com/rafaelprudente/MEGSI-CONFIG-SERVER-DATA.git
git clone https://github.com/rafaelprudente/MEGSI-AUTENTICADOR.git
git clone https://github.com/rafaelprudente/MEGSI-ITI-SERVICE-FILES.git
git clone https://github.com/rafaelprudente/MEGSI-ITI-AUTOSCALER.git
git clone https://github.com/rafaelprudente/MEGSI-CONFIG-SERVER-FS.git

echo "Copiando arquivos de configuração para /srv/configuration-server-fs..."

cp MEGSI-CONFIG-SERVER-DATA/megsi-authenticator.yml /srv/configuration-server-fs/
cp MEGSI-CONFIG-SERVER-DATA/iti-service-files.yaml /srv/configuration-server-fs/

echo "Executando as migrations..."

cd /home/azureuser/repos/MEGSI-AUTENTICADOR

mvn flyway:migrate -Dflyway.url=jdbc:mariadb://localhost:3306/MEGSI -Dflyway.user=root -Dflyway.password=uminho

cd /home/azureuser/repos/MEGSI-ITI-SERVICE-FILES

mvn flyway:migrate -Dflyway.url=jdbc:mariadb://localhost:3306/MEGSI -Dflyway.user=root -Dflyway.password=uminho

cd /home/azureuser

echo "Gerando imagens..."

cd /home/azureuser/repos/MEGSI-AUTENTICADOR
mvn clean package
sudo docker rmi rafaelrpsantos/megsi-autenticator:latest
sudo docker build -t "rafaelrpsantos/megsi-autenticator:latest" .

cd /home/azureuser/repos/MEGSI-ITI-SERVICE-FILES
mvn clean package
sudo docker rmi rafaelrpsantos/megsi-iti-service-files:latest
sudo docker build -t "rafaelrpsantos/megsi-iti-service-files:latest" .

cd /home/azureuser/repos/MEGSI-ITI-AUTOSCALER
sudo docker rmi rafaelrpsantos/megsi-iti-autoscaler:latest
sudo docker build -t "rafaelrpsantos/megsi-iti-autoscaler:latest" .

cd /home/azureuser/repos/MEGSI-CONFIG-SERVER-FS
mvn clean package
sudo docker rmi rafaelrpsantos/megsi-config-server-fs:latest
sudo docker build -t "rafaelrpsantos/megsi-config-server-fs:latest" .

clear

cd ~

echo "Subindo os containers definidos em compose-umdrive.yml..."

sudo docker compose -f compose-umdrive.yml up -d

echo "Processo concluído com sucesso."