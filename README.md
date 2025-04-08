# Installation

## Production Installation

Run this script for production deployment:

```bash
sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/DeBrosOfficial/node/refs/heads/main/scripts/install.sh)"
```

## Local Development

For local development, we have a streamlined workflow:

```bash
# Clone the repository
git clone https://github.com/DeBrosOfficial/node.git
cd node

# Start the development environment
./scripts/start-dev.sh
```

This will:
1. Automatically generate a `.env` file if it doesn't exist
2. Create development keys in the `keys/` directory
3. Start the Docker Compose development environment

## Stop and Clean (optional for debugging)

### Production

```bash
#!/bin/bash

sudo systemctl stop debros-node
sudo rm -rf /opt/debros-node
docker system prune -a
```

### Development

```bash
# Stop containers
docker-compose -f docker-compose.dev.yml down

# Clean environment (optional)
rm -rf ./keys ./.env ./orbitdb ./blockstore ./logs
```
