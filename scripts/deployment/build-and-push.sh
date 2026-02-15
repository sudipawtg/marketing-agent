#!/bin/bash
set -e

# Build and push Docker images
# Usage: ./build-and-push.sh [version] [registry]

VERSION=${1:-latest}
REGISTRY=${2:-ghcr.io/your-org}

echo "========================================="
echo "Building Docker Images"
echo "Version: $VERSION"
echo "Registry: $REGISTRY"
echo "========================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running"
    exit 1
fi

# Login to registry (if needed)
echo "Logging in to container registry..."
echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_ACTOR" --password-stdin || {
    echo "Warning: Failed to login to registry. You may need to login manually."
}

# Build backend image
echo "Building backend image..."
docker build \
    -t "$REGISTRY/marketing-agent-backend:$VERSION" \
    -t "$REGISTRY/marketing-agent-backend:latest" \
    -f infrastructure/docker/Dockerfile.backend \
    .

# Build frontend image
echo "Building frontend image..."
docker build \
    -t "$REGISTRY/marketing-agent-frontend:$VERSION" \
    -t "$REGISTRY/marketing-agent-frontend:latest" \
    -f infrastructure/docker/Dockerfile.frontend \
    ./frontend

# Push images
echo "Pushing backend image..."
docker push "$REGISTRY/marketing-agent-backend:$VERSION"
docker push "$REGISTRY/marketing-agent-backend:latest"

echo "Pushing frontend image..."
docker push "$REGISTRY/marketing-agent-frontend:$VERSION"
docker push "$REGISTRY/marketing-agent-frontend:latest"

echo ""
echo "========================================="
echo "Build and push completed successfully!"
echo "========================================="
echo ""
echo "Images:"
echo "  - $REGISTRY/marketing-agent-backend:$VERSION"
echo "  - $REGISTRY/marketing-agent-frontend:$VERSION"
