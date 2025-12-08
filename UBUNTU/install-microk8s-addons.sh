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
    echo "MicroK8s not installed!"
    exit 1
fi

microk8s status --wait-ready >/dev/null 2>&1 || { echo "MicroK8s not ready."; exit 1; }

#=============== GET SERVER IP ===============#
SERVER_IP=$(hostname -I | tr ' ' '\n' | grep '^192\.' | head -n 1)

#=============== SPINNER ===============#
spinner(){
    local pid=$!
    local spin='|/-\'
    while kill -0 $pid 2>/dev/null; do
        for i in {0..3}; do printf "\rProcessing ${spin:$i:1}"; sleep 0.1; done
    done
    printf "\rDone!      \n"
}

#=============== Legacy Dashboard Function ===============#
enable_legacy_dashboard(){
    SCRIPT_DIR="$(pwd)"
    INFO_FILE="$SCRIPT_DIR/microk8s-dashboard.info"

    echo
    echo -e "${CYAN}Enabling Kubernetes Dashboard (Legacy - via Proxy)...${NC}"

    microk8s enable dashboard >/dev/null 2>&1 & spinner
    echo -e "${GREEN}✔ Dashboard enabled${NC}"

    echo -e "${YELLOW}Waiting for dashboard pod to start...${NC}"

    # Aguarda pod subir
    for i in {1..30}; do
        POD=$(microk8s kubectl -n kube-system get pods | grep dashboard | awk '{print $1}')
        [[ -n "$POD" ]] && break
        sleep 3
    done

    if [[ -z "$POD" ]]; then
        echo -e "${RED}Dashboard pod not found!${NC}"
        read -p "ENTER..."
        return
    fi

    echo -e "${GREEN}✔ Pod detected: $POD${NC}\n"

    # Cria Service Account caso não exista
    if ! microk8s kubectl -n kube-system get sa | grep -q admin-user; then
        microk8s kubectl create serviceaccount admin-user -n kube-system >/dev/null 2>&1
        microk8s kubectl create clusterrolebinding admin-user-binding \
            --clusterrole=cluster-admin --serviceaccount=kube-system:admin-user >/dev/null 2>&1
    fi

    # Token
    TOKEN=$(microk8s kubectl -n kube-system get secret \
        $(microk8s kubectl -n kube-system get secret | grep admin-user | awk '{print $1}') \
        -o jsonpath="{.data.token}" | base64 --decode)

    # Firewall
    if command -v ufw >/dev/null 2>&1; then
        ufw allow 10443/tcp >/dev/null 2>&1
        echo -e "${GREEN}✔ Port 10443 opened in firewall${NC}"
    fi

    # Save info
    echo "URL: https://$SERVER_IP:10443" > "$INFO_FILE"
    echo "TOKEN:" >> "$INFO_FILE"
    echo "$TOKEN" >> "$INFO_FILE"

    echo -e "\n${GREEN}Dashboard Ready${NC}"
    echo -e "Open in browser: ${CYAN}https://$SERVER_IP:10443${NC}"
    echo -e "\nTOKEN:\n${YELLOW}$TOKEN${NC}"
    echo -e "Saved in: ${YELLOW}$INFO_FILE${NC}\n"

    echo -e "${CYAN}Starting dashboard-proxy... (CTRL+C to exit)${NC}"
    microk8s dashboard-proxy

    read -p "ENTER to return..."
}

#============== SHOW STATUS ==============#
show_status(){
    echo
    echo -e "${CYAN}Addon Status:${NC}"
    enabled=($(microk8s status --format short | grep enabled | awk '{print $1}'))

    for addon in "${ADDONS[@]}"; do
        if [[ " ${enabled[*]} " =~ " $addon " ]]; then
            echo -e "  ${GREEN}✔${NC} $addon"
        else
            echo -e "  ${RED}✖${NC} $addon"
        fi
    done
    echo
}

#=============== MENU ===============#
while true; do
    clear
    echo -e "${CYAN}==============================================${NC}"
    echo -e "${GREEN}            MicroK8s Addons Manager${NC}"
    echo -e "${CYAN}==============================================${NC}"
    show_status
    echo -e "${YELLOW}1${NC} - Enable addons (multiple select)"
    echo -e "${YELLOW}2${NC} - Enable ALL recommended addons"
    echo -e "${YELLOW}3${NC} - Show enabled addons (raw output)"
    echo -e "${YELLOW}4${NC} - Disable addons (multiple select)"
    echo ""
    echo -e "${YELLOW}99${NC} - Exit"
    echo -e "${CYAN}==============================================${NC}"
    read -p "Choose an option: " opt

    case "$opt" in
        1)
            echo
            enabled=($(microk8s status --format short | grep enabled | awk '{print $1}'))
            disabled=()
            for addon in "${ADDONS[@]}"; do [[ " ${enabled[*]} " =~ " $addon " ]] || disabled+=("$addon"); done
            [[ ${#disabled[@]} == 0 ]] && echo -e "${GREEN}All addons enabled.${NC}" && read -p "ENTER..." && continue

            echo -e "${CYAN}Select addons (space separated)${NC}"
            for i in "${!disabled[@]}"; do echo -e "${YELLOW}$((i+1))${NC} - ${disabled[$i]}"; done
            echo -e "\n${YELLOW}99${NC} - Cancel"
            read -p "Choose: " -a choices
            [[ "${choices[*]}" =~ 99 ]] && continue

            for c in "${choices[@]}"; do
                idx=$((c-1))
                if [[ $idx -ge 0 && $idx < ${#disabled[@]} ]]; then
                    addon=${disabled[$idx]}
                    microk8s enable "$addon" >/dev/null 2>&1 & spinner
                    [[ "$addon" == "dashboard" ]] && enable_legacy_dashboard
                fi
            done
        ;;

        2)
            echo "Enabling all addons..."
            (microk8s enable ${ADDONS[*]} >/dev/null 2>&1) & spinner
            enable_legacy_dashboard
        ;;

        3)
            microk8s status | sed -n '/addons:/,$p'
            read -p "ENTER..."
        ;;

        4)
            enabled=($(microk8s status --format short | grep enabled | awk '{print $1}'))
            [[ ${#enabled[@]} == 0 ]] && echo -e "${RED}Nothing to disable.${NC}" && read -p "ENTER..." && continue

            echo -e "${YELLOW}Select addons to disable:${NC}"
            for i in "${!enabled[@]}"; do echo -e "${YELLOW}$((i+1))${NC} - ${enabled[$i]}"; done
            echo -e "${YELLOW}99${NC} - Cancel"
            read -p "Disable: " -a choices
            [[ "${choices[*]}" =~ 99 ]] && continue

            for c in "${choices[@]}"; do
                idx=$((c-1))
                if [[ $idx -ge 0 && $idx < ${#enabled[@]} ]]; then
                    addon=${enabled[$idx]}
                    microk8s disable "$addon" >/dev/null 2>&1 & spinner
                fi
            done
            read -p "ENTER..."
        ;;

        99) exit 0 ;;
        *) echo -e "${RED}Invalid${NC}" && sleep 1 ;;
    esac
done
