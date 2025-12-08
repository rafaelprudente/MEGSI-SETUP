#!/bin/bash

# ======== COLORS ========
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
NC='\e[0m'

#=============== SETTINGS ===============#
ADDONS=("dns" "dashboard" "ingress" "storage" "helm" "metrics-server")
INFO_FILE="$HOME/microk8s-dashboard.info"

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

#=============== TOKEN FUNCTION ===============#
dashboard_token(){
    echo
    echo -e "${YELLOW}Generating dashboard access token...${NC}"

    # --------- Ensure service accounts are ready ---------
    microk8s kubectl -n kube-system get sa >/dev/null 2>&1 || {
        echo -e "${RED}Kubernetes not responding. Try again later.${NC}"
        read -p "ENTER..."
        return
    }

    # --------- TOKEN SMART DISCOVERY ---------
    ATTEMPTS=0
    TOKEN=""
    SECRET_NAME=""

    echo -e "${CYAN}Locating dashboard token secret...${NC}"

    while [[ -z "$SECRET_NAME" && $ATTEMPTS -lt 20 ]]; do
        # Busca secrets de token do SA
        SECRET_NAME=$(microk8s kubectl -n kube-system get secrets \
            --field-selector type=kubernetes.io/service-account-token \
            -o jsonpath="{.items[*].metadata.name}" \
            | tr ' ' '\n' | grep -E 'admin|dashboard' | head -n 1)

        ((ATTEMPTS++))
        echo -ne "Attempt $ATTEMPTS/20 searching for token...\r"
        sleep 4
    done

    echo

    if [[ -z "$SECRET_NAME" ]]; then
        echo -e "${RED}❗ No dashboard token secret found.${NC}"
        echo "Available secrets:"
        microk8s kubectl -n kube-system get secret
        read -p "ENTER..."
        return
    fi

    # --------- Extract Token ---------
    TOKEN=$(microk8s kubectl -n kube-system get secret "$SECRET_NAME" \
            -o jsonpath="{.data.token}" | base64 --decode 2>/dev/null)

    if [[ -z "$TOKEN" ]]; then
        echo -e "${RED}❗ Token extraction failed even after secret discovery.${NC}"
        echo "Try manual command:"
        echo "microk8s kubectl -n kube-system get secret $SECRET_NAME -o jsonpath='{.data.token}' | base64 --decode"
        read -p "ENTER..."
        return
    fi

    echo -e "\n${GREEN}✔ TOKEN GENERATED SUCCESSFULLY:${NC}\n$TOKEN\n"

    # --------- UFW Auto Enable + Rule ---------
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q inactive; then
            echo -e "${CYAN}UFW detected but inactive — enabling automatically...${NC}"
            yes | ufw enable >/dev/null 2>&1
        fi
        ufw allow 10443/tcp >/dev/null 2>&1
        echo -e "${GREEN}✔ Port 10443 opened in UFW${NC}\n"
    else
        echo -e "${YELLOW}UFW not installed — skipping firewall rule.${NC}\n"
    fi

    # --------- SAVE ACCESS INFO ---------
    echo "$TOKEN" > "$INFO_FILE"
    echo "http://$SERVER_IP:10443" >> "$INFO_FILE"
    echo "microk8s dashboard-proxy" >> "$INFO_FILE"

    echo -e "${CYAN}Access saved to:${NC} $INFO_FILE"
    echo -e "\nRun inside terminal:"
    echo -e "  ${CYAN}microk8s dashboard-proxy${NC}"
    echo -e "\nThen open in browser:"
    echo -e "  ${CYAN}http://$SERVER_IP:10443${NC}\n"

    read -p "Press ENTER to return to menu..."
}


#=============== SPINNER ===============#
spinner(){
    local pid=$!
    local spin='|/-\'
    while kill -0 $pid 2>/dev/null; do
        for i in {0..3}; do printf "\rProcessing ${spin:$i:1}"; sleep 0.1; done
    done
    printf "\rDone!      \n"
}

#============== SHOW STATUS WITH ICONS ✔✖ ==============#
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

        # ---------------- Enable Multiple ---------------- #
        1)
            echo
            enabled=($(microk8s status --format short | grep enabled | awk '{print $1}'))
            disabled=()
            for addon in "${ADDONS[@]}"; do [[ " ${enabled[*]} " =~ " $addon " ]] || disabled+=("$addon"); done
            [[ ${#disabled[@]} == 0 ]] && echo -e "${GREEN}All addons enabled.${NC}" && read -p "ENTER..." && continue

            echo -e "${CYAN}Select addons to enable (space separated)${NC}"
            for i in "${!disabled[@]}"; do echo -e "${YELLOW}$((i+1))${NC} - ${disabled[$i]}"; done
            echo -e ""
            echo -e "${YELLOW}99${NC} - Exit"
            read -p "Choose an option: " -a choices
            [[ "${choices[*]}" =~ 99 ]] && continue

            for c in "${choices[@]}"; do
                idx=$((c-1))
                if [[ $idx -ge 0 && $idx < ${#disabled[@]} ]]; then
                    addon=${disabled[$idx]}
                    echo "Enabling $addon..."
                    microk8s enable "$addon" >/dev/null 2>&1 & spinner
                    [[ $addon == "dashboard" ]] && DASH=1
                fi
            done
            [[ "$DASH" == "1" ]] && dashboard_token
        ;;

        # ---------------- Enable ALL ---------------- #
        2)
            echo "Enabling all addons..."
            (microk8s enable ${ADDONS[*]} >/dev/null 2>&1) & spinner
            dashboard_token
        ;;

        # ---------------- Raw List ---------------- #
        3)
            microk8s status | sed -n '/addons:/,$p'
            read -p "ENTER..."
        ;;

        # ---------------- Disable Multiple ---------------- #
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
                    echo "Disabling $addon..."
                    microk8s disable "$addon" >/dev/null 2>&1 & spinner
                    echo -e "❌ ${RED}$addon disabled${NC}"
                fi
            done
            read -p "ENTER..."
        ;;

        99) exit 0 ;;
        *) echo -e "${RED}Invalid${NC}" && sleep 1 ;;
    esac
done
