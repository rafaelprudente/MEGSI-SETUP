#!/bin/bash

set -e

sudo apt install maven -y

cd ~

MARIADB_CONTAINER="mariadb"
MARIADB_USER="root"
MARIADB_PASSWORD="uminho"

sudo docker exec -i "$MARIADB_CONTAINER" mariadb \
  -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" <<EOF
CREATE DATABASE IF NOT EXISTS MEGSI;
CREATE DATABASE IF NOT EXISTS ITI;
EOF

rm -rf repos
mkdir -p repos
cd repos

git clone https://github.com/rafaelprudente/MEGSI-AUTENTICADOR.git
git clone https://github.com/rafaelprudente/MEGSI-ITI-SERVICE-FILES.git

cd ~/repos/MEGSI-AUTENTICADOR

mvn flyway:migrate -Dflyway.url=jdbc:mariadb://localhost:3306/MEGSI -Dflyway.user=$MARIADB_USER -Dflyway.password=$MARIADB_PASSWORD

cd ~/repos/MEGSI-ITI-SERVICE-FILES

mvn flyway:migrate -Dflyway.url=jdbc:mariadb://localhost:3306/ITI -Dflyway.user=$MARIADB_USER -Dflyway.password=$MARIADB_PASSWORD

cd ~