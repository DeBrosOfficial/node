#!/bin/bash

set -e  # Exit on any error
trap 'echo -e "${RED}An error occurred. Installation aborted.${NOCOLOR}"; exit 1' ERR

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[38;2;2;128;175m'
YELLOW='\033[1;33m'
NOCOLOR='\033[0m'

log() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NOCOLOR} $1"
}

. /etc/os-release

if ! command -v sudo &>/dev/null; then
    log "${RED}Error: sudo command not found. Please run with sudo privileges.${NOCOLOR}"
    exit 1
fi

# Check ports availability
for port in 7777 7778; do
    if sudo netstat -tuln | grep -q ":$port "; then
        log "${RED}Error: Port $port is already in use. Please free it up and try again.${NOCOLOR}"
        exit 1
    fi
done

# Check Docker installation and version
MIN_DOCKER_VERSION="20.10.0"
if ! command -v docker &> /dev/null; then
    log "${CYAN}Docker not found. Installing Docker...${NOCOLOR}"
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

    # Detect OS and set Docker repository
    . /etc/os-release
    if [ "$ID" = "ubuntu" ]; then
        OS_TYPE="ubuntu"
        REPO_URL="https://download.docker.com/linux/ubuntu"
        CODENAME=$(lsb_release -cs)
    elif [ "$ID" = "debian" ] || [ "$ID" = "raspbian" ]; then
        OS_TYPE="debian"
        REPO_URL="https://download.docker.com/linux/debian"
        CODENAME=$(lsb_release -cs)  # e.g., "bookworm" for Debian 12 or Raspberry Pi OS
    else
        log "${RED}Error: Unsupported OS ($ID). This script supports Ubuntu, Debian, or Raspberry Pi OS.${NOCOLOR}"
        exit 1
    fi

    curl -fsSL "$REPO_URL/gpg" | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] $REPO_URL $CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker $USER
    log "${GREEN}Docker installed successfully on $OS_TYPE ($CODENAME).${NOCOLOR}"
else
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    if [ "$(printf '%s\n' "$MIN_DOCKER_VERSION" "$DOCKER_VERSION" | sort -V | head -n1)" != "$MIN_DOCKER_VERSION" ]; then
        log "${RED}Docker version $DOCKER_VERSION is too old. Minimum required: $MIN_DOCKER_VERSION${NOCOLOR}"
        exit 1
    fi
    log "${GREEN}Docker already installed (version $DOCKER_VERSION).${NOCOLOR}"
fi

# Check if Docker Compose is installed
if ! docker compose version &> /dev/null; then
    log "${CYAN}Docker Compose not found. Installing Docker Compose...${NOCOLOR}"
    sudo apt-get install -y docker-compose-plugin
    log "${GREEN}Docker Compose installed successfully.${NOCOLOR}"
else
    log "${GREEN}Docker Compose already installed.${NOCOLOR}"
fi

# Create installation directory
INSTALL_DIR="/opt/debros-node"
sudo mkdir -p $INSTALL_DIR
sudo chown $USER:$USER $INSTALL_DIR

# Check if repository already exists
UPDATE_MODE=false
if [ -d "$INSTALL_DIR/.git" ]; then
    log "${BLUE}==================================================${NOCOLOR}"
    log "${YELLOW}            DeBros Node already installed              ${NOCOLOR}"
    log "${BLUE}==================================================${NOCOLOR}"
    
    echo -e "${CYAN}Do you want to update DeBros Node to the latest version?${NOCOLOR}"
    read -rp "Update DeBros Node? (yes/no) [Default: yes]: " UPDATE_CHOICE
    UPDATE_CHOICE="${UPDATE_CHOICE:-yes}"
    
    if [[ "$UPDATE_CHOICE" == "yes" ]]; then
        UPDATE_MODE=true
        log "${BLUE}==================================================${NOCOLOR}"
        log "${GREEN}             Updating DeBros Node                     ${NOCOLOR}"
        log "${BLUE}==================================================${NOCOLOR}"
        
        if [ -f "$INSTALL_DIR/.env" ]; then
            if ! cp "$INSTALL_DIR/.env" "$INSTALL_DIR/.env.backup"; then
                log "${RED}Failed to create backup of .env file${NOCOLOR}"
                exit 1
            fi
            log "${CYAN}Backed up existing configuration.${NOCOLOR}"
        fi
        
        cd $INSTALL_DIR
        git pull
        
        log "${GREEN}DeBros Node updated successfully.${NOCOLOR}"
    else
        log "${CYAN}Update cancelled. Exiting...${NOCOLOR}"
        exit 0
    fi
else
    log "${BLUE}==================================================${NOCOLOR}"
    log "${GREEN}             Downloading DeBros Node                  ${NOCOLOR}"
    log "${BLUE}==================================================${NOCOLOR}"

    git clone https://github.com/DeBrosOfficial/node.git $INSTALL_DIR
    
    cd $INSTALL_DIR
fi

# Banner
echo -e "${BLUE}========================================================================${NOCOLOR}"
echo -e "${CYAN}
          ____       ____                  _   _           _      
         |  _ \  ___| __ ) _ __ ___  ___  | \ | | ___   __| | ___ 
         | | | |/ _ \  _ \|  __/ _ \/ __| |  \| |/ _ \ / _  |/ _ |
         | |_| |  __/ |_) | | | (_) \__ \ | |\  | (_) | (_| |  __/
         |____/ \___|____/|_|  \___/|___/ |_| \_|\___/ \__,_|\___|                                                                                                                                                                               
${NOCOLOR}"
echo -e "${BLUE}========================================================================${NOCOLOR}"

# Configuration
if [ "$UPDATE_MODE" = true ] && [ -f "$INSTALL_DIR/.env.backup" ]; then
    log "${CYAN}Restoring previous configuration...${NOCOLOR}"
    cp "$INSTALL_DIR/.env.backup" "$INSTALL_DIR/.env"
else
    log "${BLUE}==================================================${NOCOLOR}"
    log "${GREEN}        Start Node Configuration Wizard          ${NOCOLOR}"
    log "${BLUE}==================================================${NOCOLOR}"

    # Enter nickname
    log "${GREEN}- Enter your desired nickname for the DeBros node (1-19 characters, only [a-zA-Z0- executing [a-zA-Z0-9] and no spaces)${NOCOLOR}"
    read -rp "1/3 Enter your nickname: " NICKNAME
    while [[ ! "$NICKNAME" =~ ^[a-zA-Z0-9]{1,19}$ ]]; do
        log "${RED}Error: Nickname must be 1-19 characters long and contain only letters and numbers (no spaces)${NOCOLOR}"
        read -rp "1/3 Enter your nickname: " NICKNAME
    done

    # Enter admin wallet address
    log "${GREEN}- Enter your Solana wallet address to be eligible for rewards${NOCOLOR}"
    read -rp "2/3 Your Solana Wallet Address: " ADMIN_WALLET

    # Announce ports
    log "${GREEN}- DeBros will use ports 7777 and 7778 automatically${NOCOLOR}"

    # Configure firewall
    log "${GREEN}- Would you like to configure the firewall to open ports 7777 and 7778?${NOCOLOR}"
    read -rp "3/3 Configure firewall? (yes/no) [Default: yes]: " CONFIGURE_FIREWALL
    CONFIGURE_FIREWALL="${CONFIGURE_FIREWALL:-yes}"
    while ! [[ "$CONFIGURE_FIREWALL" =~ ^(yes|no)$ ]]; do
        log "${RED}Error: Please respond with 'yes' or 'no'.${NOCOLOR}"
        read -rp "3/3 Configure firewall? (yes/no) [Default: yes]: " CONFIGURE_FIREWALL
        CONFIGURE_FIREWALL="${CONFIGURE_FIREWALL:-yes}"
    done

    if [[ "$CONFIGURE_FIREWALL" == "yes" ]]; then
        if ! command -v ufw &> /dev/null; then
            log "${GREEN}Installing UFW firewall...${NOCOLOR}"
            sudo apt-get update
            sudo apt-get install -y ufw
        fi
        
        # Capture the initial state of ufw
        UFW_INITIAL_STATUS=$(sudo ufw status | grep -o "Status: [a-z]*" | awk '{print $2}')
        
        log "${GREEN}Configuring firewall rules...${NOCOLOR}"
        sudo ufw allow 7777
        sudo ufw allow 7778
        
        # Only enable ufw if it was already active
        if [[ "$UFW_INITIAL_STATUS" == "active" ]]; then
            log "${GREEN}Ensuring firewall remains enabled...${NOCOLOR}"
            echo "y" | sudo ufw enable
        else
            log "${GREEN}Firewall rules added, but not enabling UFW as it was initially inactive.${NOCOLOR}"
        fi
        
        log "${GREEN}Firewall configuration completed.${NOCOLOR}"
    fi
    
    KEY_DIR="/var/lib/debros/keys"
    KEY_NAME="debros_key"
    if [ ! -d "$KEY_DIR" ]; then
        log "${CYAN}Creating folder $KEY_DIR...${NOCOLOR}"
        sudo mkdir -p "$KEY_DIR"
        sudo chmod 700 "$KEY_DIR"
        sudo chown "$USER:$USER" "$KEY_DIR"
    fi
    
    if [ ! -f "$KEY_DIR/$KEY_NAME" ]; then
        log "${CYAN}Creating new key pair...${NOCOLOR}"
        ssh-keygen -t ed25519 -f "$KEY_DIR/$KEY_NAME" -N "" -q
        log "${GREEN}Keys created in $KEY_DIR${NOCOLOR}"
    else
        log "${GREEN}Using existing keys from $KEY_DIR${NOCOLOR}"
    fi

    FINGERPRINT=$(ssh-keygen -l -f "$KEY_DIR/$KEY_NAME.pub" 2>/dev/null | awk '{print $2}' | sed 's/SHA256://' | base64 -d 2>/dev/null | xxd -p -u | tr -d '\n' | head -c 40)
    IP_ADDRESS=$(curl -s ifconfig.me)

    # Update or create .env file
    if [ -f "$INSTALL_DIR/.env" ]; then
        sed -i "s/NICKNAME=.*/NICKNAME=$NICKNAME/" "$INSTALL_DIR/.env"
        sed -i "s/FINGERPRINT=.*/FINGERPRINT=$FINGERPRINT/" "$INSTALL_DIR/.env"
        sed -i "s/HOSTNAME=.*/HOSTNAME=$IP_ADDRESS/" "$INSTALL_DIR/.env"
        sed -i "s/ADMIN_WALLET=.*/ADMIN_WALLET=$ADMIN_WALLET/" "$INSTALL_DIR/.env"
        sed -i "s/NODE_PUBLIC_ADDRESS=.*/NODE_PUBLIC_ADDRESS=$IP_ADDRESS/" "$INSTALL_DIR/.env"
    else
        cat > $INSTALL_DIR/.env << EOF
NICKNAME=$NICKNAME
FINGERPRINT=$FINGERPRINT
NODE_ENV=production
PORT=7777
ENABLE_ANYONE=true
HOSTNAME=$IP_ADDRESS
ADMIN_WALLET=$ADMIN_WALLET
ENABLE_LOAD_BALANCING=true
SERVICE_DISCOVERY_TOPIC=debros-service-discovery
HEARTBEAT_INTERVAL=5000
STALE_PEER_TIMEOUT=30000
PEER_LOG_INTERVAL=60000
NODE_PUBLIC_ADDRESS=$IP_ADDRESS
BOOTSTRAP_NODES=/ip4/188.166.113.190/tcp/7778/p2p/12D3KooWNWgs4WAUmE4CsxrL6uuyv1yuTzcRReMe5r7Psemsg2Z9,/ip4/82.208.21.140/tcp/7778/p2p/12D3KooWPUdpNX5N6dsuFAvgwfBMXUoFK2QS5sh8NpjxbfGpkSCi
MAX_CONNECTIONS=1000
LOAD_BALANCING_STRATEGY=least-loaded
ACCEPT_TERMS=true
KEY_PATH=/var/lib/debros/keys
LIBP2P_DEBUG=true
IPFS_DEBUG=true
LOG_LEVEL=debug
DEBUG=libp2p:*
EOF
    fi
fi

if [ ! -f "/etc/systemd/system/debros.service" ] || [ "$UPDATE_MODE" = true ]; then
    cat > /tmp/debros.service << EOF
[Unit]
Description=DeBrosNode Service
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/docker compose up --build
ExecStop=/usr/bin/docker compose down
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo mv /tmp/debros.service /etc/systemd/system/
    sudo systemctl daemon-reload
    if [ "$UPDATE_MODE" != true ]; then
        sudo systemctl enable debros.service
    fi
fi

# Check if running on Raspberry Pi and enable cgroups if needed
check_and_enable_cgroups() {
    # Detect Raspberry Pi by checking /proc/cpuinfo
    if grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        log "${CYAN}Detected Raspberry Pi hardware.${NOCOLOR}"
        
        # Check if cmdline.txt exists in either location
        CMDLINE_FILE=""
        if [ -f "/boot/firmware/cmdline.txt" ]; then
            CMDLINE_FILE="/boot/firmware/cmdline.txt"
        elif [ -f "/boot/cmdline.txt" ]; then
            CMDLINE_FILE="/boot/cmdline.txt"
        else
            log "${RED}Error: Could not locate cmdline.txt for Raspberry Pi.${NOCOLOR}"
            exit 1
        fi

        # Check if cgroups are already enabled
        if ! grep -q "cgroup_enable=memory" "$CMDLINE_FILE" || ! grep -q "cgroup_memory=1" "$CMDLINE_FILE"; then
            log "${YELLOW}Memory cgroups not enabled. Updating $CMDLINE_FILE...${NOCOLOR}"
            
            # Backup the original cmdline.txt
            sudo cp "$CMDLINE_FILE" "$CMDLINE_FILE.backup" || {
                log "${RED}Failed to backup $CMDLINE_FILE${NOCOLOR}"
                exit 1
            }
            
            # Append cgroup parameters if not present
            CURRENT_CMDLINE=$(cat "$CMDLINE_FILE")
            NEW_CMDLINE="$CURRENT_CMDLINE cgroup_enable=memory cgroup_memory=1"
            echo "$NEW_CMDLINE" | sudo tee "$CMDLINE_FILE" > /dev/null || {
                log "${RED}Failed to update $CMDLINE_FILE${NOCOLOR}"
                exit 1
            }
            
            log "${GREEN}Updated $CMDLINE_FILE with cgroup settings.${NOCOLOR}"
            log "${YELLOW}A reboot is required to apply these changes.${NOCOLOR}"
            
            read -rp "Reboot now? (yes/no) [Default: yes]: " REBOOT_CHOICE
            REBOOT_CHOICE="${REBOOT_CHOICE:-yes}"
            if [[ "$REBOOT_CHOICE" == "yes" ]]; then
                log "${CYAN}Rebooting system...${NOCOLOR}"
                sudo reboot
            else
                log "${CYAN}Please reboot manually to apply changes before continuing.${NOCOLOR}"
                exit 0
            fi
        else
            log "${GREEN}Memory cgroups already enabled in $CMDLINE_FILE.${NOCOLOR}"
        fi
    fi
}

# Call the function before K3s installation
check_and_enable_cgroups

# Ask about K3s installation
if ! command -v k3s &> /dev/null; then
    log "${GREEN}- Would you like to install K3s for container orchestration?${NOCOLOR}"
    read -rp "4/4 Install K3s? (yes/no) [Default: yes]: " INSTALL_K3S
    INSTALL_K3S="${INSTALL_K3S:-yes}"
    while ! [[ "$INSTALL_K3S" =~ ^(yes|no)$ ]]; do
        log "${RED}Error: Please respond with 'yes' or 'no'.${NOCOLOR}"
        read -rp "4/4 Install K3s? (yes/no) [Default: yes]: " INSTALL_K3S
        INSTALL_K3S="${INSTALL_K3S:-yes}"
    done

    if [[ "$INSTALL_K3S" == "yes" ]]; then
        log "${CYAN}Installing K3s...${NOCOLOR}"
        curl -sfL https://get.k3s.io | sh -
        
        # Wait for K3s to initialize
        sleep 10
        
        # Configure kubectl for the current user
        sudo chmod 644 /etc/rancher/k3s/k3s.yaml
        mkdir -p $HOME/.kube
        sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
        sudo chown $USER:$USER $HOME/.kube/config
        
        # Install Nginx Ingress Controller
        log "${CYAN}Installing Nginx Ingress Controller...${NOCOLOR}"
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
        
        log "${GREEN}K3s and Nginx Ingress Controller installed successfully.${NOCOLOR}"
    fi
fi

chmod 600 /var/lib/debros/keys/*
chown $USER:$USER /var/lib/debros/keys/*

log "${BLUE}==================================================${NOCOLOR}"
if [ "$UPDATE_MODE" = true ]; then
    log "${GREEN}Restarting DeBros Service${NOCOLOR}"
else
    log "${GREEN}Starting DeBros Service${NOCOLOR}"
fi

if systemctl is-active --quiet debros.service; then
    log "${CYAN}Stopping DeBros service...${NOCOLOR}"
    sudo systemctl stop debros.service
    sleep 2
fi

sudo systemctl start debros.service
sleep 5

if systemctl is-active --quiet debros.service; then
    if [ "$UPDATE_MODE" = true ]; then
        log "${GREEN}DeBros service updated and restarted successfully.${NOCOLOR}"
    else
        log "${GREEN}DeBros service started successfully.${NOCOLOR}"
    fi
else
    log "${RED}Failed to start DeBros service.${NOCOLOR}"
    log "${CYAN}You can check the logs with: sudo journalctl -u debros.service${NOCOLOR}"
fi
log "${GREEN}DeBros is now running on ports: ${NOCOLOR}${CYAN}7777 and 7778${NOCOLOR}"
log "${BLUE}==================================================${NOCOLOR}"
log "${GREEN}              DeBros Node Fingerprint            ${NOCOLOR}"
log "${CYAN}     $FINGERPRINT                                 ${NOCOLOR}"
log "${BLUE}==================================================${NOCOLOR}"
if [ "$UPDATE_MODE" = true ]; then
    log "${GREEN}                 Congratulations!                 ${NOCOLOR}"
    log "${CYAN}   DeBros successfully updated and restarted       ${NOCOLOR}"
else
    log "${GREEN}                 Congratulations!                 ${NOCOLOR}"
    log "${CYAN}   DeBros configuration completed successfully!    ${NOCOLOR}"
fi
log "${BLUE}==================================================${NOCOLOR}"
log "${GREEN}Admin commands:${NOCOLOR}"
log "${CYAN}  - sudo systemctl status debros${NOCOLOR} (Check service status)"
log "${CYAN}  - sudo systemctl restart debros${NOCOLOR} (Restart service)"
log "${CYAN}  - sudo journalctl -u debros.service -f${NOCOLOR} (View logs)"
log "${CYAN}  - sudo systemctl stop debros${NOCOLOR} (Stop service)"
log "${CYAN}  - sudo systemctl start debros${NOCOLOR} (Start service)"
log "${BLUE}==================================================${NOCOLOR}"
log "${GREEN}Installation directory: ${NOCOLOR}${CYAN}$INSTALL_DIR${NOCOLOR}"
log "${BLUE}==================================================${NOCOLOR}"

# Information about the DeBros CLI
log "${BLUE}==================================================${NOCOLOR}"
log "${GREEN}DeBros CLI Information:${NOCOLOR}"
log "${CYAN}The DeBros CLI is a tool that runs on your local development machine,${NOCOLOR}"
log "${CYAN}not on the node itself. To install it on your development machine, run:${NOCOLOR}"
log "${YELLOW}npm install -g @debros/cli${NOCOLOR} or ${YELLOW}pnpm install -g @debros/cli${NOCOLOR}"
log "${BLUE}==================================================${NOCOLOR}"

log "${GREEN}To update DeBros in the future, simply run this script again.${NOCOLOR}"
log "${CYAN}For Documentation visit https://docs.debros.io    ${NOCOLOR}"
log "${BLUE}==================================================${NOCOLOR}"
