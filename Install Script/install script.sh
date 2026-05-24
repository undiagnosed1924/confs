#!/usr/bin/env bash

# Exit on error
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RC='\033[0m'

# 1. PRE-SELECTION PREREQUISITES
# We install these first so the menu and download logic work perfectly.
echo -e "${BLUE}Performing system pre-check...${RC}"
sudo apt update -qq
sudo apt install -y curl gpg wget unzip jq > /dev/null 2>&1

# Default selection states
INSTALL_CODIUM=true
INSTALL_BRAVE=true
INSTALL_ONLYOFFICE=true
INSTALL_LOCALSEND=true
INSTALL_TLAUNCHER=true

# 2. SELECTION MENU
show_menu() {
    clear
    echo -e "${BLUE}===================================================${RC}"
    echo -e "${BLUE}   UNDIAGNOSED1924 CUSTOM INSTALLER SELECTION      ${RC}"
    echo -e "${BLUE}===================================================${RC}"
    echo -e "Enter the number to toggle [ON/OFF], or 'y' to install."
    echo -e "------------------------------------------"
    echo -e "1) [$( [[ $INSTALL_CODIUM == true ]] && echo -e "${GREEN}ON${RC}" || echo -e "OFF" )] VSCodium"
    echo -e "2) [$( [[ $INSTALL_BRAVE == true ]] && echo -e "${GREEN}ON${RC}" || echo -e "OFF" )] Brave Browser"
    echo -e "3) [$( [[ $INSTALL_ONLYOFFICE == true ]] && echo -e "${GREEN}ON${RC}" || echo -e "OFF" )] OnlyOffice"
    echo -e "4) [$( [[ $INSTALL_LOCALSEND == true ]] && echo -e "${GREEN}ON${RC}" || echo -e "OFF" )] LocalSend"
    echo -e "5) [$( [[ $INSTALL_TLAUNCHER == true ]] && echo -e "${GREEN}ON${RC}" || echo -e "OFF" )] TLauncher (Minecraft)"
    echo -e "------------------------------------------"
    echo -n "Selection (1-5, 'y' to confirm, 'q' to quit): "
}

while true; do
    show_menu
    read -r opt
    case $opt in
        1) INSTALL_CODIUM=$([[ $INSTALL_CODIUM == true ]] && echo false || echo true) ;;
        2) INSTALL_BRAVE=$([[ $INSTALL_BRAVE == true ]] && echo false || echo true) ;;
        3) INSTALL_ONLYOFFICE=$([[ $INSTALL_ONLYOFFICE == true ]] && echo false || echo true) ;;
        4) INSTALL_LOCALSEND=$([[ $INSTALL_LOCALSEND == true ]] && echo false || echo true) ;;
        5) INSTALL_TLAUNCHER=$([[ $INSTALL_TLAUNCHER == true ]] && echo false || echo true) ;;
        y|Y) break ;;
        q|Q) exit 0 ;;
        *) echo -e "${YELLOW}Invalid option${RC}"; sleep 1 ;;
    esac
done

# 3. REPOSITORY CONFIGURATION
echo -e "\n${BLUE}Configuring Repositories...${RC}"

if [ "$INSTALL_CODIUM" = true ]; then
    wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg > /dev/null 2>&1
    echo 'deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list
fi

if [ "$INSTALL_BRAVE" = true ]; then
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
fi

if [ "$INSTALL_ONLYOFFICE" = true ]; then
    sudo curl -fsSLo /usr/share/keyrings/onlyoffice.gpg https://download.onlyoffice.com/repo/onlyoffice.gpg
    echo "deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main" | sudo tee /etc/apt/sources.list.d/onlyoffice.list
fi

# 4. INSTALLATION PHASE
sudo apt update

PACKAGES=(git htop tmux build-essential)
[[ "$INSTALL_CODIUM" == true ]] && PACKAGES+=(codium)
[[ "$INSTALL_BRAVE" == true ]] && PACKAGES+=(brave-browser)
[[ "$INSTALL_ONLYOFFICE" == true ]] && PACKAGES+=(onlyoffice-desktopeditors)
[[ "$INSTALL_TLAUNCHER" == true ]] && PACKAGES+=(default-jre)

echo -e "${GREEN}Installing Packages: ${PACKAGES[*]}${RC}"
sudo apt install -y "${PACKAGES[@]}"

# 5. POST-INSTALL (DEB & BINARIES)
if [ "$INSTALL_LOCALSEND" = true ]; then
    echo -e "${BLUE}Fetching latest LocalSend...${RC}"
    DEB_URL=$(curl -s https://api.github.com/repos/localsend/localsend/releases/latest | jq -r '.assets[] | select(.name | endswith("linux-x86-64.deb")) | .browser_download_url')
    wget -qO /tmp/localsend.deb "$DEB_URL"
    sudo apt install -y /tmp/localsend.deb
    rm /tmp/localsend.deb
fi

if [ "$INSTALL_TLAUNCHER" = true ]; then
    echo -e "${BLUE}Setting up TLauncher...${RC}"
    mkdir -p "$HOME/.local/share/tlauncher"
    wget -qO /tmp/TLauncher.zip https://tlauncher.org/jar
    unzip -oq /tmp/TLauncher.zip -d /tmp/tlauncher-extracted
    JAR_FILE=$(find /tmp/tlauncher-extracted -name "*.jar" | head -n 1)
    mv "$JAR_FILE" "$HOME/.local/share/tlauncher/TLauncher.jar"
    
    mkdir -p "$HOME/.local/share/applications"
    cat <<EOF > "$HOME/.local/share/applications/tlauncher.desktop"
[Desktop Entry]
Name=TLauncher
Comment=Minecraft Launcher
Exec=java -jar $HOME/.local/share/tlauncher/TLauncher.jar
Terminal=false
Type=Application
Icon=games-config
Categories=Game;
EOF
    rm -rf /tmp/TLauncher.zip /tmp/tlauncher-extracted
fi

echo -e "${GREEN}Setup Complete!${RC}"
