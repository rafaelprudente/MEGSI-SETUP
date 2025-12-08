#!/bin/bash

# ======== CORES ========
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
NC='\e[0m' # sem cor

# ======== URLs RAW DO GITHUB ========
REPO_BASE="https://raw.githubusercontent.com/rafaelprudente/MEGSI-SETUP/main/UBUNTU"

SCRIPT_A="install-vbox-additions.sh"
SCRIPT_B="b.sh"   # substitua futuramente pelo script real

# ======== FUNÇÕES ========
download_script() {
    url="$1"
    file="$2"

    echo -e "${YELLOW}Script '$file' não encontrado. Baixando...${NC}"
    curl -L -o "$file" "$url"

    if [[ $? -ne 0 || ! -s "$file" ]]; then
        echo -e "${RED}Falha ao baixar $file! Verifique a URL.${NC}"
        rm -f "$file" 2>/dev/null
        return 1
    fi

    chmod +x "$file"
    echo -e "${GREEN}Download concluído com sucesso!${NC}"
}

run_script() {
    script=$1
    url=$2

    if [[ ! -f "$script" ]]; then
        download_script "$url" "$script" || return
    fi

    echo -e "${CYAN}Executando $script...${NC}"
    chmod +x "$script"
    ./"$script"

    echo -e "\n${YELLOW}Pressione ENTER para voltar ao menu...${NC}"
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
        1) run_script "$SCRIPT_A" "$REPO_BASE/$SCRIPT_A" ;;
        2) run_script "$SCRIPT_B" "$REPO_BASE/$SCRIPT_B" ;;
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
