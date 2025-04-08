#!/bin/bash

# Navigate to project root
cd "$(dirname "$(dirname "$(readlink -f "$0")")")"

# Generate development environment if needed
./scripts/generate-dev-env.sh

# Start the development container
docker-compose -f docker-compose.dev.yml up --build