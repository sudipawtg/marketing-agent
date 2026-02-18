# GitHub Workflows Complete Guide

> **Comprehensive guide to all CI/CD workflows in `.github/workflows/`**

---

## Table of Contents

1. [Workflow Overview](#workflow-overview)
2. [ci.yml - Continuous Integration](#ciyml---continuous-integration)
3. [cd.yml - Continuous Deployment](#cdyml---continuous-deployment)
4. [security.yml - Security Scanning](#securityyml---security-scanning)
5. [evaluation.yml - AI Evaluation](#evaluationyml---ai-evaluation)
6. [pr-checks.yml - Pull Request Validation](#pr-checksyml---pull-request-validation)
7. [release.yml - Release Automation](#releaseyml---release-automation)
8. [labeler.yml - Automatic Labeling](#labeleryml---automatic-labeling)
9. [Issue Templates](#issue-templates)
10. [Best Practices](#best-practices)

---

## Workflow Overview

### What are GitHub Actions Workflows?

**GitHub Actions** is GitHub's built-in CI/CD automation platform. Workflows are automated processes defined in YAML files that run in response to events (pushes, PRs, schedules, etc.).

### Why Multiple Workflows?

each workflow has a **specific purpose**:
- **Separation of concerns**: Each workflow has one responsibility
- **Parallel execution**: Multiple workflows run simultaneously
- **Targeted triggers**: Only run what's needed when it's needed
- **Clear ownership**: Easy to understand what each workflow does

### Workflow Lifecycle

```
┌─────────────┐
│   Trigger   │ (push, PR, schedule, manual)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Jobs     │ (can run in parallel or sequence)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Steps    │ (sequential actions within a job)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Result    │ (✓ success, ✗ failure)
└─────────────┘
```

### All Workflows at a Glance

| Workflow | Purpose | Triggers | Duration |
|----------|---------|----------|----------|
| **ci.yml** | Code quality & tests | Push, PR | ~5-10 min |
| **cd.yml** | Deployment | Push to main, tags | ~15-20 min |
| **security.yml** | Security scans | Push, PR, daily | ~10-15 min |
| **evaluation.yml** | AI quality tests | PR, push, daily | ~8-12 min |
| **pr-checks.yml** | PR validation | PR opened/updated | ~3-5 min |
| **release.yml** | Create releases | Tag push | ~5-8 min |

---

## ci.yml - Continuous Integration

**🎯 Purpose**: Validate code quality before merging

### What It Does

1. **Backend Linting & Testing**
   - Runs Black (code formatter check)
   - Runs Ruff (fast linter)
   - Runs MyPy (type checking)
   - Runs pytest (unit & integration tests)
   - Measures code coverage

2. **Frontend Linting & Testing**
   - Runs Biome (linter & formatter)
   - Runs TypeScript compiler checks
   - Runs Jest tests
   - Checks bundle size

3. **Docker Build Testing**
   - Builds backend Docker image
   - Builds frontend Docker image
   - Validates Dockerfiles

4. **Smoke Tests**
   - Starts all services via docker-compose
   - Tests health endpoints
   - Validates service connectivity

### When It Runs

- ✅ Every push to any branch
- ✅ Every pull request
- ✅ Manual trigger

### How to Fix Failures

#### Black Failed
```bash
# Auto-fix formatting locally
black src/

# Check what would change (dry run)
black src/ --check --diff
```

#### Ruff Failed
```bash
# Auto-fix linting issues
ruff check src/ --fix

# Show all issues
ruff check src/
```

#### MyPy Failed
```bash
# Run type checking locally
mypy src/

# Common fix: Add type annotations
def my_function(name: str) -> str:
    return f"Hello {name}"
```

#### Tests Failed
```bash
# Run tests locally
pytest tests/ -v

# Run specific test
pytest tests/test_campaigns.py::test_create_campaign -v

# Run with coverage
pytest tests/ --cov=src --cov-report=html
```

### Key Configuration

```yaml
# Service containers (PostgreSQL & Redis)
services:
  postgres:
    image: postgres:15-alpine
    env:
      POSTGRES_DB: marketing_agent_test
    ports:
      - 5432:5432
    options: --health-cmd pg_isready

  redis:
    image: redis:7-alpine
    ports:
      - 6379:6379
```

**Why service containers?** Tests need real databases to run integration tests properly.

---

## cd.yml - Continuous Deployment

**🎯 Purpose**: Deploy code to staging/production environments

### Deployment Pipeline

```
┌──────────────┐
│ Build Images │ → Build Docker images for backend/frontend
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Push to GHCR │ → Push to GitHub Container Registry
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Staging    │ → Deploy to staging environment
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Production  │ → Deploy to production (main branch only)
└──────────────┘
       │
       ├───────────────────────────┐
       │                           │
       ▼                           ▼
┌──────────────┐          ┌────────────────┐
│ Blue-Green   │          │     Canary     │
│  Deployment  │          │   Deployment   │
└──────────────┘          └────────────────┘
```

### Deployment Strategies Explained

#### Rolling Update (Default)
- Updates pods gradually
- Always maintains some running pods
- Zero downtime
- Automatic rollback on failure

```yaml
strategy:
  rollingUpdate:
    maxUnavailable: 1  # Max 1 pod down at a time
    maxSurge: 1        # Max 1 extra pod during update
```

#### Canary Deployment
- Routes 10% of traffic to new version
- Monitors metrics for 5 minutes
- Auto-promotes if healthy
- Auto-rollback if errors detected

```
Old Version (90%)  ███████████▓░
New Version (10%)  █░
                    ↓
                [Monitor]
                    ↓
          Good? → Full rollout
          Bad?  → Rollback
```

#### Blue-Green Deployment
- Spin up complete new environment (Green)
- Switch traffic from old (Blue) to new (Green)
- Keep Blue running for quick rollback
- Shut down Blue after verification

```
Before:  Blue (100% traffic) ██████████
         Green (0% traffic)

During:  Blue (0% traffic)
         Green (100% traffic) ██████████

After:   Green (100% traffic) ██████████
         Blue (shut down)
```

### Environment Requirements

Each environment needs:
- Kubernetes cluster (EKS/GKE/AKS)
- Container registry access (GHCR)
- Database (PostgreSQL)
- Cache (Redis)
- Secrets configured in GitHub

### How to Deploy

#### Deploy to Staging
```bash
# Automatically deploys on push to `develop` branch
git push origin develop
```

#### Deploy to Production
```bash
# Create and push version tag
git tag -a v1.2.3 -m "Release 1.2.3"
git push origin v1.2.3

# Or push to main branch
git push origin main
```

#### Manual Deployment
- Go to repository → Actions → cd.yml
- Click "Run workflow"
- Select environment
- Click "Run"

### Troubleshooting Deployments

#### Image Pull Errors
```bash
# Check if image exists
docker pull gh cr.io/ORG/REPO:TAG

# Check registry authentication
kubectl get secret ghcr-secret -o yaml
```

#### Pod Not Starting
```bash
# Check pod status
kubectl get pods -n production

# View pod events
kubectl describe pod POD_NAME -n production

# Check logs
kubectl logs POD_NAME -n production

# Get events
kubectl get events -n production --sort-by='.lastTimestamp'
```

#### Database Migration Failed
```bash
# Manually run migration
kubectl exec -it deployment/backend -n production -- bash
alembic upgrade head
```

---

## security.yml - Security Scanning

**🎯 Purpose**: Multi-layered security scanning

### Security Layers

```
┌─────────────────────────────────────────┐
│  1. DEPENDENCY SCANNING                 │ ← Python & Node.js packages
├─────────────────────────────────────────┤
│  2. SAST (Code Analysis)                │ ← Your source code
├─────────────────────────────────────────┤
│  3. SECRET SCANNING                     │ ← Git history
├─────────────────────────────────────────┤
│  4. CONTAINER SCANNING                  │ ← Docker images
├─────────────────────────────────────────┤
│  5. IaC SCANNING                        │ ← Terraform/K8s/Dockerfiles
├─────────────────────────────────────────┤
│  6. LICENSE COMPLIANCE                  │ ← Legal review
└─────────────────────────────────────────┘
```

### 1. Dependency Scanning

**Tools**: Safety, pip-audit (Python) | npm audit (Node.js)

**What it finds**:
- Known vulnerable package versions (CVEs)
- Outdated dependencies
- Security advisories

**Example vulnerability**:
```
Package: requests==2.25.0
Severity: HIGH
CVE: CVE-2023-32681
Fix: Upgrade to requests>=2.31.0
```

**How to fix**:
```bash
# Update Python package
pip install --upgrade requests

# Update in pyproject.toml
requests = "^2.31.0"

# Update Node.js package
npm update axios
```

### 2. SAST - Static Application Security Testing

**Tools**: CodeQL (GitHub), Bandit (Python)

**What it finds**:
- SQL injection vulnerabilities
- Cross-site scripting (XSS)
- Command injection
- Path traversal
- Hardcoded secrets
- Weak cryptography

**Example issue**:
```python
# ❌ BAD: SQL Injection vulnerability
query = f"SELECT * FROM users WHERE id = {user_input}"

# ✅ GOOD: Parameterized query
query = "SELECT * FROM users WHERE id = ?"
cursor.execute(query, (user_input,))
```

**Common patterns to avoid**:
```python
# ❌ Never use eval/exec with user input
eval(user_input)

# ❌ Don't use shell=True with user input
subprocess.run(f"ls {user_input}", shell=True)

# ❌ Don't build SQL queries with f-strings
f"SELECT * FROM table WHERE name = '{name}'"

# ❌ weak cryptography
hashlib.md5(password.encode()).hexdigest()

# ✅ Use bcrypt/scrypt/argon2
bcrypt.hashpw(password.encode(), bcrypt.gensalt())
```

### 3. Secret Scanning

**Tool**: TruffleHog

**What it finds**:
- API keys (AWS, OpenAI, Stripe, etc.)
- Database passwords
- OAuth tokens
- Private keys
- JWT secrets

**If secrets are found** (🚨 CRITICAL):
1. **Rotate immediately!** Old secrets are compromised forever
2. Remove from git history (use `git filter-branch` or BFG Repo-Cleaner)
3. Add to `.gitignore`
4. Use environment variables or secret management

**Prevention**:
```bash
# Use pre-commit hooks
pip install pre-commit detect-secrets
pre-commit install

# Use environment variables
export OPENAI_API_KEY="sk-..."
export DATABASE_URL="postgresql://..."

# Use GitHub Secrets in workflows
env:
  OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
```

### 4. Container Image Scanning

**Tool**: Trivy

**What it finds**:
- Vulnerable OS packages (apt/apk packages in base image)
- Vulnerable application dependencies
- Misconfigurations
- Exposed secrets in layers

**Example finding**:
```
Image: python:3.11-slim
Vulnerability: CVE-2023-12345
Package: openssl
Severity: CRITICAL
Fixed in: openssl 3.0.10

Recommendation: Update base image to python:3.11-slim-bookworm
```

**Best practices**:
```dockerfile
# ✅ Use specific version tags (not :latest)
FROM python:3.11-slim-bookworm

# ✅ Use minimal images
FROM python:3.11-alpine  # Smaller = fewer vulnerabilities

# ✅ Use multi-stage builds
FROM python:3.11 AS builder
RUN pip install ...
FROM python:3.11-slim AS runtime
COPY --from=builder ...

# ✅ Don't run as root
USER nobody
```

### 5. Infrastructure as Code (IaC) Scanning

**Tool**: Checkov

**What it finds**:
- Overly permissive IAM policies
- Unencrypted storage
- Public security groups (0.0.0.0/0)
- Missing backup policies
- Running containers as root

**Example issues**:

```hcl
# ❌ S3 bucket without encryption
resource "aws_s3_bucket" "data" {
  bucket = "my-data"
}

# ✅ S3 bucket with encryption
resource "aws_s3_bucket" "data" {
  bucket = "my-data"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

```yaml
# ❌ Kubernetes pod running as root
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: app
    image: my-app

# ✅ Pod with security context
apiVersion: v1
kind: Pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
  containers:
  - name: app
    image: my-app
```

### 6. License Compliance

**Tools**: pip-licenses, license-checker

**License types**:

| License | Commercial Use | Must Open Source | Example |
|---------|----------------|------------------|---------|
| MIT | ✅ Yes | ❌ No | React, Lodash |
| Apache 2.0 | ✅ Yes | ❌ No | Kubernetes, TensorFlow |
| BSD | ✅ Yes | ❌ No | Django, Flask |
| GPL | ⚠️ Yes | ✅ YES! | Linux, MySQL |
| AGPL | ⚠️ Yes | ✅ YES (even SaaS) | MongoDB |

**What to watch for**:
- GPL/AGPL licenses = must open-source your code
- "No commercial use" licenses = can't use in business
- Unlicensed packages = legal uncertainty

### Viewing Security Results

1. Go to repository → **Security** tab
2. Click **Code scanning alerts**
3. Filter by severity: Critical, High, Medium, Low
4. Click alert for details and remediation advice

---

## evaluation.yml - AI Evaluation

**🎯 Purpose**: Test AI agent quality automatically

### Why AI Evaluation is Different

Unlike traditional software:
- **Probabilistic**: Same input can produce different outputs
- **Quality is subjective**: "Good" response needs human-like judgment
- **Continuous drift**: Models change, world knowledge updates
- **Cost-aware**: Token usage = real money

### The Evaluation Pipeline

```
┌─────────────────────┐
│  Golden Datasets    │ ← Curated test cases
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Run Through Agent  │ ← Generate responses
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Score Responses    │ ← Measure quality
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Check Thresholds   │ ← Pass/fail gate
└─────────────────────┘
```

### Quality Metrics

| Metric | What It Measures | Threshold | Example |
|--------|------------------|-----------|---------|
| **Relevance** | Is response on-topic? | 0.70 | User asks about CTR, agent talks about CTR (not CPC) |
| **Accuracy** | Are facts correct? | 0.70 | Agent says "CTR = clicks/impressions" (correct formula) |
| **Completeness** | All info provided? | 0.80 | User asks "why low CTR?", agent gives multiple reasons |
| **Coherence** | Well-structured? | 0.70 | Clear paragraphs, logical flow, no gibberish |
| **Safety** | No harmful content? | 1.00 | No hate speech, PII, dangerous advice |

### Golden Dataset Structure

```json
{
  "dataset": "campaign_optimization",
  "test_cases": [
    {
      "id": "test_001",
      "input": {
        "campaign_data": {
          "name": "Summer Sale 2024",
          "ctr": 0.5,  // Low CTR
          "impressions": 100000,
          "clicks": 500,
          "conversions": 10
        },
        "question": "Why is the CTR so low and how can I improve it?"
      },
      "expected_output": {
        "must_include": [
          "CTR is below industry average",
          "headline optimization",
          "audience targeting",
          "A/B testing"
        ],
        "must_not_include": [
          "increase budget",  // Not relevant to CTR
          "delete campaign"   // Too drastic
        ]
      },
      "scoring": {
        "relevance_weight": 0.3,
        "accuracy_weight": 0.3,
        "completeness_weight": 0.2,
        "coherence_weight": 0.2
      }
    }
  ]
}
```

### LangSmith Tracing

**LangSmith** = Observability platform for LLM applications

Captures for each LLM call:
- Input prompt (exact text sent to model)
- Output completion (model's response)
- Latency (time to first token, total time)
- Token count (prompt tokens + completion tokens)
- Cost ($0.03 per 1K GPT-4 tokens)
- Model parameters (temperature, max_tokens, etc.)

**How to use**:
1. Click LangSmith trace link in workflow logs
2. See conversation tree (user → agent → tool → agent)
3. Inspect each LLM call
4. Debug issues (why did agent give wrong answer?)

### Performance Benchmarking

Measures:
- **Latency**: Time to generate response
  - p50 (median): 1.2s
  - p95 (95th percentile): 3.5s
  - p99 (worst case): 8.0s
- **Token usage**: Tokens per request
  - Input: ~500 tokens
  - Output: ~300 tokens
  - Total: ~800 tokens/request
- **Cost**: Price per 1000 requests
  - GPT-4: ~$24 per 1K requests
  - GPT-3.5-turbo: ~$2 per 1K requests

### Regression Detection

Compares PR branch vs main:
```
Metric            Main    PR      Change
─────────────────────────────────────────
Pass Rate         92%     88%     -4% ❌
Relevance        0.85    0.82    -0.03 ⚠️
Latency (p95)    2.1s    2.3s    +0.2s ⚠️
Cost per 1K      $24     $26     +$2 ⚠️

❌ = Fails threshold, blocks PR
⚠️ = Warning, review recommended
 ✅ = Within acceptable range
```

### Troubleshooting Low Scores

#### Relevance Low (< 0.70)
- Agent going off-topic
- Fix: Improve system prompt, add constraints
- Example: "Always answer questions about marketing campaigns"

#### Accuracy Low (< 0.70)
- Agent making factual errors
- Fix: Add knowledge base, cite sources, use RAG
- Example: Incorrect CTR formula calculation

#### Completeness Low (< 0.80)
- Agent giving partial answers
- Fix: Improve prompts to request complete responses
- Example: Expand prompt: "List ALL factors affecting CTR"

#### Coherence Low (< 0.70)
- Agent output is messy/unclear
- Fix: Use structured output, add formatting instructions
- Example: "Respond in bullet points with clear headers"

#### Safety Violations
- Agent produced harmful content
- Fix: Add content filters, moderation layer
- Example: Use OpenAI moderation API

---

## pr-checks.yml - Pull Request Validation

**🎯 Purpose**: Automated PR quality checks

### What It Validates

#### 1. PR Title Format
Uses **Conventional Commits** standard:
```
<type>(<scope>): <description>

Examples:
✅ feat(campaigns): add budget optimization
✅ fix(auth): resolve JWT expiration bug
✅ docs: update API documentation
❌ Updated some stuff  (too vague)
❌ FEATURE: New thing  (wrong format)
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting)
- `refactor`: Code restructuring
- `perf`: Performance improvement
- `test`: Adding tests
- `build`: Build system changes
- `ci`: CI/CD changes
- `chore`: Maintenance tasks

**Why?** Enables automatic changelog generation and semantic versioning.

#### 2. Merge Conflicts
Checks if PR can merge cleanly with base branch.

**How it works**:
```bash
git merge-tree $(git merge-base HEAD origin/main) HEAD origin/main
# If output contains '<<<<<', merge conflict exists
```

**How to fix**:
```bash
git fetch origin
git merge origin/main
# Resolve conflicts
git add .
git commit
git push
```

#### 3. File Size Limits
Prevents large files (> 1MB) from being committed.

**Why?** Large files:
- Slow down git operations
- Bloat repository size
- Should use Git LFS instead

**How to fix**:
```bash
# Install Git LFS
git lfs install

# Track large files
git lfs track "*.psd"
git lfs track "*.mp4"

# Add .gitattributes
git add .gitattributes
git commit -m "Add Git LFS tracking"
```

#### 4. Code Complexity
Uses **Radon** to measure code complexity.

**Metrics**:
- **Cyclomatic Complexity**: Number of decision points
  - 1-5: Simple (✅ good)
  - 6-10: Moderate (⚠️ okay)
  - 11-20: Complex (⚠️ refactor recommended)
  - 21+: Very complex (❌ definitely refactor)

- **Maintainability Index**: 0-100 score
  - 85-100: Highly maintainable (✅)
  - 65-85: Moderately maintainable (⚠️)
  - 0-65: Difficult to maintain (❌)

**Example high complexity**:
```python
# ❌ Complexity = 12 (too many branches)
def process_user(user):
    if user.is_active:
        if user.has_subscription:
            if user.subscription_expired():
                if user.auto_renew:
                    renew_subscription(user)
                else:
                    send_renewal_reminder(user)
            else:
                grant_access(user)
        else:
            show_paywall(user)
    else:
        show_activation_required(user)

# ✅ Refactored (complexity = 4)
def process_user(user):
    if not user.is_active:
        return show_activation_required(user)
    
    if not user.has_subscription:
        return show_paywall(user)
    
    if user.subscription_expired():
        return handle_expired_subscription(user)
    
    return grant_access(user)
```

#### 5. Test Coverage
Ensures new code is tested.

**Requirement**: 70% minimum coverage

**How it works**:
``bash
pytest --cov=src --cov-report=term
# Fails if coverage < 70%
```

**Coverage Report in PR**:
```
File                    Stmts   Miss  Cover
─────────────────────────────────────────
src/campaigns.py          100     10    90%  ✅
src/auth.py              150     60    60%  ❌
src/analytics.py          80      8    90%  ✅
─────────────────────────────────────────
TOTAL                     330     78    77%  ✅
```

**How to improve coverage**:
```python
# Add tests for uncovered code
def test_campaign_creation():
    campaign = create_campaign(name="Test", budget=1000)
    assert campaign.name == "Test"
    assert campaign.budget == 1000
    assert campaign.status == "draft"
```

#### 6. Changed Files Analysis
Warns if source files changed but tests didn't.

**Logic**:
```
IF src/**/*.py changed
AND tests/**/*.py NOT changed
THEN warn: "Consider adding tests"
```

**Why?** Encourages test-driven development.

#### 7. Performance Impact Check
Runs benchmarks to detect performance regressions.

**Example**:
```
Benchmark          Main    PR      Change
──────────────────────────────────────────
API Response Time  120ms   135ms   +12% ⚠️
Database Query     45ms    44ms    -2% ✅
File Processing    2.1s    2.0s    -5% ✅
```

#### 8. Automatic Labeling
Labels PR based on changed files (see labeler.yml).

**Examples**:
- Changed `src/**/*.py` → Label: `backend`
- Changed `frontend/**/*` → Label: `frontend`
- Changed `docs/**/*` → Label: `documentation`
- Changed `.github/workflows/**/*` → Label: `ci-cd`

#### 9. PR Size Labeling
Labels PR by size:
- XS: 0-10 lines changed
- S: 11-100 lines changed
- M: 101-500 lines changed
- L: 501-1000 lines changed
- XL: 1000+ lines changed ⚠️

**Why?** Large PRs are hard to review. Break them up!

---

## release.yml - Release Automation

**🎯 Purpose**: Automate software releases

### Release Process

```
┌────────────────┐
│  Create Tag    │ ← git tag -a v1.2.3 -m "Release 1.2.3"
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Generate       │ ← Changelog from git commits
│ Changelog      │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Create GitHub  │ ← Release with notes & assets
│ Release        │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Build          │ ← Python package & frontend bundle
│ Artifacts      │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Update Docs    │ ← Version references in documentation
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Notify Team    │ ← Slack/email notifications
└────────────────┘
```

### Semantic Versioning

Format: `MAJOR.MINOR.PATCH` (e.g., `v2.3.1`)

- **MAJOR**: Breaking changes (v1.0.0 → v2.0.0)
  - Example: Removed API endpoint, changed response format
- **MINOR**: New features (backward compatible) (v1.0.0 → v1.1.0)
  - Example: Added new API endpoint, new feature
- **PATCH**: Bug fixes (v1.0.0 → v1.0.1)
  - Example: Fixed bug, security patch

### How to Create a Release

#### Option 1: Tag-Based Release (Recommended)
```bash
# 1. Create annotated tag
git tag -a v1.2.3 -m "Release version 1.2.3"

# 2. Push tag to GitHub
git push origin v1.2.3

# 3. Workflow automatically:
#    - Creates GitHub release
#    - Generates changelog
#    - Builds artifacts
#    - Updates documentation
```

#### Option 2: Manual Trigger
```bash
# Go to: Actions → release.yml → Run workflow
# Input: version = 1.2.3
# Click: Run workflow
```

### Changelog Generation

Parses git commits between releases:
```bash
# Get commits since last release
git log v1.2.2..v1.2.3 --pretty=format:"- %s (%h)"

# Output:
- feat(campaigns): add budget optimization (a1b2c3d)
- fix(auth): resolve JWT bug (e4f5g6h)
- docs: update API docs (i7j8k9l)
```

**Grouped by type**:
```markdown
## Features
- add budget optimization (#123)
- implement A/B testing (#124)

## Bug Fixes
- resolve JWT expiration bug (#125)
- fix database connection pool (#126)

## Documentation
- update API documentation (#127)
```

### Release Assets

**Python Package**:
```bash
# Built via setuptools
python -m build

# Creates:
# - dist/marketing-agent-1.2.3.tar.gz (source)
# - dist/marketing_agent-1.2.3-py3-none-any.whl (wheel)
```

**Frontend Bundle**:
```bash
# Built via Vite
npm run build

# Creates:
# - frontend/dist/ (optimized static files)
# Archived as frontend-dist-v1.2.3.tar.gz
```

### Release Notes Template

```markdown
## Release v1.2.3

### What's Changed
- feat(campaigns): add budget optimization (#123)
- fix(auth): resolve JWT expiration bug (#125)
- docs: update API documentation (#127)

### Docker Images
- Backend: `ghcr.io/ORG/REPO-backend:1.2.3`
- Frontend: `ghcr.io/ORG/REPO-frontend:1.2.3`

### Installation

**Using Docker Compose:**
```bash
docker-compose pull
docker-compose up -d
```

**Using Kubernetes:**
```bash
kubectl apply -f infrastructure/k8s/production/
```

### Breaking Changes
- None

### Deprecations
- `GET /api/v1/old-endpoint` (use `/api/v2/new-endpoint` instead)

### Full Changelog
https://github.com/ORG/REPO/compare/v1.2.2...v1.2.3
```

### Post-Release Actions

**Automatic**:
1. Updates `docs/**/*.md` with new version
2. Commits and pushes changes
3. Sends Slack notification (if configured)
4. Sends email notification (if configured)

**Manual**:
1. Verify deployment succeeded
2. Smoke test production
3. Update external documentation
4. Announce to users

---

## labeler.yml - Automatic Labeling

**🎯 Purpose**: Auto-label PRs based on changed files

### How It Works

When PR is opened/updated:
1. Checks which files changed
2. Matches file patterns
3. Applies corresponding labels

### Label Patterns

```yaml
# Backend label: Applied if Python files change
backend:
  - 'src/**/*.py'
  - 'tests/**/*.py'
  - 'pyproject.toml'

# Frontend label: Applied if frontend files change
frontend:
  - 'frontend/**/*'

# Documentation: Any markdown files
documentation:
  - 'docs/**/*'
  - '**/*.md'

# Infrastructure: DevOps files
infrastructure:
  - 'infrastructure/**/*'
  - 'docker-compose.yml'
  - '.github/**/*'

# Database: DB-related files
database:
  - 'src/database/**/*'
  - 'alembic/**/*'

# AI Agent: Agent code and prompts
agent:
  - 'src/agent/**/*'
  - 'prompts/**/*'

# API: API endpoints
api:
  - 'src/api/**/*'

# CI/CD: Workflow files
ci-cd:
  - '.github/workflows/**/*'

# Dependencies: Package files
dependencies:
  - 'pyproject.toml'
  - 'frontend/package.json'
```

### Label Benefits

1. **Filtering**: Find all backend PRs quickly
2. **Routing**: Notify right team (backend team sees backend label)
3. **Metrics**: Track how many frontend vs backend changes
4. **Required reviews**: Enforce reviews from specific teams

### Label Configuration

**In GitHub**:
- Settings → Labels
- Create labels with colors:
  - `backend` (blue)
  - `frontend` (green)
  - `documentation` (yellow)
  - `infrastructure` (purple)

**Automatic** application via workflow:
```yaml
- uses: actions/labeler@v5
  with:
    repo-token: ${{ secrets.GITHUB_TOKEN }}
    configuration-path: .github/labeler.yml
```

---

## Issue Templates

Located in `.github/ISSUE_TEMPLATE/`

### Purpose

Standardize issue reporting with structured forms.

### Templates Overview

#### 1. bug_report.md

**When to use**: Something is broken

**Sections**:
- Bug description
- Steps to reproduce
- Expected vs actual behavior
- Environment (browser, OS, version)
- Logs/screenshots
- Possible solution

**Why structured?** Ensures reporters provide enough info to fix bug.

#### 2. cicd_issue.md

**When to use**: CI/CD pipeline problems

**Sections**:
- Issue type (workflow failure, deployment issue, etc.)
- Which workflow/job failed
- Error message
- Recent changes
- Impact (blocking deployments?)

**Special fields**:
- Workflow URL link
- Commit SHA
- Environment (staging/production)

#### 3. feature_request.md

**When to use**: Proposing new functionality

**Sections**:
- Feature description
- Problem it solves
- Proposed solution
- Alternatives considered
- Implementation considerations (frontend/backend/DB changes)
- Priority level
- Success criteria

**Helps with**:
- Prioritization
- Implementation planning
- Understanding requirements

### How to Use

When creating issue on GitHub:
1. Click "New issue"
2. See template options
3. Choose appropriate template
4. Fill in all sections
5. Submit

**Auto-labeling**: Issues from templates get automatic labels:
- Bug report → `bug` + `needs-triage`
- Feature request → `enhancement` + `needs-triage`
- CI/CD issue → `ci-cd` + `infrastructure`

---

## Best Practices

### Workflow Design

✅ **DO**:
- Keep workflows focused (one responsibility)
- Use descriptive job/step names
- Add comments explaining complex logic
- Use path filters to avoid unnecessary runs
- Cache dependencies (pip, npm)
- Run cheap checks first (linting before testing)
- Fail fast (don't waste time if early step fails)

❌ **DON'T**:
- Put everything in one giant workflow
- Delete logs (keep artifacts for 30 days)
- Skip security scans (they're critical!)
- Use `latest` tags in production
- Hardcode secrets (use GitHub Secrets)

### Performance Optimization

```yaml
# ✅ Cache dependencies
- uses: actions/setup-python@v5
  with:
    cache: 'pip'  # Saves 30-60 seconds

# ✅ Run jobs in parallel
jobs:
  backend:
    runs-on: ubuntu-latest
  frontend:
    runs-on: ubuntu-latest  # Parallel with backend

# ✅ Use path filters
on:
  push:
    paths:
      - 'src/**'  # Only run if src/ changes

# ✅ Use concurrency groups (cancel old runs)
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### Security Best Practices

```yaml
# ✅ Minimize permissions
permissions:
  contents: read  # Only what's needed

# ✅ Use GITHUB_TOKEN (auto-generated)
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

# ✅ Store secrets in GitHub Secrets
env:
  API_KEY: ${{ secrets.API_KEY }}

# ❌ Don't echo secrets
run: echo ${{ secrets.API_KEY }}  # Visible in logs!

# ✅ Mask secrets if printing
run: echo "::add-mask::${{ secrets.API_KEY }}"
```

### Debugging Workflows

#### View Logs
1. Go to repository → Actions
2. Click workflow run
3. Click failed job
4. Expand failed step
5. Read error message

#### Enable Debug Logging
Settings → Secrets → Add:
- `ACTIONS_RUNNER_DEBUG` = `true`
- `ACTIONS_STEP_DEBUG` = `true`

#### Run Locally
Use **act** to run GitHub Actions locally:
```bash
# Install act
brew install act

# Run workflow
act push

# Run specific job
act -j backend-lint-and-test
```

#### Common Issues

**"Resource not accessible by integration"**
- Fix: Add required permissions to workflow

**"Docker credential helper error"**
- Fix: Check GHCR credentials are set

**"No space left on device"**
- Fix: Clean up Docker images: `docker system prune -af`

**Workflow doesn't trigger**
- Check trigger conditions (branches, paths)
- Check if workflow file has syntax errors
- Check if workflow is enabled (Actions settings)

### Monitoring Workflows

#### GitHub Insights
- Repository → Insights → Actions
- See workflow run times, success rates
- Identify slow/flaky workflows

#### Metrics to Track
- **Success rate**: Should be > 95%
- **Duration**: Aim for < 10 minutes for CI
- **Concurrency**: How many runs are queued
- **Cost**: Enterprise plans show Action minutes used

#### Notifications
```yaml
# Send Slack notification on failure
- name: Notify Slack
  if: failure()
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
      -d '{"text": "Workflow failed: ${{ github.workflow }}"}'
```

---

## Quick Reference

### Workflow Triggers

```yaml
# On push to any branch
on: push

# On push to specific branches
on:
  push:
    branches: [main, develop]

# On pull request
on: pull_request

# On tag push
on:
  push:
    tags:
      - 'v*.*.*'

# On schedule (cron)
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM

# Manual trigger
on: workflow_dispatch

# Multiple events
on: [push, pull_request]

# With filters
on:
  push:
    branches: [main]
    paths:
      - 'src/**'
      - '!docs/**'  # Ignore docs
```

### Job Dependencies

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building..."
  
  test:
    needs: build  # Wait for build
    runs-on: ubuntu-latest
    steps:
      - run: echo "Testing..."
  
  deploy:
    needs: [build, test]  # Wait for both
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying..."
```

### Environment Variables

```yaml
env:
  GLOBAL_VAR: value  # All jobs

jobs:
  my-job:
    env:
      JOB_VAR: value  # This job only
    steps:
      - name: Step with env
        env:
          STEP_VAR: value  # This step only
        run: echo $STEP_VAR
```

### Conditional Execution

```yaml
# Run only on main branch
- name: Deploy
  if: github.ref == 'refs/heads/main'
  run: ./deploy.sh

# Run only on pull requests
- name: Comment on PR
  if: github.event_name == 'pull_request'
  run: ./comment.sh

# Run only if previous step failed
- name: Cleanup
  if: failure()
  run: ./cleanup.sh

# Run only if previous step succeeded
- name: Celebrate
  if: success()
  run: echo "Success!"

# Run always (even if failed)
- name: Upload logs
  if: always()
  uses: actions/upload-artifact@v4
```

### Artifacts

```yaml
# Upload
- uses: actions/upload-artifact@v4
  with:
    name: test-results
    path: test-results/
    retention-days: 30

# Download (in different job)
- uses: actions/download-artifact@v4
  with:
    name: test-results
    path: ./results
```

### Matrix Builds

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        python-version: ['3.9', '3.10', '3.11']
    steps:
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
      - run: pytest
```

### Outputs

```yaml
jobs:
  build:
    outputs:
      version: ${{ steps.get_version.outputs.version }}
    steps:
      - id: get_version
        run: echo "version=1.2.3" >> $GITHUB_OUTPUT
  
  deploy:
    needs: build
    steps:
      - run: echo "Deploying version ${{ needs.build.outputs.version }}"
```

---

## Troubleshooting Guide

### Workflow Not Triggering

**Symptoms**: Push code but workflow doesn't start

**Causes & Fixes**:
1. **YAML syntax error**
   ```bash
   # Validate YAML
   yamllint .github/workflows/ci.yml
   ```

2. **Path filter excludes change**
   ```yaml
   # If you changed docs but workflow has:
   paths:
     - 'src/**'  # Won't trigger
   ```

3. **Branch name doesn't match**
   ```yaml
   # If you're on `feature/test` but workflow has:
   branches: [main, develop]  # Won't trigger
   ```

4. **Workflow is disabled**
   - Check: Actions → Workflows → Enable workflow

### Workflow Always Failing

**Symptoms**: Same workflow fails repeatedly

**Debugging steps**:
1. Check logs in Actions tab
2. Look for error keywords
3. Search GitHub issues for error message
4. Run commands locally
5. Check secrets are set correctly

**Common causes**:
- Missing environment variables
- Incorrect permissions
- Service unavailable (npm registry down)
- Flaky tests (random failures)

### Workflow Taking Too Long

**Target times**:
- CI: < 10 minutes
- Security: < 15 minutes
- Deployment: < 20 minutes

**Optimization strategies**:
1. **Cache dependencies**
   ```yaml
   - uses: actions/setup-python@v5
     with:
       cache: 'pip'
   ```

2. **Run jobs in parallel**
   ```yaml
   jobs:
     backend: ...
     frontend: ...  # Parallel
   ```

3. **Use path filters**
   ```yaml
   on:
     push:
       paths:
         - 'src/**'  # Skip if only docs changed
   ```

4. **Cancel redundant runs**
   ```yaml
   concurrency:
     group: ${{ github.workflow }}-${{ github.ref }}
     cancel-in-progress: true
   ```

5. **Use faster runners**
   ```yaml
   runs-on: ubuntu-latest  # Faster than others
   ```

---

## Conclusion

You now have comprehensive understanding of all GitHub workflows! Each workflow serves a specific purpose in the CI/CD pipeline:

1. **ci.yml**: Quality gate (linting, testing)
2. **cd.yml**: Deployment automation
3. **security.yml**: Multi-layered security scanning
4. **evaluation.yml**: AI quality assurance
5. **pr-checks.yml**: PR validation
6. **release.yml**: Release automation

**Key Takeaways**:
- Workflows should be focused and fast
- Security scanning is non-negotiable
- Test everything before deploying
- Monitor and optimize continuously
- Document your processes

**Further Reading**:
- [CI_CD_COMPLETE_GUIDE.md](CI_CD_COMPLETE_GUIDE.md) - Deep dive into CI/CD concepts
- [CI_CD_QUICK_REFERENCE.md](CI_CD_QUICK_REFERENCE.md) - Command cheatsheet
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

Happy deploying! 🚀
