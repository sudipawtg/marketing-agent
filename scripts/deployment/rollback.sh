#!/bin/bash
set -e

# Rollback script for Marketing Agent
# Usage: ./rollback.sh [environment] [revision]

ENVIRONMENT=${1:-staging}
REVISION=${2:-0}  # 0 means previous revision

echo "========================================="
echo "Marketing Agent Rollback"
echo "Environment: $ENVIRONMENT"
echo "Revision: $REVISION (0 = previous)"
echo "========================================="

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(staging|production)$ ]]; then
    echo "Error: Invalid environment. Must be staging or production"
    exit 1
fi

# Set namespace
case $ENVIRONMENT in
    staging)
        NAMESPACE="staging"
        ;;
    production)
        NAMESPACE="production"
        ;;
esac

# Confirm rollback
read -p "Are you sure you want to rollback $ENVIRONMENT? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Rollback cancelled"
    exit 0
fi

echo "Rolling back backend deployment..."
kubectl rollout undo deployment/marketing-agent-backend -n $NAMESPACE --to-revision=$REVISION

echo "Rolling back frontend deployment..."
kubectl rollout undo deployment/marketing-agent-frontend -n $NAMESPACE --to-revision=$REVISION

echo "Waiting for rollback to complete..."
kubectl rollout status deployment/marketing-agent-backend -n $NAMESPACE
kubectl rollout status deployment/marketing-agent-frontend -n $NAMESPACE

echo ""
echo "========================================="
echo "Rollback completed successfully!"
echo "========================================="
echo ""
kubectl get pods -n $NAMESPACE -l app=marketing-agent
