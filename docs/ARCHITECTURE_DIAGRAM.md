# CI/CD Architecture Diagram

## Complete Pipeline Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            DEVELOPER WORKSTATION                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. Code Changes → 2. Pre-commit Hooks → 3. Git Push                       │
│                      (format, lint,                                          │
│                       security scan)                                         │
│                                                                              │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GITHUB ACTIONS                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                       CI PIPELINE (ci.yml)                           │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │                                                                      │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │   │
│  │  │   Backend    │  │   Frontend   │  │    Docker    │             │   │
│  │  │ Lint & Test  │  │ Lint & Build │  │  Build Test  │             │   │
│  │  ├──────────────┤  ├──────────────┤  ├──────────────┤             │   │
│  │  │ • Black      │  │ • ESLint     │  │ • Backend    │             │   │
│  │  │ • Ruff       │  │ • TypeScript │  │   Image      │             │   │
│  │  │ • MyPy       │  │ • Build      │  │ • Frontend   │             │   │
│  │  │ • Pytest     │  │              │  │   Image      │             │   │
│  │  │ • Coverage   │  │              │  │              │             │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘             │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                  │                                           │
│                                  ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                   SECURITY SCANNING (security.yml)                   │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │                                                                      │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │   │
│  │  │ Dependency   │  │    SAST      │  │  Container   │             │   │
│  │  │   Scanning   │  │   CodeQL     │  │   Scanning   │             │   │
│  │  ├──────────────┤  ├──────────────┤  ├──────────────┤             │   │
│  │  │ • Safety     │  │ • Code       │  │ • Trivy      │             │   │
│  │  │ • pip-audit  │  │   Analysis   │  │ • Image      │             │   │
│  │  │ • npm audit  │  │ • Bandit     │  │   Vulns      │             │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘             │   │
│  │                                                                      │   │
│  │  ┌──────────────┐  ┌──────────────┐                                │   │
│  │  │   Secret     │  │     IaC      │                                │   │
│  │  │   Scanning   │  │   Scanning   │                                │   │
│  │  ├──────────────┤  ├──────────────┤                                │   │
│  │  │ • TruffleHog │  │ • Checkov    │                                │   │
│  │  │ • Detect     │  │ • K8s        │                                │   │
│  │  │   Secrets    │  │ • Terraform  │                                │   │
│  │  └──────────────┘  └──────────────┘                                │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                  │                                           │
│                                  ▼                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    PR CHECKS (pr-checks.yml)                         │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │                                                                      │   │
│  │  • PR Title Validation          • Test Coverage Check               │   │
│  │  • Merge Conflict Detection     • Changed Files Analysis            │   │
│  │  • Code Complexity Analysis     • Performance Benchmarks            │   │
│  │  • Auto Labeling                • Size Labeling                     │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                  │                                           │
└──────────────────────────────────┼───────────────────────────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
                    ▼                             ▼
         ┌────────────────────┐        ┌────────────────────┐
         │   PULL REQUEST     │        │   MERGE TO MAIN    │
         │      REVIEW        │        │                    │
         └────────────────────┘        └──────────┬─────────┘
                                                  │
                                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CD PIPELINE (cd.yml)                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                    BUILD & PUSH DOCKER IMAGES                         │  │
│  ├──────────────────────────────────────────────────────────────────────┤  │
│  │                                                                       │  │
│  │  • Multi-arch build (amd64, arm64)                                   │  │
│  │  • Push to GitHub Container Registry (ghcr.io)                       │  │
│  │  • Tag with version, branch, SHA                                     │  │
│  │  • Cache layers for faster builds                                    │  │
│  │                                                                       │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                  │                                           │
│                                  ▼                                           │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                      DEPLOY TO STAGING                                │  │
│  ├──────────────────────────────────────────────────────────────────────┤  │
│  │                                                                       │  │
│  │  1. Configure kubectl context                                        │  │
│  │  2. Run database migrations                                          │  │
│  │  3. Update backend deployment (2 replicas)                           │  │
│  │  4. Update frontend deployment (1 replica)                           │  │
│  │  5. Wait for rollout completion                                      │  │
│  │  6. Health checks                                                    │  │
│  │  7. Post-deployment tests                                            │  │
│  │                                                                       │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                  │                                           │
│                   ┌──────────────┴───────────────┐                          │
│                   │                               │                          │
│                   ▼                               ▼                          │
│  ┌────────────────────────────┐   ┌─────────────────────────────┐          │
│  │    CANARY DEPLOYMENT       │   │   PRODUCTION DEPLOYMENT     │          │
│  │  (Manual Trigger)          │   │   (Version Tags Only)       │          │
│  ├────────────────────────────┤   ├─────────────────────────────┤          │
│  │                            │   │                             │          │
│  │  1. Deploy to 10% traffic  │   │  1. Database backup         │          │
│  │  2. Monitor for 5 min      │   │  2. Run migrations          │          │
│  │  3. Check metrics          │   │  3. Update deployments      │          │
│  │  4. Promote or rollback    │   │     (5 backend, 3 frontend) │          │
│  │                            │   │  4. Health checks           │          │
│  │                            │   │  5. Verification            │          │
│  │                            │   │  6. Notifications           │          │
│  │                            │   │                             │          │
│  └────────────────────────────┘   └─────────────────────────────┘          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          KUBERNETES CLUSTER                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                         STAGING NAMESPACE                             │  │
│  ├──────────────────────────────────────────────────────────────────────┤  │
│  │                                                                       │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │  │
│  │  │   Backend    │  │   Frontend   │  │  PostgreSQL  │              │  │
│  │  │  (2 pods)    │  │   (1 pod)    │  │   (1 pod)    │              │  │
│  │  │  + HPA       │  │  + HPA       │  │              │              │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘              │  │
│  │                                                                       │  │
│  │  ┌──────────────┐  ┌──────────────┐                                 │  │
│  │  │    Redis     │  │   Ingress    │                                 │  │
│  │  │   (1 pod)    │  │   (NGINX)    │                                 │  │
│  │  └──────────────┘  └──────────────┘                                 │  │
│  │                                                                       │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                       PRODUCTION NAMESPACE                            │  │
│  ├──────────────────────────────────────────────────────────────────────┤  │
│  │                                                                       │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │  │
│  │  │   Backend    │  │   Frontend   │  │  PostgreSQL  │              │  │
│  │  │  (5 pods)    │  │   (3 pods)   │  │  (StatefulSet│              │  │
│  │  │  + HPA       │  │  + HPA       │  │   with PVC)  │              │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘              │  │
│  │                                                                       │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │  │
│  │  │    Redis     │  │   Ingress    │  │  CronJob     │              │  │
│  │  │   (1 pod)    │  │   (NGINX)    │  │  (Backups)   │              │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘              │  │
│  │                                                                       │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       MONITORING & OBSERVABILITY                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │  Prometheus  │  │   Grafana    │  │    Sentry    │  │     Logs     │   │
│  │   Metrics    │  │  Dashboards  │  │  Error       │  │  Aggregation │   │
│  │              │  │              │  │  Tracking    │  │              │   │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### Pre-commit Hooks
- Run locally before code is committed
- Fast feedback loop
- Prevents bad code from reaching CI

### CI Pipeline
- Runs on every push and PR
- Parallel execution for speed
- Multiple test types (unit, integration, smoke)
- Code coverage tracking with Codecov

### Security Scanning
- Runs on push, PR, and daily schedule
- Multiple security tools for comprehensive coverage
- Results uploaded to GitHub Security tab
- Blocking on critical vulnerabilities (configurable)

### PR Checks
- Automated validation and labeling
- Code quality metrics
- Performance regression detection
- Test coverage enforcement (70% minimum)

### CD Pipeline
- Automatic staging deployment on main merge
- Manual production deployment with approval gates
- Canary deployment for gradual rollout
- Comprehensive health checks at each stage

### Kubernetes Deployment
- Environment-specific configurations
- Horizontal Pod Autoscaling (HPA)
- Resource limits and requests
- Health checks (liveness, readiness)
- Database backups via CronJob

### Monitoring
- Prometheus for metrics collection
- Grafana for visualization
- Sentry for error tracking
- Centralized logging

## Key Features

✅ **Fully Automated** - Minimal manual intervention  
✅ **Production Ready** - Enterprise-grade security and reliability  
✅ **Scalable** - Auto-scaling based on load  
✅ **Observable** - Comprehensive monitoring and logging  
✅ **Secure** - Multiple security scanning layers  
✅ **Fast** - Parallel execution and caching  
✅ **Reliable** - Health checks and automatic rollback  
✅ **Developer Friendly** - Clear feedback and documentation
