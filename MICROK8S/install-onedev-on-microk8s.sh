#!/bin/bash

# Adiciona repo
microk8s helm3 repo add onedev https://code.onedev.io/onedev/~helm
microk8s helm3 repo update

microk8s helm3 install onedev onedev/onedev -n onedev --create-namespace \
  --set database.external=true \
  --set database.type=mysql \
  --set database.host=mariadb.default.svc.cluster.local \
  --set database.port=3306 \
  --set database.name=onedev \
  --set database.user=root \
  --set database.password=uminho

# Acesso local ao OneDev
microk8s kubectl port-forward --namespace onedev svc/onedev 6610:80
