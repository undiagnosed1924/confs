#!/usr/bin/env bash

# Exit on error
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RC='\033[0m'

echo -e "${BLUE}Starting Automated Debian Setup...${RC}"

# Prerequisite: Ensure curl and gpg are installed to handle keys
sudo apt update && sudo apt install -y curl gpg wget

# ---------------------------------------------------------
# 1. ADD THIRD-PARTY REPOSITORIES
# ---------------------------------------------------------

echo -e "${GREEN}Adding Repository: VSCodium...${RC}"
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
echo 'deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list

echo -e "${GREEN}Adding Repository: Brave Browser...${RC}"
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

echo -e "${GREEN}Adding Repository: OnlyOffice...${RC}"
gpg --no-default-keyring --keyring gnupg-ring:/tmp/onlyoffice.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys CB2DE8E5
chmod 644 /tmp/onlyoffice.gpg
sudo chown root:root /tmp/onlyoffice.gpg
sudo mv /tmp/onlyoffice.gpg /usr/share/keyrings/onlyoffice.gpg
echo "deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main" | sudo tee /etc/apt/sources.list.d/onlyoffice.list

# ---------------------------------------------------------
# 2. INSTALL ALL SOFTWARE
# ---------------------------------------------------------

echo -e "${BLUE}Updating package lists with new repositories...${RC}"
sudo apt update -y

# Define standard software
SOFTWARES=(
    git
    htop
    tmux
    build-essential
    codium                  # VSCodium
    brave-browser           # Brave
    onlyoffice-desktopeditors # OnlyOffice
)

echo -e "${GREEN}Installing software: ${SOFTWARES[*]}${RC}"
sudo apt install -y "${SOFTWARES[@]}"

# ---------------------------------------------------------
# 3. CLEANUP
# ---------------------------------------------------------

echo -e "${GREEN}Cleaning up...${RC}"
sudo apt autoremove -y
echo -e "${BLUE}System setup complete!${RC}"
