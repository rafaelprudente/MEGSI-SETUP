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
    echo "Usage: sudo /.install-microk8s-addons.sh"
    exit 1
fi

#=============== MICROK8S CHECK ===============#
if ! snap list | grep -q "^microk8s "; then
    echo "MicroK8s not installed!"
    exit 1
fi

microk8s status --wait-ready >/dev/null 2>&1 || { echo "MicroK8s not ready."; exit 1; }

#=============== GET SERVER IP ===============#
SERVER_IP=$(hostname -I | tr ' ' '\n' | grep '^192\.' | head -n 1)

#=============== TOKEN FUNCTION ===============#
dashboard_token() {
    echo
    echo -e "${YELLOW}Generating access token...${NC}"
    TOKEN=$(microk8s kubectl -n kube-system get secret \
        $(microk8s kubectl -n kube-system get secret | grep admin-user | awk '{print $1}') \
        -o jsonpath="{.data.token}" | base64 --decode)

    echo -e "${GREEN}TOKEN:${NC}"
    echo "$TOKEN"
    echo
    echo -e "Access UI using:\n${CYAN}microk8s dashboard-proxy${NC}"
    echo "Open browser:"
    echo -e "${CYAN}http://$SERVER_IP:10443${NC}"
    echo
    read -p "Press ENTER to continue..."
}

#=============== SPINNER ===============#
spinner(){
    local pid=$!
    local spin='|/-\'
    while kill -0 $pid 2>/dev/null; do
        for i in {0..3}; do printf "\rProcessing ${spin:$i:1}"; sleep 0.1; done
    done
    printf "\rDone!        \n"
}

#=============== MENU ===============#
while true; do
    clear
    echo -e "${CYAN}==============================================${NC}"
    echo -e "${GREEN}            MicroK8s Addons Manager${NC}"
    echo -e "${CYAN}==============================================${NC}"
    echo -e "${YELLOW}1${NC} - Enable addons (multiple select)"
    echo -e "${YELLOW}2${NC} - Enable ALL recommended addons"
    echo -e "${YELLOW}3${NC} - Show enabled addons"
    echo ""
    echo -e "${YELLOW}99${NC} - Exit"
    echo -e "${CYAN}==============================================${NC}"
    read -p "Select: " opt

    case $opt in
        1)
            echo
            enabled=($(microk8s status --format short | grep enabled | awk '{print $1}'))
            disabled=()

            for addon in "${ADDONS[@]}"; do
                [[ " ${enabled[*]} " =~ " $addon " ]] || disabled+=("$addon")
            done

            if [[ ${#disabled[@]} -eq 0 ]]; then
                echo -e "${GREEN}All addons already enabled.${NC}"
                read -p "ENTER..."
                continue
            fi

            echo -e "${CYAN}Select addons (space separated)${NC}"
            for i in "${!disabled[@]}"; do
                echo -e "${YELLOW}$((i+1))${NC} - ${disabled[$i]}"
            done
            echo -e "${YELLOW}99${NC} Cancel"
            echo
            read -p "Enable addons: " -a choices

            [[ "${choices[*]}" =~ 99 ]] && continue

            for c in "${choices[@]}"; do
                idx=$((c-1))
                if [[ $idx -ge 0 && $idx < ${#disabled[@]} ]]; then
                    addon=${disabled[$idx]}
                    echo "Enabling $addon..."
                    microk8s enable "$addon" >/dev/null 2>&1 & spinner

                    [[ "$addon" == "dashboard" ]] && DASH=1
                fi
            done

            echo -e "${GREEN}Selected addons enabled.${NC}"
            [[ "$DASH" == "1" ]] && dashboard_token
        ;;

        2)
            echo "Enabling all..."
            (microk8s enable ${ADDONS[*]} >/dev/null 2>&1) & spinner
            dashboard_token
        ;;

        3)
            echo -e "${CYAN}Enabled:${NC}"
            microk8s status | sed -n '/addons:/,$p'
            read -p "ENTER..."
        ;;

        99) exit 0 ;;
        *) echo -e "${RED}Invalid option"; sleep 1 ;;
    esac
done
