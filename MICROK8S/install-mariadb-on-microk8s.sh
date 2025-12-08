#!/bin/bash

sudo curl -# -L -o "mariadb.yaml" "https://raw.githubusercontent.com/rafaelprudente/MEGSI-SETUP/main/MICROK8S/mariadb.yaml"

microk8s kubectl apply -f mariadb.yaml

microk8s kubectl port-forward svc/mariadb 3306:30306

microk8s kubectl get pods
