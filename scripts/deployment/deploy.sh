#!/bin/bash
set -e

# Deployment script for Marketing Agent
# Usage: ./deploy.sh [environment] [version]

ENVIRONMENT=${1:-staging}
VERSION=${2:-latest}

echo "========================================="
echo "Marketing Agent Deployment"
echo "Environment: $ENVIRONMENT"
echo "Version: $VERSION"
echo "========================================="

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(staging|production|canary)$ ]]; then
    echo "Error: Invalid environment. Must be staging, production, or canary"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    exit 1
fi

# Check if kustomize is installed
if ! command -v kustomize &> /dev/null; then
    echo "Warning: kustomize is not installed. Using kubectl kustomize instead"
    KUSTOMIZE_CMD="kubectl kustomize"
else
    KUSTOMIZE_CMD="kustomize"
fi

# Set kubectl context based on environment
case $ENVIRONMENT in
    staging)
        CONTEXT="staging-cluster"
        NAMESPACE="staging"
        ;;
    production)
        CONTEXT="production-cluster"
        NAMESPACE="production"
        ;;
    canary)
        CONTEXT="production-cluster"
        NAMESPACE="production"
        ;;
esac

echo "Setting kubectl context to $CONTEXT..."
kubectl config use-context $CONTEXT || {
    echo "Error: Failed to set context. Please ensure $CONTEXT exists"
    exit 1
}

# Update image tags if version specified
if [ "$VERSION" != "latest" ]; then
    echo "Updating image tags to version $VERSION..."
    cd "infrastructure/k8s/$ENVIRONMENT"
    $KUSTOMIZE_CMD edit set image \
        ghcr.io/your-org/marketing-agent-backend=ghcr.io/your-org/marketing-agent-backend:$VERSION \
        ghcr.io/your-org/marketing-agent-frontend=ghcr.io/your-org/marketing-agent-frontend:$VERSION
    cd -
fi

# Generate and view manifests
echo "Generating Kubernetes manifests..."
$KUSTOMIZE_CMD build "infrastructure/k8s/$ENVIRONMENT" > /tmp/k8s-manifests-$ENVIRONMENT.yaml

echo "Preview of manifests to be applied:"
echo "---"
head -50 /tmp/k8s-manifests-$ENVIRONMENT.yaml
echo "..."
echo "---"

# Confirm deployment
read -p "Do you want to proceed with deployment? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

# Apply manifests
echo "Applying Kubernetes manifests..."
kubectl apply -f /tmp/k8s-manifests-$ENVIRONMENT.yaml

# Wait for rollout
echo "Waiting for deployments to complete..."
kubectl rollout status deployment/marketing-agent-backend -n $NAMESPACE --timeout=5m
kubectl rollout status deployment/marketing-agent-frontend -n $NAMESPACE --timeout=5m

# Run post-deployment checks
echo "Running post-deployment health checks..."
sleep 10

# Check backend health
echo "Checking backend health..."
kubectl exec -n $NAMESPACE deployment/marketing-agent-backend -- curl -f http://localhost:8000/health || {
    echo "Warning: Backend health check failed"
}

# Check frontend health
echo "Checking frontend health..."
kubectl exec -n $NAMESPACE deployment/marketing-agent-frontend -- curl -f http://localhost/health || {
    echo "Warning: Frontend health check failed"
}

# Display deployment info
echo ""
echo "========================================="
echo "Deployment completed successfully!"
echo "========================================="
echo ""
echo "Deployment Information:"
kubectl get pods -n $NAMESPACE -l app=marketing-agent
echo ""
echo "Services:"
kubectl get svc -n $NAMESPACE -l app=marketing-agent
echo ""
echo "Ingress:"
kubectl get ingress -n $NAMESPACE

# Cleanup
rm /tmp/k8s-manifests-$ENVIRONMENT.yaml

echo ""
echo "Deployment complete!"
