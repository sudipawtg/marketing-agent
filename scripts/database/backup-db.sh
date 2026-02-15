#!/bin/bash
set -e

# Backup database script
# Usage: ./backup-db.sh [environment]

ENVIRONMENT=${1:-staging}
BACKUP_DIR="./backups"

echo "========================================="
echo "Database Backup"
echo "Environment: $ENVIRONMENT"
echo "========================================="

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(staging|production|local)$ ]]; then
    echo "Error: Invalid environment. Must be local, staging, or production"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/marketing-agent-$ENVIRONMENT-$TIMESTAMP.sql.gz"

case $ENVIRONMENT in
    local)
        echo "Backing up local database..."
        docker-compose exec -T postgres pg_dump -U postgres marketing_agent | gzip > "$BACKUP_FILE"
        ;;
    staging|production)
        NAMESPACE="$ENVIRONMENT"
        echo "Finding postgres pod in $NAMESPACE..."
        POD=$(kubectl get pod -n $NAMESPACE -l app=postgres -o jsonpath='{.items[0].metadata.name}')
        
        if [ -z "$POD" ]; then
            echo "Error: No postgres pod found"
            exit 1
        fi
        
        echo "Using pod: $POD"
        echo "Creating backup..."
        kubectl exec -n $NAMESPACE $POD -- pg_dump -U postgres marketing_agent | gzip > "$BACKUP_FILE"
        ;;
esac

echo ""
echo "Backup completed successfully!"
echo "Backup file: $BACKUP_FILE"
echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)"

# Keep only last 30 days of backups
echo "Cleaning up old backups (keeping last 30 days)..."
find "$BACKUP_DIR" -name "marketing-agent-*.sql.gz" -mtime +30 -delete

echo "Done!"
