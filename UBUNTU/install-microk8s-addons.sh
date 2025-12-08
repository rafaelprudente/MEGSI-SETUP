#!/bin/bash

# ======== COLORS ========
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
NC='\e[0m'

#=============== SETTINGS ===============#
ADDONS=("dns" "dashboard" "ingress" "storage" "helm" "metrics-server")

# Must be run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo."
    echo "Usage: sudo ./install-microk8s-addons.sh"
    exit 1
fi

#=============== MICROK8S CHECK ===============#
if ! snap list | grep -q "^microk8s "; then
    echo -e "${RED}MicroK8s not installed!${NC}"
    exit 1
fi

microk8s status --wait-ready || { echo -e "${RED}MicroK8s not ready.${NC}"; exit 1; }

#=============== GET SERVER IP ===============#
SERVER_IP=$(hostname -I | tr ' ' '\n' | grep '^192\.' | head -n 1)
SCRIPT_DIR="$(pwd)"
INFO_FILE="$SCRIPT_DIR/microk8s-dashboard.info"

echo
echo -e "${CYAN}Enabling Kubernetes Dashboard (Legacy)...${NC}"

microk8s enable dns

microk8s enable rbac

# Remove SA e RB antigas (evita conflito e recria apenas uma vez)
microk8s kubectl delete serviceaccount admin-user -n kube-system --ignore-not-found
microk8s kubectl delete clusterrolebinding admin-user-binding --ignore-not-found

# Cria usuario admin cluster-wide
microk8s kubectl create serviceaccount admin-user -n kube-system
microk8s kubectl create clusterrolebinding admin-user-binding \
    --clusterrole=cluster-admin --serviceaccount=kube-system:admin-user

microk8s enable dashboard
echo -e "${GREEN}✔ Dashboard enabled${NC}"

echo -e "${YELLOW}Waiting for dashboard pod to start...${NC}"
for i in {1..30}; do
    POD=$(microk8s kubectl -n kube-system get pods | grep -E "dashboard|kubernetes-dashboard" | awk '{print $1}')
    [[ -n "$POD" ]] && break
    sleep 3
done

if [[ -z "$POD" ]]; then
    echo -e "${RED}Dashboard pod not found!${NC}"
    exit 1
fi

echo -e "${GREEN}✔ Pod detected: $POD${NC}\n"

# Token
TOKEN=$(microk8s kubectl -n kube-system get secret \
    $(microk8s kubectl -n kube-system get secret | grep admin-user | awk '{print $1}') \
    -o jsonpath="{.data.token}" | base64 --decode)

# Firewall
if command -v ufw &>/dev/null; then
    ufw allow 10443/tcp
    echo -e "${GREEN}✔ Port 10443 opened in firewall${NC}"
fi

# Save access info
echo "URL: https://$SERVER_IP:10443" > "$INFO_FILE"
echo "TOKEN:" >> "$INFO_FILE"
echo "$TOKEN" >> "$INFO_FILE"

echo -e "\n${GREEN}Dashboard Ready${NC}"
echo -e "Open in browser: ${CYAN}https://$SERVER_IP:10443${NC}"
echo -e "\nTOKEN:\n${YELLOW}$TOKEN${NC}"
echo -e "Saved in: ${YELLOW}$INFO_FILE${NC}\n"

echo -e "${CYAN}Starting dashboard-proxy... (CTRL+C to exit)${NC}"
microk8s dashboard-proxy

exit 0
