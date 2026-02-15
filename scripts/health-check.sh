#!/bin/bash
set -e

# Health check script
# Usage: ./health-check.sh [environment]

ENVIRONMENT=${1:-staging}

echo "========================================="
echo "Health Check"
echo "Environment: $ENVIRONMENT"
echo "========================================="

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(staging|production|local)$ ]]; then
    echo "Error: Invalid environment. Must be local, staging, or production"
    exit 1
fi

check_http_endpoint() {
    local url=$1
    local name=$2
    
    echo -n "Checking $name... "
    if curl -sf "$url" > /dev/null; then
        echo "✓ OK"
        return 0
    else
        echo "✗ FAILED"
        return 1
    fi
}

case $ENVIRONMENT in
    local)
        echo "Checking local services..."
        check_http_endpoint "http://localhost:8000/health" "Backend API"
        check_http_endpoint "http://localhost:5173/health" "Frontend" || echo "Note: Frontend might not have health endpoint"
        check_http_endpoint "http://localhost:5432" "PostgreSQL" || echo "Note: Direct PostgreSQL check may fail"
        ;;
    
    staging)
        echo "Checking staging services..."
        check_http_endpoint "https://api.staging.marketing-agent.example.com/health" "Backend API"
        check_http_endpoint "https://staging.marketing-agent.example.com" "Frontend"
        
        echo ""
        echo "Kubernetes pod status:"
        kubectl get pods -n staging -l app=marketing-agent
        ;;
    
    production)
        echo "Checking production services..."
        check_http_endpoint "https://api.marketing-agent.example.com/health" "Backend API"
        check_http_endpoint "https://marketing-agent.example.com" "Frontend"
        
        echo ""
        echo "Kubernetes pod status:"
        kubectl get pods -n production -l app=marketing-agent
        ;;
esac

echo ""
echo "Health check completed!"
