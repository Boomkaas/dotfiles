#!/usr/bin/env bash

# ==============================================================================
# Network & Share Manager (Hamachi & Samba TUI)
# Interactive terminal dashboard to operate LogMeIn Hamachi VPN,
# Samba local folder shares, and remote CIFS mounts.
# ==============================================================================

# set -eo pipefail disabled for interactive menu resilience

# Ensure script opens in a graphical terminal if launched without a TTY
if [[ "${1:-}" != "--no-gui" ]] && { [ ! -t 0 ] || [ ! -t 1 ]; }; then
    if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
        if command -v kitty >/dev/null 2>&1; then
            exec kitty --title "Network & Share Manager" bash "$0" --no-gui "$@"
        elif command -v foot >/dev/null 2>&1; then
            exec foot --title "Network & Share Manager" bash "$0" --no-gui "$@"
        fi
    fi
fi
[[ "${1:-}" == "--no-gui" ]] && shift

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

pause() {
    echo -e "\n${DIM}Press [Enter] to continue...${RESET}"
    read -r
}

get_hamachi_status() {
    local svc_active
    svc_active=$(systemctl is-active logmein-hamachi 2>/dev/null) || svc_active="inactive"

    if [ "$svc_active" != "active" ]; then
        echo -e "${RED}● STOPPED${RESET} (service inactive)"
        return
    fi

    local ham_ip
    ham_ip=$(ip -4 addr show dev ham0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1) || ham_ip=""

    if [ -n "$ham_ip" ]; then
        echo -e "${GREEN}● ONLINE${RESET} (IP: ${CYAN}${ham_ip}${RESET} on ham0)"
    else
        echo -e "${YELLOW}● RUNNING${RESET} (interface pending or logged out)"
    fi
}

get_samba_status() {
    local svc_active
    svc_active=$(systemctl is-active samba-smbd 2>/dev/null) || svc_active="inactive"

    if [ "$svc_active" != "active" ]; then
        echo -e "${RED}● STOPPED${RESET} (sharing disabled)"
        return
    fi

    local client_count
    client_count=$(ss -tnH '( sport = :445 or dport = :445 )' 2>/dev/null | wc -l)
    echo -e "${GREEN}● ACTIVE${RESET} (${client_count} client connection(s))"
}

get_cifs_mounts() {
    local mounts
    mounts=$(findmnt -t cifs -o TARGET,SOURCE --noheadings 2>/dev/null || true)
    if [ -n "$mounts" ]; then
        echo -e "${GREEN}${mounts}${RESET}"
    else
        echo -e "${DIM}None${RESET}"
    fi
}

draw_header() {
    clear 2>/dev/null || true
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}         ${BOLD}🌐 Network & Share Manager (Hamachi & Samba TUI)${RESET}              ${CYAN}║${RESET}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${RESET}"
    echo -e "  ${BOLD}Hamachi VPN:${RESET}    $(get_hamachi_status)"
    echo -e "  ${BOLD}Samba Sharing:${RESET}  $(get_samba_status)"
    echo -e "  ${BOLD}Active Shares:${RESET}  ${DIM}workspace (~/Code), Test (~/Code/Test)${RESET}"
    echo -e "  ${BOLD}CIFS Mounts:${RESET}    $(get_cifs_mounts)"
    echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
}

main_menu() {
    while true; do
        draw_header
        echo -e "${BOLD}${BLUE}  [ Hamachi VPN ]${RESET}"
        echo -e "   ${CYAN}1${RESET}) 󰌘  Start Hamachi Service"
        echo -e "   ${CYAN}2${RESET}) 󰌙  Stop Hamachi Service (disconnect and take down ham0)"
        echo -e "   ${CYAN}3${RESET}) 󰒍  Log In to Hamachi Network"
        echo -e "   ${CYAN}4${RESET}) 󰒎  Log Out of Hamachi Network"
        echo -e "   ${CYAN}5${RESET}) 󰍹  Show Hamachi Status & Peers List"
        echo -e "   ${CYAN}6${RESET})   Launch Haguichi GUI"
        echo
        echo -e "${BOLD}${BLUE}  [ Samba Folder Sharing ]${RESET}"
        echo -e "   ${CYAN}7${RESET}) 󰉋  Start Samba Sharing (expose ~/Code/Test & workspace)"
        echo -e "   ${CYAN}8${RESET}) 󰉌  Stop Samba Sharing (disconnect all shared folders)"
        echo -e "   ${CYAN}9${RESET}) 󰑓  Restart Samba Sharing"
        echo -e "  ${CYAN}10${RESET}) 󰒔  View Active Client Connections (who is connected)"
        echo -e "  ${CYAN}11${RESET}) 󰌆  Set / Change Samba Password (smbpasswd for user peng)"
        echo -e "  ${CYAN}12${RESET}) 󰝰  Open ~/Code/Test in File Manager (Thunar)"
        echo
        echo -e "${BOLD}${BLUE}  [ Remote CIFS Mounts ]${RESET}"
        echo -e "  ${CYAN}13${RESET}) 󰁤  Mount Remote Share to /mnt"
        echo -e "  ${CYAN}14${RESET}) 󰁦  Unmount /mnt"
        echo
        echo -e "   ${RED}0${RESET}) 󰗼  Exit"
        echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
        echo -ne "${BOLD}Select an option [0-14]: ${RESET}"
        read -r choice

        case "$choice" in
            1)
                echo -e "\n${YELLOW}==> Starting LogMeIn Hamachi service...${RESET}"
                sudo systemctl start logmein-hamachi
                sleep 1
                echo -e "${GREEN}✓ Service started.${RESET}"
                pause
                ;;
            2)
                echo -e "\n${YELLOW}==> Stopping LogMeIn Hamachi service...${RESET}"
                sudo systemctl stop logmein-hamachi
                sleep 1
                echo -e "${GREEN}✓ Service stopped and ham0 interface removed.${RESET}"
                pause
                ;;
            3)
                echo -e "\n${YELLOW}==> Logging into Hamachi...${RESET}"
                sudo hamachi login || true
                pause
                ;;
            4)
                echo -e "\n${YELLOW}==> Logging out of Hamachi...${RESET}"
                sudo hamachi logout || true
                pause
                ;;
            5)
                echo -e "\n${YELLOW}==> Hamachi status & peer list:${RESET}"
                echo "---------------------------------------------------------"
                sudo hamachi || true
                echo "---------------------------------------------------------"
                pause
                ;;
            6)
                echo -e "\n${YELLOW}==> Launching Haguichi GUI...${RESET}"
                if command -v haguichi >/dev/null 2>&1; then
                    haguichi >/dev/null 2>&1 &
                    echo -e "${GREEN}✓ Haguichi started.${RESET}"
                else
                    echo -e "${RED}✗ Haguichi is not installed. Run 'nixreb' first.${RESET}"
                fi
                sleep 1
                ;;
            7)
                echo -e "\n${YELLOW}==> Starting Samba file sharing services...${RESET}"
                sudo systemctl start samba-smbd samba-wsdd
                sleep 1
                echo -e "${GREEN}✓ Samba and WSDD are running.${RESET}"
                pause
                ;;
            8)
                echo -e "\n${YELLOW}==> Stopping Samba file sharing services...${RESET}"
                sudo systemctl stop samba-smbd samba-wsdd
                sleep 1
                echo -e "${GREEN}✓ Samba stopped. All shared folders are now disconnected.${RESET}"
                pause
                ;;
            9)
                echo -e "\n${YELLOW}==> Restarting Samba file sharing services...${RESET}"
                sudo systemctl restart samba-smbd samba-wsdd
                sleep 1
                echo -e "${GREEN}✓ Samba restarted successfully.${RESET}"
                pause
                ;;
            10)
                echo -e "\n${YELLOW}==> Active Samba connections on port 445:${RESET}"
                echo "---------------------------------------------------------"
                ss -tnp '( sport = :445 or dport = :445 )' 2>/dev/null || true
                echo "---------------------------------------------------------"
                if command -v smbstatus >/dev/null 2>&1; then
                    echo -e "\n${YELLOW}==> smbstatus summary:${RESET}"
                    sudo smbstatus -S 2>/dev/null || true
                fi
                pause
                ;;
            11)
                echo -e "\n${YELLOW}==> Setting Samba password for user 'peng'...${RESET}"
                sudo smbpasswd -a peng
                pause
                ;;
            12)
                echo -e "\n${YELLOW}==> Opening ~/Code/Test in file manager...${RESET}"
                mkdir -p "$HOME/Code/Test"
                if command -v thunar >/dev/null 2>&1; then
                    thunar "$HOME/Code/Test" >/dev/null 2>&1 &
                elif command -v xdg-open >/dev/null 2>&1; then
                    xdg-open "$HOME/Code/Test" >/dev/null 2>&1 &
                fi
                sleep 0.5
                ;;
            13)
                echo -e "\n${YELLOW}==> Mount Remote CIFS/Samba Share${RESET}"
                local my_ham_ip
                my_ham_ip=$(ip -4 addr show dev ham0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1) || my_ham_ip="25.6.89.170"

                read -rp "Target host IP [default: ${my_ham_ip}]: " target_ip
                target_ip="${target_ip:-$my_ham_ip}"

                read -rp "Share name [default: Test]: " share_name
                share_name="${share_name:-Test}"

                read -rp "Username [default: peng]: " smb_user
                smb_user="${smb_user:-peng}"

                sudo mkdir -p /mnt
                echo -e "\n${YELLOW}Mounting //${target_ip}/${share_name} to /mnt...${RESET}"
                sudo mount -t cifs "//${target_ip}/${share_name}" /mnt \
                    -o "username=${smb_user},uid=$(id -u),gid=$(id -g)"
                echo -e "${GREEN}✓ Successfully mounted to /mnt.${RESET}"
                pause
                ;;
            14)
                echo -e "\n${YELLOW}==> Unmounting /mnt...${RESET}"
                if sudo umount /mnt 2>/dev/null || sudo umount -l /mnt 2>/dev/null; then
                    echo -e "${GREEN}✓ /mnt unmounted successfully.${RESET}"
                else
                    echo -e "${YELLOW}/mnt was not mounted or already unmounted.${RESET}"
                fi
                pause
                ;;
            0|q|Q)
                echo -e "\n${GREEN}Goodbye!${RESET}"
                exit 0
                ;;
            *)
                echo -e "\n${RED}Invalid option! Please choose between 0 and 14.${RESET}"
                sleep 1
                ;;
        esac
    done
}

main_menu
