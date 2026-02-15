#!/bin/bash
set -e

# Database migration script
# Usage: ./migrate-db.sh [environment] [command]

ENVIRONMENT=${1:-staging}
COMMAND=${2:-upgrade}  # upgrade, downgrade, history

echo "========================================="
echo "Database Migration"
echo "Environment: $ENVIRONMENT"
echo "Command: $COMMAND"
echo "========================================="

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(staging|production|local)$ ]]; then
    echo "Error: Invalid environment. Must be local, staging, or production"
    exit 1
fi

# Set namespace
case $ENVIRONMENT in
    staging)
        NAMESPACE="staging"
        POD_SELECTOR="app=marketing-agent,component=backend"
        ;;
    production)
        NAMESPACE="production"
        POD_SELECTOR="app=marketing-agent,component=backend"
        ;;
    local)
        # Run locally with Docker Compose
        docker-compose exec backend alembic $COMMAND head
        exit 0
        ;;
esac

# Get the backend pod
echo "Finding backend pod in $NAMESPACE..."
POD=$(kubectl get pod -n $NAMESPACE -l $POD_SELECTOR -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD" ]; then
    echo "Error: No backend pod found"
    exit 1
fi

echo "Using pod: $POD"

# Run migration command
case $COMMAND in
    upgrade)
        echo "Running database migrations..."
        kubectl exec -n $NAMESPACE $POD -- alembic upgrade head
        ;;
    downgrade)
        echo "Rolling back database migration..."
        kubectl exec -n $NAMESPACE $POD -- alembic downgrade -1
        ;;
    history)
        echo "Database migration history:"
        kubectl exec -n $NAMESPACE $POD -- alembic history
        ;;
    current)
        echo "Current database version:"
        kubectl exec -n $NAMESPACE $POD -- alembic current
        ;;
    *)
        echo "Error: Invalid command. Must be upgrade, downgrade, history, or current"
        exit 1
        ;;
esac

echo ""
echo "Migration command completed successfully!"
