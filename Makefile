# Makefile for Marketing Agent CI/CD operations

.PHONY: help install test lint format build deploy clean

# Variables
PYTHON := python3.11
PIP := $(PYTHON) -m pip
ENVIRONMENT ?= staging
VERSION ?= latest

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Development
install: ## Install dependencies
	$(PIP) install --upgrade pip
	$(PIP) install -e ".[dev]"
	cd frontend && npm ci

install-pre-commit: ## Install pre-commit hooks
	$(PIP) install pre-commit
	pre-commit install
	pre-commit install --hook-type commit-msg

# Testing
test: ## Run all tests
	pytest tests/ -v

test-unit: ## Run unit tests
	pytest tests/unit/ -v

test-integration: ## Run integration tests
	pytest tests/integration/ -v

test-coverage: ## Run tests with coverage
	pytest tests/ -v --cov=src --cov-report=html --cov-report=term

# Code quality
lint: ## Run linters
	black --check src/ tests/
	ruff check src/ tests/
	mypy src/
	cd frontend && npm run lint

format: ## Format code
	black src/ tests/
	ruff check --fix src/ tests/
	cd frontend && npm run lint --fix

security-scan: ## Run security scans
	bandit -r src/
	safety check
	pip-audit

# Docker
docker-build: ## Build Docker images
	docker-compose build

docker-up: ## Start Docker containers
	docker-compose up -d

docker-down: ## Stop Docker containers
	docker-compose down

docker-logs: ## View Docker logs
	docker-compose logs -f

docker-push: ## Build and push Docker images
	./scripts/build-and-push.sh $(VERSION)

# Database
db-migrate: ## Run database migrations
	alembic upgrade head

db-rollback: ## Rollback last migration
	alembic downgrade -1

db-backup: ## Backup database
	./scripts/backup-db.sh $(ENVIRONMENT)

# Deployment
deploy-staging: ## Deploy to staging
	./scripts/deploy.sh staging $(VERSION)

deploy-production: ## Deploy to production
	./scripts/deploy.sh production $(VERSION)

deploy-canary: ## Deploy canary
	./scripts/deploy.sh canary $(VERSION)

rollback: ## Rollback deployment
	./scripts/rollback.sh $(ENVIRONMENT)

health-check: ## Run health checks
	./scripts/health-check.sh $(ENVIRONMENT)

# Kubernetes
k8s-apply: ## Apply Kubernetes manifests
	kubectl apply -k infrastructure/k8s/$(ENVIRONMENT)

k8s-delete: ## Delete Kubernetes resources
	kubectl delete -k infrastructure/k8s/$(ENVIRONMENT)

k8s-logs: ## View Kubernetes logs
	kubectl logs -f -l app=marketing-agent -n $(ENVIRONMENT)

k8s-pods: ## List Kubernetes pods
	kubectl get pods -n $(ENVIRONMENT) -l app=marketing-agent

k8s-describe: ## Describe Kubernetes resources
	kubectl describe deployment/marketing-agent-backend -n $(ENVIRONMENT)
	kubectl describe deployment/marketing-agent-frontend -n $(ENVIRONMENT)

# CI/CD
ci-test: ## Run CI tests locally
	docker-compose -f docker-compose.test.yml up --abort-on-container-exit

ci-build: ## Build for CI
	$(MAKE) lint
	$(MAKE) test
	$(MAKE) docker-build

# Clean
clean: ## Clean up generated files
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".mypy_cache" -exec rm -rf {} +
	find . -type d -name "htmlcov" -exec rm -rf {} +
	rm -rf dist/ build/
	cd frontend && rm -rf dist/ node_modules/.cache/

clean-all: clean ## Clean up all generated files including dependencies
	rm -rf .venv/
	cd frontend && rm -rf node_modules/

# Local development
dev: ## Start development servers
	$(MAKE) docker-up
	cd frontend && npm run dev

dev-backend: ## Start backend development server
	uvicorn src.api.main:app --reload --host 0.0.0.0 --port 8000

dev-frontend: ## Start frontend development server
	cd frontend && npm run dev

# Documentation
docs: ## Generate documentation
	@echo "Generating documentation..."
	@echo "Documentation available in docs/"
