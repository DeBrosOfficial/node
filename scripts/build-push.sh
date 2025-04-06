# Define your version
VERSION="v0.0.10"

# Build and tag with both specific version and latest
docker buildx build --platform linux/amd64 \
  -t debros/node:$VERSION \
  -t debros/node:latest \
  . --push