# Installation

## Run this script:

```bash
sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/DeBrosOfficial/node/refs/heads/main/scripts/install.sh)"
```

## Stop and Clean (optional for debugging)

```bash
#!/bin/bash

sudo systemctl stop debros-node
sudo rm -rf /opt/debros-node
docker system prune -a
```
