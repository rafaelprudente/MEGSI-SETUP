#!/bin/bash

# ======== COLORS ========
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
NC='\e[0m' # No Color

#=============== SETTINGS ===============#
ADDONS=("dns" "dashboard" "ingress" "storage" "helm" "metrics-server")

#=============== CHECK PRIVILEGES ===============#
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo."
    echo "Usage: sudo ./microk8s-addons.sh"
    exit 1
fi

#=============== INSTALL CHECK ===============#
if ! snap list | grep -q "^microk8s "; then
    echo "MicroK8s is not installed!"
    exit 1
fi

echo "Checking MicroK8s status..."
microk8s status --wait-ready >/dev/null 2>&1 || {
    echo "MicroK8s is not ready. Try rebooting first."
    exit 1
}

#=============== SPINNER FUNCTION ===============#
spinner(){
    local pid=$!
    local spin='|/-\'
    while kill -0 $pid 2>/dev/null; do
        for i in {0..3}; do
            printf "\rProcessing ${spin:$i:1}"
            sleep 0.1
        done
    done
    printf "\rDone!            \n"
}

#=============== GET SERVER IP ===============#
SERVER_IP=$(hostname -I | tr ' ' '\n' | grep '^192\.' | head -n 1)

#=============== MENU LOOP ===============#
while true; do
    clear
    echo -e "${CYAN}==============================================${NC}"
    echo -e "${GREEN}            MicroK8s Addons Manager${NC}"
    echo -e "${CYAN}==============================================${NC}"
    echo -e "${YELLOW}1${NC} - Enable individual addons"
    echo -e "${YELLOW}2${NC} - Enable ALL recommended addons"
    echo -e "${YELLOW}3${NC} - Show enabled addons"
    echo -e ""
    echo -e "${YELLOW}99${NC} - Exit"
    echo -e "${CYAN}==============================================${NC}"
    read -p "Select an option: " opt

    case $opt in
        1)
            echo
            echo "Available addons:"
            for i in "${!ADDONS[@]}"; do
                echo "[$((i+1))] ${ADDONS[$i]}"
            done
            echo "[0] Cancel"
            read -p "Enable which addon? " choice

            if [[ $choice -eq 0 ]]; then continue; fi
            index=$((choice-1))

            if [[ $index -ge 0 && $index < ${#ADDONS[@]} ]]; then
                addon=${ADDONS[$index]}
                echo "Enabling $addon..."
                microk8s enable "$addon" >/dev/null 2>&1 & spinner
                echo "✔ $addon enabled successfully!"
            else
                echo "Invalid option."
            fi
            read -p "Press ENTER to continue..."
        ;;

        2)
            echo "Enabling all addons..."
            (microk8s enable ${ADDONS[*]} >/dev/null 2>&1) & spinner

            echo "=============================================="
            echo "All addons enabled!"
            echo "=============================================="

            echo
            echo "🔗 Access Kubernetes Dashboard:"
            echo "   http://$SERVER_IP:10443"  
            echo "📌 Run inside session:"
            echo "   microk8s dashboard-proxy"
            echo
            read -p "Press ENTER to continue..."
        ;;

        3)
            echo "Enabled addons:"
            microk8s status | sed -n '/addons:/,$p'
            read -p "Press ENTER to continue..."
        ;;

        99)
            exit 0
        ;;

        *)
            echo "Invalid option!"
            sleep 1
        ;;
    esac
done
