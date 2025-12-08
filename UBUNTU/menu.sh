#!/bin/bash

# ======== COLORS ========
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
NC='\e[0m' # No Color

# ======== RAW URLs FROM GITHUB ========
REPO_BASE="https://raw.githubusercontent.com/rafaelprudente/MEGSI-SETUP/main/UBUNTU"

SCRIPT_A="install-vbox-additions.sh"
SCRIPT_B="set-static-ip.sh"
SCRIPT_C="map-truenas-folder.sh"
SCRIPT_D="install-microk8s.sh"
SCRIPT_E="install-microk8s-addons.sh"

# ======== DOWNLOAD WITH PROGRESS BAR ========
download_script() {
    url="$1"
    file="$2"

    echo -e "${YELLOW}Script '$file' not found locally.${NC}"

    echo -e "${CYAN}Downloading '$file'...${NC}"

    sudo curl -# -L -o "$file" "$url"

    if [[ ! -s "$file" ]]; then
        echo -e "${RED}Download failed! Check connection or URL.${NC}"
        sudo rm -f "$file" 2>/dev/null
        return 1
    fi

    sudo chmod +x "$file"
    echo -e "${GREEN}Download completed successfully!${NC}\n"
}

# ======== RUN SCRIPT ========
run_script() {
    script=$1
    url=$2

    if [[ ! -f "$script" ]]; then
        download_script "$url" "$script" || return
    fi

    echo -e "${CYAN}Running $script...${NC}\n"
    sudo chmod +x "$script"
    ./"$script"

    echo -e "\n${YELLOW}Press ENTER to return to the menu...${NC}"
    read

    sudo rm -rf $1
}

# ======== MENU ========
menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}                 MENU${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}1${NC} - Install VirtualBox Additions"
    echo -e "${YELLOW}2${NC} - Set Static IP"
    echo -e "${YELLOW}3${NC} - Map TrueNas Folder"
    echo -e "${YELLOW}4${NC} - Install MicroK8s"
    echo -e "${YELLOW}5${NC} - Install MicroK8s Addons"
    echo -e ""
    echo -e "${YELLOW}99${NC} - Exit"
    echo -e "${CYAN}========================================${NC}"
}

# ======== MAIN LOOP ========
while true; do
    menu
    read -p "Choose an option: " option

    case "$option" in
        1) run_script "$SCRIPT_A" "$REPO_BASE/$SCRIPT_A" ;;
        2) run_script "$SCRIPT_B" "$REPO_BASE/$SCRIPT_B" ;;
        3) run_script "$SCRIPT_C" "$REPO_BASE/$SCRIPT_C" ;;
        4) run_script "$SCRIPT_D" "$REPO_BASE/$SCRIPT_D" ;;
        5) run_script "$SCRIPT_E" "$REPO_BASE/$SCRIPT_e" ;;
        99)  clear
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option!${NC}"
            sleep 1
            ;;
    esac
done
