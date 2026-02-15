# Scripts Directory

This directory contains all automation scripts for the Marketing Agent platform, organized by purpose.

## 📁 Directory Structure

```
scripts/
├── README.md (this file)
├── setup/                  # Setup and installation scripts
├── demo/                   # Demo and development scripts
├── deployment/             # Deployment and CI/CD scripts
├── database/               # Database management scripts
├── monitoring/             # Monitoring and health check scripts
├── development/            # Development utilities
├── check_evaluation_thresholds.py
├── generate_evaluation_report.py
└── run_evaluation.py
```

## 🚀 Setup Scripts (`setup/`)

Scripts for initial project setup and environment configuration.

| Script | Description | Platform |
|--------|-------------|----------|
| `setup.ps1` | Complete Windows setup script | Windows PowerShell |

**Usage:**
```powershell
# Windows
.\scripts\setup\setup.ps1
```

## 🎮 Demo Scripts (`demo/`)

Scripts for running demos and starting the application for development.

| Script | Description | Platform |
|--------|-------------|----------|
| `run_demo.sh` | Run complete demo (backend + frontend) | Linux/macOS |
| `run_demo.ps1` | Run complete demo (backend + frontend) | Windows |
| `start_demo.ps1` | Start demo with detailed output | Windows |
| `start_frontend.sh` | Start frontend only | Linux/macOS |
| `start_frontend.ps1` | Start frontend only | Windows |
| `start_frontend_only.ps1` | Start frontend in standalone mode | Windows |
| `start_with_logs.ps1` | Start with verbose logging | Windows |

**Usage:**
```bash
# Linux/macOS - Full demo
./scripts/demo/run_demo.sh

# Linux/macOS - Frontend only
./scripts/demo/start_frontend.sh

# Windows - Full demo
.\scripts\demo\run_demo.ps1

# Windows - with detailed logs
.\scripts\demo\start_with_logs.ps1
```

## 🚀 Deployment Scripts (`deployment/`)

Scripts for deploying to various environments.

| Script | Description |
|--------|-------------|
| `build-and-push.sh` | Build Docker images and push to registry |
| `deploy.sh` | Deploy to Kubernetes cluster |
| `rollback.sh` | Rollback to previous deployment |

**Usage:**
```bash
# Build and push images
./scripts/deployment/build-and-push.sh

# Deploy to staging
./scripts/deployment/deploy.sh staging

# Deploy to production
./scripts/deployment/deploy.sh production

# Rollback
./scripts/deployment/rollback.sh
```

## 🗄️ Database Scripts (`database/`)

Scripts for database management and migrations.

| Script | Description |
|--------|-------------|
| `backup-db.sh` | Backup database |
| `migrate-db.sh` | Run database migrations |

**Usage:**
```bash
# Backup database
./scripts/database/backup-db.sh

# Run migrations
./scripts/database/migrate-db.sh
```

## 📊 Monitoring Scripts (`monitoring/`)

Health checks and monitoring utilities.

| Script | Description |
|--------|-------------|
| `health-check.sh` | Check application health |

**Usage:**
```bash
# Check application health
./scripts/monitoring/health-check.sh
```

## 🧪 Evaluation Scripts (Root)

Python scripts for running ML model evaluations.

| Script | Description |
|--------|-------------|
| `run_evaluation.py` | Run evaluation suite |
| `generate_evaluation_report.py` | Generate evaluation reports |
| `check_evaluation_thresholds.py` | Check if evaluations meet thresholds |

**Usage:**
```bash
# Run evaluations
python scripts/run_evaluation.py

# Generate report
python scripts/generate_evaluation_report.py

# Check thresholds
python scripts/check_evaluation_thresholds.py --threshold 0.8
```

## 🔧 Development Scripts (`development/`)

Utilities for local development.

*(Add development scripts here as needed)*

## 📝 Script Conventions

### Naming
- Use lowercase with hyphens: `my-script.sh`
- Include file extension: `.sh`, `.ps1`, `.py`
- Use descriptive names that indicate purpose

### Executable Permissions
All shell scripts should have execute permissions:
```bash
chmod +x scripts/**/*.sh
```

### Error Handling
All scripts should:
- Exit on error: `set -e` (bash)
- Provide clear error messages
- Return appropriate exit codes

### Documentation
Each script should include:
- Header comment explaining purpose
- Usage examples
- Required environment variables
- Prerequisites

## 🔐 Security Notes

- Never commit API keys or secrets in scripts
- Use environment variables for sensitive data
- Keep `.env` files out of version control
- Use secrets management for production

## 🤝 Contributing

When adding new scripts:
1. Place in appropriate subdirectory
2. Add execute permissions (`chmod +x`)
3. Update this README
4. Include usage documentation in script header

---

**Questions?** See [main documentation](../docs/README.md) or [CONTRIBUTING.md](../CONTRIBUTING.md)
