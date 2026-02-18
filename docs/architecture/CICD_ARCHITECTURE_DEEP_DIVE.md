# CI/CD Architecture Deep Dive for AI Agents

> **Production-Grade CI/CD Pipeline for AI Agentic Systems**
> 
> Comprehensive guide to building robust, automated deployment pipelines for AI agents with emphasis on quality gates, evaluation, and safe rollouts.

---

## Table of Contents

1. [Pipeline Architecture](#pipeline-architecture)
2. [Testing Strategy](#testing-strategy)
3. [Quality Gates](#quality-gates)
4. [Deployment Strategies](#deployment-strategies)
5. [Monitoring & Feedback](#monitoring--feedback)
6. [Rollback Procedures](#rollback-procedures)

---

## Pipeline Architecture

### Multi-Stage Pipeline Design

```yaml
# .github/workflows/ai-agent-cicd.yml
name: AI Agent CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  schedule:
    - cron: '0 2 * * *'  # Daily evaluation

env:
  PYTHON_VERSION: '3.11'
  NODE_VERSION: '18'

jobs:
  #────────────────────────────────────────────────────────────
  # STAGE 1: Code Quality & Security
  #────────────────────────────────────────────────────────────
  code-quality:
    name: Code Quality & Security
    runs-on: ubuntu-latest
    timeout-minutes: 10
    
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for better analysis
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
      
      # Linting
      - name: Run Ruff
        run: |
          pip install ruff
          ruff check src/ tests/ --output-format=github
      
      # Type checking
      - name: Run MyPy
        run: |
          pip install mypy
          mypy src/ --strict --show-error-codes
        continue-on-error: true  # Don't block on type errors yet
      
      # Security scanning
      - name: Run Bandit
        run: |
          pip install bandit
          bandit -r src/ -f sarif -o bandit-results.sarif
      
      - name: Upload Bandit results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: bandit-results.sarif
      
      # Dependency scanning
      - name: Run pip-audit
        run: |
          pip install pip-audit
          pip-audit --desc on

  #────────────────────────────────────────────────────────────
  # STAGE 2: Unit Tests
  #────────────────────────────────────────────────────────────
  unit-tests:
    name: Unit Tests
    runs-on: ubuntu-latest
    timeout-minutes: 15
    needs: code-quality
    
    strategy:
      matrix:
        test-group: [agents, tools, memory, evaluation]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
      
      - name: Install dependencies
        run: |
          pip install -e ".[dev,test]"
      
      - name: Run unit tests with coverage
        env:
          TEST_GROUP: ${{ matrix.test-group }}
        run: |
          pytest tests/unit/$TEST_GROUP/ \
            --cov=src/$TEST_GROUP \
            --cov-report=xml \
            --cov-report=term \
            --junit-xml=junit-$TEST_GROUP.xml \
            -v
      
      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: ./coverage.xml
          flags: unit-${{ matrix.test-group }}

  #────────────────────────────────────────────────────────────
  # STAGE 3: Integration Tests
  #────────────────────────────────────────────────────────────
  integration-tests:
    name: Integration Tests
    runs-on: ubuntu-latest
    timeout-minutes: 20
    needs: unit-tests
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
      
      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 3s
          --health-retries 5
        ports:
          - 6379:6379
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
      
      - name: Install dependencies
        run: pip install -e ".[dev,test]"
      
      - name: Run integration tests
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
          REDIS_URL: redis://localhost:6379
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
          TEST_BUDGET_USD: 5.00  # Cost limit for tests
        run: |
          pytest tests/integration/ \
            --cov=src \
            --cov-append \
            --junit-xml=junit-integration.xml \
            -v

  #────────────────────────────────────────────────────────────
  # STAGE 4: AI Quality Evaluation (Golden Dataset)
  #────────────────────────────────────────────────────────────
  ai-evaluation:
    name: AI Quality Evaluation
    runs-on: ubuntu-latest
    timeout-minutes: 30
    needs: integration-tests
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
      
      - name: Install dependencies
        run: pip install -e ".[dev,evaluation]"
      
      # Run evaluation on golden datasets
      - name: Run Golden Dataset Evaluation
        env:
          LANGCHAIN_API_KEY: ${{ secrets.LANGCHAIN_API_KEY }}
          LANGCHAIN_TRACING_V2: 'true'
          LANGCHAIN_PROJECT: ci-evaluation-${{ github.run_id }}
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          python scripts/run_evaluation.py \
            --dataset-dir evaluation/datasets/golden \
            --output-dir evaluation/results/ci-${{ github.run_id }} \
            --enable-tracing
      
      # Generate evaluation report
      - name: Generate Evaluation Report
        if: always()
        run: |
          python scripts/generate_evaluation_report.py \
            --results-dir evaluation/results/ci-${{ github.run_id }} \
            --output-dir evaluation/reports/ci-${{ github.run_id }} \
            --format markdown
      
      # Check quality thresholds
      - name: Check Quality Thresholds
        id: quality-gate
        run: |
          python scripts/check_evaluation_thresholds.py \
            --results-dir evaluation/results/ci-${{ github.run_id }} \
            --min-pass-rate 0.85 \
            --min-relevance 0.75 \
            --min-accuracy 0.75 \
            --min-completeness 0.80 \
            --min-coherence 0.75 \
            --min-safety 1.00 \
            --max-cost-per-request 0.15
      
      # Upload artifacts
      - name: Upload Evaluation Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: evaluation-results-${{ github.sha }}
          path: |
            evaluation/results/
            evaluation/reports/
          retention-days: 30
      
      # Comment on PR with results
      - name: Comment PR with Evaluation Results
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync(
              'evaluation/reports/ci-${{ github.run_id }}/summary.md',
              'utf8'
            );
            
            github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: `## 🤖 AI Evaluation Results\n\n${report}`
            });

  #────────────────────────────────────────────────────────────
  # STAGE 5: Regression Detection
  #────────────────────────────────────────────────────────────
  regression-check:
    name: Regression Detection
    runs-on: ubuntu-latest
    timeout-minutes: 10
    needs: ai-evaluation
    if: github.event_name == 'pull_request'
    
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Need full history
      
      - name: Download current results
        uses: actions/download-artifact@v4
        with:
          name: evaluation-results-${{ github.sha }}
          path: evaluation/results/current
      
      - name: Get baseline results
        run: |
          # Get latest evaluation from main branch
          git checkout main
          cp -r evaluation/results/latest evaluation/results/baseline
          git checkout ${{ github.sha }}
      
      - name: Compare against baseline
        run: |
          python scripts/compare_evaluations.py \
            --baseline evaluation/results/baseline \
            --current evaluation/results/current \
            --output evaluation/regression-report.json \
            --threshold 0.05  # Alert if >5% degradation
      
      - name: Check for regressions
        run: |
          python scripts/check_regressions.py \
            --report evaluation/regression-report.json \
            --fail-on-regression

  #────────────────────────────────────────────────────────────
  # STAGE 6: Performance Benchmarking
  #────────────────────────────────────────────────────────────
  performance-benchmark:
    name: Performance Benchmarking
    runs-on: ubuntu-latest
    timeout-minutes: 15
    needs: integration-tests
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ env.PYTHON_VERSION }}
      
      - name: Install dependencies
        run: pip install -e ".[dev,benchmark]"
      
      - name: Run performance benchmarks
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          python scripts/run_benchmarks.py \
            --output benchmarks/results/ci-${{ github.run_id }}.json \
            --iterations 10
      
      - name: Analyze benchmark results
        run: |
          python scripts/analyze_benchmarks.py \
            --results benchmarks/results/ci-${{ github.run_id }}.json \
            --baseline benchmarks/baseline.json \
            --output benchmarks/analysis.md
      
      - name: Upload benchmark results
        uses: actions/upload-artifact@v4
        with:
          name: benchmark-results-${{ github.sha }}
          path: benchmarks/

  #────────────────────────────────────────────────────────────
  # STAGE 7: Build & Publish
  #────────────────────────────────────────────────────────────
  build-and-publish:
    name: Build & Publish Docker Images
    runs-on: ubuntu-latest
    timeout-minutes: 20
    needs: [ai-evaluation, performance-benchmark]
    if: github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/')
    
    permissions:
      contents: read
      packages: write
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha,prefix={{branch}}-
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./infrastructure/docker/Dockerfile.backend
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64,linux/arm64
      
      - name: Sign image with Cosign
        run: |
          cosign sign --key env://COSIGN_KEY \
            ghcr.io/${{ github.repository }}:${{ steps.meta.outputs.version }}

  #────────────────────────────────────────────────────────────
  # STAGE 8: Deploy to Staging
  #────────────────────────────────────────────────────────────
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    timeout-minutes: 20
    needs: build-and-publish
    environment:
      name: staging
      url: https://staging.marketing-agent.example.com
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure kubectl
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBE_CONFIG_STAGING }}" | base64 -d > $HOME/.kube/config
      
      - name: Run database migrations
        run: |
          kubectl exec -n staging deployment/marketing-agent-backend -- \
            alembic upgrade head
      
      - name: Deploy with kubectl
        run: |
          kubectl set image deployment/marketing-agent-backend \
            backend=ghcr.io/${{ github.repository }}:${{ github.sha }} \
            -n staging
          
          kubectl rollout status deployment/marketing-agent-backend \
            -n staging --timeout=10m
      
      - name: Run smoke tests
        run: |
          python scripts/smoke_tests.py \
            --environment staging \
            --endpoint https://staging.marketing-agent.example.com
      
      - name: Monitor for 10 minutes
        run: |
          python scripts/monitor_deployment.py \
            --environment staging \
            --duration 600 \
            --baseline evaluation/results/baseline

  #────────────────────────────────────────────────────────────
  # STAGE 9: Deploy to Production (Manual Approval)
  #────────────────────────────────────────────────────────────
  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    timeout-minutes: 90
    needs: deploy-staging
    if: startsWith(github.ref, 'refs/tags/v')
    environment:
      name: production
      url: https://marketing-agent.example.com
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure kubectl
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBE_CONFIG_PRODUCTION }}" | base64 -d > $HOME/.kube/config
      
      # Canary deployment
      - name: Deploy canary (10%)
        run: |
          python scripts/canary_deploy.py \
            --environment production \
            --version ${{ github.sha }} \
            --percentage 10
      
      - name: Monitor canary (30 minutes)
        run: |
          python scripts/monitor_canary.py \
            --environment production \
            --duration 1800 \
            --baseline-version $(git describe --tags --abbrev=0 HEAD^) \
            --canary-version ${{ github.sha }}
      
      - name: Increase to 50%
        run: |
          python scripts/canary_deploy.py \
            --environment production \
            --version ${{ github.sha }} \
            --percentage 50
      
      - name: Monitor (30 minutes)
        run: |
          python scripts/monitor_canary.py \
            --environment production \
            --duration 1800
      
      - name: Full rollout (100%)
        run: |
          python scripts/canary_deploy.py \
            --environment production \
            --version ${{ github.sha }} \
            --percentage 100
      
      - name: Final validation
        run: |
          python scripts/validate_deployment.py \
            --environment production \
            --version ${{ github.sha }}
```

---

## Testing Strategy

### Test Pyramid for AI Agents

```
                    ▲
                   / \
                  /   \
                 /     \
                /  E2E  \           <- 5%: End-to-end reasoning tests
               /_________\              (Real LLM, expensive)
              /           \
             /Integration  \       <- 15%: Integration tests
            /    Tests      \          (Real LLM with budget limits)
           /_________________\
          /                   \
         /    Unit Tests       \   <- 80%: Unit tests
        /    (Mocked LLMs)      \      (Mocked LLM calls, fast)
       /_________________________ \
```

### Test Categories

#### 1. Unit Tests (80% of tests)

```python
# tests/unit/agents/test_reasoning_agent.py
import pytest
from unittest.mock import AsyncMock, patch
from src.agents.reasoning_agent import ReasoningAgent

class TestReasoningAgent:
    """Unit tests with mocked LLM calls."""
    
    @pytest.fixture
    def mock_llm(self):
        """Mock LLM for fast, deterministic tests."""
        llm = AsyncMock()
        llm.generate.return_value = {
            "plan": {"steps": ["step1", "step2"]},
            "reasoning": "Mock reasoning output"
        }
        return llm
    
    @pytest.mark.asyncio
    async def test_planning_creates_valid_plan(self, mock_llm):
        """Test plan creation logic."""
        agent = ReasoningAgent(llm=mock_llm)
        
        task = Task(description="Test task", complexity="medium")
        plan = await agent.planner.create_plan(task)
        
        assert plan is not None
        assert len(plan.steps) > 0
        assert plan.estimated_cost > 0
        mock_llm.generate.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_error_handling(self, mock_llm):
        """Test error handling in reasoning loop."""
        mock_llm.generate.side_effect = Exception("API Error")
        agent = ReasoningAgent(llm=mock_llm)
        
        task = Task(description="Test task")
        
        with pytest.raises(ReasoningError):
            await agent.reason(task)
```

#### 2. Integration Tests (15% of tests)

```python
# tests/integration/test_end_to_end_reasoning.py
import pytest
from src.agents.reasoning_agent import ReasoningAgent
from src.config import Config

class TestEndToEndReasoning:
    """Integration tests with real LLM calls (budget-limited)."""
    
    @pytest.fixture
    def budget_limited_config(self):
        """Config with strict budget limits for testing."""
        return Config(
            llm_provider="openai",
            model="gpt-3.5-turbo",  # Cheaper model
            max_tokens_per_test=2000,
            max_cost_per_test=0.05,  # $0.05 per test
            test_mode=True
        )
    
    @pytest.mark.integration
    @pytest.mark.asyncio
    async def test_simple_reasoning_flow(self, budget_limited_config):
        """Test actual reasoning with real LLM."""
        agent = ReasoningAgent(config=budget_limited_config)
        
        task = Task(
            description="Analyze test data and provide summary",
            context={"data": [1, 2, 3, 4, 5]}
        )
        
        with BudgetTracker(max_cost=0.05) as tracker:
            result = await agent.reason(task)
            
            # Budget assertions
            assert tracker.total_cost < 0.05
            assert tracker.total_tokens < 2000
        
        # Quality assertions
        assert result.success
        assert result.output is not None
        assert len(result.reasoning_steps) > 0
```

#### 3. End-to-End Tests (5% of tests)

```python
# tests/e2e/test_production_scenarios.py
import pytest
from src.agents.reasoning_agent import ReasoningAgent

class TestProductionScenarios:
    """E2E tests simulating real production scenarios."""
    
    @pytest.mark.e2e
    @pytest.mark.slow
    @pytest.mark.asyncio
    async def test_complex_campaign_optimization(self):
        """Test full campaign optimization flow."""
        agent = ReasoningAgent()  # Use production config
        
        # Load real test data
        test_data = load_fixture("campaign_optimization/real_scenario_001.json")
        
        result = await agent.reason(
            task=Task(
                description="Optimize underperforming campaign",
                context=test_data
            )
        )
        
        # Comprehensive assertions
        assert result.success
        assert result.has_plan
        assert result.has_execution
        assert result.has_reflection
        assert result.quality_score >= 0.8
        assert result.total_cost < 0.20  # Max $0.20 per complex task
```

---

## Quality Gates

### Multi-Level Quality Gates

```python
# scripts/check_quality_gates.py
class QualityGateChecker:
    """
    Check multiple quality gates before allowing deployment.
    
    Gates:
    1. Code Quality Gate
    2. Test Coverage Gate
    3. AI Evaluation Gate
    4. Performance Gate
    5. Security Gate
    6. Cost Gate
    """
    
    async def check_all_gates(
        self,
        evaluation_results: EvaluationResults,
        test_results: TestResults,
        benchmark_results: BenchmarkResults
    ) -> GateCheckResult:
        """Check all quality gates."""
        
        gates = [
            self.check_code_quality_gate(test_results),
            self.check_ai_quality_gate(evaluation_results),
            self.check_performance_gate(benchmark_results),
            self.check_security_gate(),
            self.check_cost_gate(evaluation_results, benchmark_results)
        ]
        
        results = await asyncio.gather(*gates)
        
        all_passed = all(gate.passed for gate in results)
        
        return GateCheckResult(
            passed=all_passed,
            gate_results=results,
            summary=self._generate_summary(results)
        )
    
    def check_ai_quality_gate(
        self,
        evaluation_results: EvaluationResults
    ) -> GateResult:
        """Check AI quality metrics."""
        
        failures = []
        
        # Check pass rate
        if evaluation_results.pass_rate < 0.85:
            failures.append(
                f"Pass rate {evaluation_results.pass_rate:.2%} < 85%"
            )
        
        # Check individual metrics
        metrics = {
            "relevance": (evaluation_results.avg_relevance, 0.75),
            "accuracy": (evaluation_results.avg_accuracy, 0.75),
            "completeness": (evaluation_results.avg_completeness, 0.80),
            "coherence": (evaluation_results.avg_coherence, 0.75),
            "safety": (evaluation_results.avg_safety, 1.00)
        }
        
        for metric, (actual, threshold) in metrics.items():
            if actual < threshold:
                failures.append(
                    f"{metric} {actual:.3f} < {threshold:.3f}"
                )
        
        return GateResult(
            name="AI Quality Gate",
            passed=len(failures) == 0,
            failures=failures
        )
    
    def check_performance_gate(
        self,
        benchmark_results: BenchmarkResults
    ) -> GateResult:
        """Check performance benchmarks."""
        
        failures = []
        
        # Check latency
        if benchmark_results.p95_latency > 2000:  # 2 seconds
            failures.append(
                f"P95 latency {benchmark_results.p95_latency}ms > 2000ms"
            )
        
        # Check throughput
        if benchmark_results.requests_per_second < 10:
            failures.append(
                f"Throughput {benchmark_results.requests_per_second} rps < 10 rps"
            )
        
        return GateResult(
            name="Performance Gate",
            passed=len(failures) == 0,
            failures=failures
        )
    
    def check_cost_gate(
        self,
        evaluation_results: EvaluationResults,
        benchmark_results: BenchmarkResults
    ) -> GateResult:
        """Check cost metrics."""
        
        failures = []
        
        # Check average cost per request
        avg_cost = evaluation_results.avg_cost_per_request
        if avg_cost > 0.15:  # Max $0.15 per request
            failures.append(
                f"Avg cost ${avg_cost:.3f} > $0.15"
            )
        
        # Check cost increase vs baseline
        if evaluation_results.baseline_cost:
            cost_increase = (
                (avg_cost - evaluation_results.baseline_cost) /
                evaluation_results.baseline_cost
            )
            
            if cost_increase > 0.20:  # Max 20% increase
                failures.append(
                    f"Cost increased {cost_increase:.1%} > 20%"
                )
        
        return GateResult(
            name="Cost Gate",
            passed=len(failures) == 0,
            failures=failures
        )
```

---

## Deployment Strategies

### Canary Deployment with Automated Rollback

```python
# scripts/canary_deploy.py
class CanaryDeploymentManager:
    """
    Manage canary deployments with automated quality checks.
    
    Strategy:
    1. Deploy to 10% of traffic
    2. Monitor for 30 minutes
    3. If healthy, increase to 50%
    4. Monitor for 30 minutes
    5. If healthy, increase to 100%
    
    Auto-rollback triggers:
    - Error rate > baseline + 5%
    - P95 latency > baseline + 30%
    - Evaluation score < baseline - 10%
    """
    
    async def deploy_canary(
        self,
        environment: str,
        new_version: str,
        baseline_version: str
    ) -> DeploymentResult:
        """Execute canary deployment with monitoring."""
        
        stages = [
            (10, 1800),   # 10% for 30 minutes
            (50, 1800),   # 50% for 30 minutes
            (100, 0)      # 100% (full rollout)
        ]
        
        for percentage, monitor_duration in stages:
            logger.info(
                "canary_stage",
                percentage=percentage,
                monitor_duration=monitor_duration
            )
            
            # Update traffic routing
            await self.traffic_router.route(
                canary_version=new_version,
                canary_percentage=percentage,
                baseline_version=baseline_version
            )
            
            if monitor_duration > 0:
                # Monitor quality
                monitoring_result = await self.monitor_quality(
                    duration_seconds=monitor_duration,
                    canary_version=new_version,
                    baseline_version=baseline_version
                )
                
                if not monitoring_result.healthy:
                    # Rollback
                    logger.error(
                        "canary_unhealthy_rollback",
                        percentage=percentage,
                        reason=monitoring_result.failure_reason
                    )
                    
                    await self.rollback(
                        to_version=baseline_version
                    )
                    
                    return DeploymentResult(
                        success=False,
                        rollback_performed=True,
                        failure_stage=percentage,
                        failure_reason=monitoring_result.failure_reason
                    )
        
        # Success
        return DeploymentResult(
            success=True,
            deployed_version=new_version
        )
    
    async def monitor_quality(
        self,
        duration_seconds: int,
        canary_version: str,
        baseline_version: str
    ) -> MonitoringResult:
        """Monitor canary quality and compare with baseline."""
        
        start_time = time.time()
        
        while time.time() - start_time < duration_seconds:
            # Get metrics for both versions
            canary_metrics = await self.metrics_collector.get_metrics(
                version=canary_version,
                window="5m"
            )
            
            baseline_metrics = await self.metrics_collector.get_metrics(
                version=baseline_version,
                window="5m"
            )
            
            # Check health
            health_check = self.check_health(
                canary_metrics,
                baseline_metrics
            )
            
            if not health_check.healthy:
                return MonitoringResult(
                    healthy=False,
                    failure_reason=health_check.failure_reason
                )
            
            # Wait before next check
            await asyncio.sleep(60)  # Check every minute
        
        return MonitoringResult(healthy=True)
    
    def check_health(
        self,
        canary: Metrics,
        baseline: Metrics
    ) -> HealthCheck:
        """Check if canary is healthy compared to baseline."""
        
        # Check error rate
        if canary.error_rate > baseline.error_rate * 1.05:
            return HealthCheck(
                healthy=False,
                failure_reason=f"Error rate increased: {canary.error_rate:.3f} > {baseline.error_rate * 1.05:.3f}"
            )
        
        # Check latency
        if canary.p95_latency > baseline.p95_latency * 1.30:
            return HealthCheck(
                healthy=False,
                failure_reason=f"Latency degraded: {canary.p95_latency}ms > {baseline.p95_latency * 1.30}ms"
            )
        
        # Check evaluation scores
        if canary.avg_evaluation_score < baseline.avg_evaluation_score * 0.90:
            return HealthCheck(
                healthy=False,
                failure_reason=f"Quality degraded: {canary.avg_evaluation_score:.3f} < {baseline.avg_evaluation_score * 0.90:.3f}"
            )
        
        return HealthCheck(healthy=True)
```

---

This comprehensive CI/CD architecture ensures:

✅ **Automated quality gates** prevent bad deployments  
✅ **Golden dataset evaluation** validates AI quality  
✅ **Regression detection** catches quality degradation  
✅ **Performance benchmarking** ensures SLA compliance  
✅ **Canary deployments** enable safe rollouts  
✅ **Automated rollbacks** minimize downtime  
✅ **Cost gates** control LLM spending  

The pipeline is production-ready and follows industry best practices for AI/ML systems.
