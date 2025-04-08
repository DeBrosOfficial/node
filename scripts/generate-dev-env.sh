#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NOCOLOR='\033[0m'

log() {
    echo -e "${CYAN}[DEV SETUP]${NOCOLOR} $1"
}

# Base directory - the project root
BASE_DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
KEY_DIR="$BASE_DIR/keys"
KEY_NAME="debros_key"

# Create .env file if it doesn't exist
if [ ! -f "$BASE_DIR/.env" ]; then
    log "Generating .env file for development..."
    
    # Create keys directory
    mkdir -p "$KEY_DIR"
    chmod 700 "$KEY_DIR"
    
    # Generate keypair if it doesn't exist
    if [ ! -f "$KEY_DIR/$KEY_NAME" ]; then
        log "Creating new key pair..."
        ssh-keygen -t ed25519 -f "$KEY_DIR/$KEY_NAME" -N "" -q
        log "${GREEN}Keys created in $KEY_DIR${NOCOLOR}"
    fi
    
    # Calculate fingerprint
    FINGERPRINT=$(ssh-keygen -l -f "$KEY_DIR/$KEY_NAME.pub" 2>/dev/null | awk '{print $2}' | sed 's/SHA256://' | base64 -d 2>/dev/null | xxd -p -u | tr -d '\n' | head -c 40)
    
    # Default dev values
    NICKNAME="dev_node"
    ADMIN_WALLET="devWallet123456789"
    
    # Create the .env file with development settings
    cat > "$BASE_DIR/.env" << EOF
NICKNAME=$NICKNAME
FINGERPRINT=$FINGERPRINT
NODE_ENV=development
PORT=7777
ENABLE_ANYONE=true
HOSTNAME=localhost
ADMIN_WALLET=$ADMIN_WALLET
ENABLE_LOAD_BALANCING=true
SERVICE_DISCOVERY_TOPIC=debros-service-discovery
HEARTBEAT_INTERVAL=5000
STALE_PEER_TIMEOUT=30000
PEER_LOG_INTERVAL=60000
NODE_PUBLIC_ADDRESS=localhost
BOOTSTRAP_NODES=/ip4/188.166.113.190/tcp/7778/p2p/12D3KooWNWgs4WAUmE4CsxrL6uuyv1yuTzcRReMe5r7Psemsg2Z9,/ip4/82.208.21.140/tcp/7778/p2p/12D3KooWPUdpNX5N6dsuFAvgwfBMXUoFK2QS5sh8NpjxbfGpkSCi
MAX_CONNECTIONS=1000
LOAD_BALANCING_STRATEGY=least-loaded
ACCEPT_TERMS=true
KEY_PATH=./keys
LIBP2P_DEBUG=true
IPFS_DEBUG=true
LOG_LEVEL=debug
DEBUG=libp2p:*
EOF
    
    log "${GREEN}Development .env file created successfully${NOCOLOR}"
    log "Keys location: $KEY_DIR"
else
    log "${GREEN}Development .env file already exists${NOCOLOR}"
fi

# Make the script executable
chmod +x "$0"

log "${GREEN}Development environment setup complete${NOCOLOR}"