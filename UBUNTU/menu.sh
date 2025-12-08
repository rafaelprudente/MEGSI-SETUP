#!/bin/bash

# ======== CORES ========
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
NC='\e[0m' # sem cor

# ======== FUNÇÕES ========
run_script() {
    script=$1
    if [[ -f "$script" ]]; then
        echo -e "${CYAN}Executing $script...${NC}"
        chmod +x "$script"
        ./"$script"
    else
        echo -e "${RED}ERROR: the script '$script' not found!${NC}"
    fi
    echo -e "\n${YELLOW}Press ENTER to back to menu...${NC}"
    read
}

# ======== MENU ========
menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}                 MENU                  ${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}1${NC} - Install VirtualBox Additions"
    echo -e "${YELLOW}2${NC} - Set Static IP"
    echo -e ""
    echo -e "${YELLOW}3${NC} - Exit"
    echo -e "${CYAN}========================================${NC}"
}

# ======== LOOP PRINCIPAL ========
while true; do
    menu
    read -p "Choose an option: " opcao

    case "$opcao" in
        1) run_script "install-vbox-additions.sh" ;;
        2) run_script "b.sh" ;;
        3) 
            echo -e "${GREEN}Exiting...${NC}"
            sleep 1
            clear
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid Option!${NC}"
            sleep 1
            ;;
    esac
done
