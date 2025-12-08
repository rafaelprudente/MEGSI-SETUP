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

# ======== SIMPLE SPINNER ========
spinner() {
    local delay=0.1
    local spin='|/-\'
    tput civis
    for i in {1..15}; do
        printf "\r${YELLOW}Preparing download... ${spin:$((i%4)):1}${NC}"
        sleep $delay
    done
    printf "\r${CYAN}Starting download...    ${NC}\n"
    tput cnorm
}

# ======== DOWNLOAD WITH PROGRESS BAR ========
download_script() {
    url="$1"
    file="$2"

    echo -e "${YELLOW}Script '$file' not found locally.${NC}"

    spinner

    echo -e "${CYAN}Downloading '$file'...${NC}"

    curl -# -L -o "$file" "$url"

    if [[ ! -s "$file" ]]; then
        echo -e "${RED}Download failed! Check connection or URL.${NC}"
        rm -f "$file" 2>/dev/null
        return 1
    fi

    chmod +x "$file"
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
    chmod +x "$script"
    ./"$script"

    echo -e "\n${YELLOW}Press ENTER to return to the menu...${NC}"
    read

#    sudo rm -rf $1
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

# ======== MAIN LOOP ========
while true; do
    menu
    read -p "Choose an option: " option

    case "$option" in
        1) run_script "$SCRIPT_A" "$REPO_BASE/$SCRIPT_A" ;;
        2) run_script "$SCRIPT_B" "$REPO_BASE/$SCRIPT_B" ;;
        3)  clear
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option!${NC}"
            sleep 1
            ;;
    esac
done
