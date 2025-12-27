#!/bin/bash

set -e

echo "Criando rede de para os containers..."

docker network create megsi-net

echo "Subindo os containers definidos em compose.yaml..."

docker compose -f compose.yaml up -d

echo "Aguardando o MariaDB iniciar..."

sleep 15

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

git clone https://github.com/rafaelprudente/MEGSI-CONFIG-SERVER-DATA.git
git clone https://github.com/rafaelprudente/MEGSI-AUTENTICADOR.git
git clone https://github.com/rafaelprudente/MEGSI-ITI-SERVICE-FILES.git

echo "Copiando arquivos de configuração para /srv/configuration-server-fs..."

cp MEGSI-CONFIG-SERVER-DATA/megsi-authenticator.yml /srv/configuration-server-fs/
cp MEGSI-CONFIG-SERVER-DATA/iti-service-files.yaml /srv/configuration-server-fs/

echo "Processo concluído com sucesso."