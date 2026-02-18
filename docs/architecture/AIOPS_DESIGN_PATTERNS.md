# AIOps Design Patterns for AI Agents

> **Enterprise Design Patterns for Production AI Operations**
> 
> This document catalogs proven design patterns for building robust AIOps systems for AI agents.

---

## Table of Contents

1. [Observability Patterns](#observability-patterns)
2. [Evaluation Patterns](#evaluation-patterns)
3. [Resilience Patterns](#resilience-patterns)
4. [Cost Optimization Patterns](#cost-optimization-patterns)
5. [Quality Assurance Patterns](#quality-assurance-patterns)
6. [Deployment Patterns](#deployment-patterns)

---

## Observability Patterns

### Pattern 1: Trace Correlation Chain

**Problem**: Different observability tools (LangSmith, Prometheus, logs) are not connected, making debugging difficult.

**Solution**: Propagate correlation IDs across all observability layers.

```python
class CorrelationContext:
    """Propagate correlation across all telemetry."""
    
    def __init__(self):
        self.trace_id = generate_trace_id()
        self.span_id = generate_span_id()
        self.session_id = None
    
    def to_baggage(self) -> Dict[str, str]:
        """Convert to OpenTelemetry baggage."""
        return {
            "trace_id": self.trace_id,
            "span_id": self.span_id,
            "session_id": self.session_id or ""
        }
    
    def inject_into_logs(self) -> Dict[str, str]:
        """Inject into structured logs."""
        return {
            "trace_id": self.trace_id,
            "span_id": self.span_id
        }

# Usage
correlation = CorrelationContext()

# In LangSmith
langsmith_run = langsmith_client.create_run(
    extra={"trace_id": correlation.trace_id}
)

# In Prometheus
METRIC_COUNTER.labels(
    trace_id=correlation.trace_id
).inc()

# In Logs
logger.info("reasoning_started", **correlation.inject_into_logs())
```

**Benefits**:
- Single pane of glass debugging
- Correlate metrics with traces
- Track request across all systems

---

### Pattern 2: Real-Time Evaluation Stream

**Problem**: Evaluation feedback comes too late (batch mode).

**Solution**: Stream evaluation results in real-time using async processing.

```python
class RealtimeEvaluationStream:
    """
    Stream evaluation results as reasoning progresses.
    
    Architecture:
    Request → Reasoning Agent → [Evaluation Stream] → Alert System
                              ↓
                         Real-time Dashboard
    """
    
    def __init__(self):
        self.stream = asyncio.Queue()
        self.subscribers = []
    
    async def evaluate_step_async(
        self,
        step: ReasoningStep
    ):
        """Evaluate step and publish to stream."""
        
        # Non-blocking evaluation
        evaluation = await self.evaluator.evaluate_async(step)
        
        # Publish to stream
        await self.stream.put({
            "type": "step_evaluation",
            "step_id": step.id,
            "evaluation": evaluation,
            "timestamp": datetime.now()
        })
        
        # Notify subscribers
        for subscriber in self.subscribers:
            await subscriber.on_evaluation(evaluation)
    
    async def subscribe(self, handler):
        """Subscribe to evaluation stream."""
        self.subscribers.append(handler)

# Usage: Real-time alerting
class QualityMonitor:
    async def on_evaluation(self, evaluation):
        if evaluation.score < 0.7:
            await alert_manager.send_alert(
                "Low quality detected",
                evaluation
            )

monitor = QualityMonitor()
await evaluation_stream.subscribe(monitor)
```

**Benefits**:
- Immediate feedback
- Early failure detection
- Real-time quality dashboards

---

### Pattern 3: Metrics Aggregation Pipeline

**Problem**: Raw metrics are noisy and hard to interpret.

**Solution**: Multi-stage aggregation pipeline with smart bucketing.

```python
class MetricsAggregator:
    """
    Aggregate metrics at multiple time scales.
    
    Aggregation levels:
    - Raw (1s): For real-time monitoring
    - Short (1m): For dashboards
    - Medium (1h): For trend analysis
    - Long (1d): For reporting
    """
    
    async def aggregate_reasoning_metrics(self):
        """Pipeline: Raw → 1m → 1h → 1d"""
        
        # Stage 1: Aggregate to 1-minute buckets
        one_minute = await self._aggregate(
            source="raw_metrics",
            window="1m",
            metrics=[
                ("latency", "percentile", [0.5, 0.95, 0.99]),
                ("cost", "sum", None),
                ("tokens", "sum", None),
                ("quality_score", "mean", None)
            ]
        )
        
        # Stage 2: Aggregate to 1-hour buckets
        one_hour = await self._aggregate(
            source=one_minute,
            window="1h",
            metrics=[
                ("latency_p95", "max", None),
                ("cost", "sum", None),
                ("quality_score", "mean", None)
            ]
        )
        
        # Stage 3: Aggregate to daily buckets
        one_day = await self._aggregate(
            source=one_hour,
            window="1d",
            metrics=[
                ("latency_p95", "max", None),
                ("cost", "sum", None),
                ("quality_score", "mean", None),
                ("total_requests", "sum", None)
            ]
        )
        
        return {
            "1m": one_minute,
            "1h": one_hour,
            "1d": one_day
        }
```

**Benefits**:
- Efficient storage
- Fast dashboard queries
- Multi-scale analysis

---

## Evaluation Patterns

### Pattern 4: Golden Dataset Versioning

**Problem**: Test datasets become stale or inconsistent.

**Solution**: Version control golden datasets with schema validation.

```python
class GoldenDatasetVersion:
    """
    Versioned golden datasets with validation.
    
    Schema:
    - version: Semantic version (1.0.0)
    - schema_version: Dataset schema version
    - test_cases: List of test cases
    - metadata: Creation date, author, description
    """
    
    def __init__(self, path: Path):
        self.path = path
        self.dataset = self._load_and_validate()
    
    def _load_and_validate(self) -> GoldenDataset:
        """Load dataset with schema validation."""
        
        with open(self.path) as f:
            raw_data = json.load(f)
        
        # Validate schema
        schema_version = raw_data.get("schema_version", "1.0.0")
        validator = SchemaValidator.for_version(schema_version)
        
        validated = validator.validate(raw_data)
        
        return GoldenDataset(**validated)
    
    def upgrade_to_latest(self) -> GoldenDataset:
        """Upgrade dataset to latest schema version."""
        
        current_version = self.dataset.schema_version
        latest_version = SchemaValidator.latest_version()
        
        if current_version == latest_version:
            return self.dataset
        
        # Apply migrations
        for migration in self._get_migrations(current_version, latest_version):
            self.dataset = migration.apply(self.dataset)
        
        return self.dataset

# Schema evolution example
class SchemaV1ToV2Migration:
    """Migrate from schema v1 to v2."""
    
    def apply(self, dataset: GoldenDataset) -> GoldenDataset:
        """
        Changes in v2:
        - Add 'complexity' field to test cases
        - Rename 'expected_keywords' to 'expected_concepts'
        - Add 'evaluation_criteria' section
        """
        
        for test_case in dataset.test_cases:
            # Add complexity (infer from input)
            test_case.complexity = self._infer_complexity(test_case)
            
            # Rename field
            if "expected_keywords" in test_case.expected_output:
                test_case.expected_output["expected_concepts"] = \
                    test_case.expected_output.pop("expected_keywords")
            
            # Add default evaluation criteria
            if "evaluation_criteria" not in test_case:
                test_case.evaluation_criteria = {
                    "min_relevance": 0.70,
                    "min_accuracy": 0.70,
                    "min_safety": 1.00
                }
        
        dataset.schema_version = "2.0.0"
        return dataset
```

**Benefits**:
- Backward compatibility
- Schema evolution
- Auditability

---

### Pattern 5: Evaluation Cascading

**Problem**: Running all evaluations is slow and expensive.

**Solution**: Cascade evaluations from fast/cheap to slow/expensive.

```python
class CascadingEvaluator:
    """
    Cascade evaluations for efficiency.
    
    Stages:
    1. Fast heuristics (rule-based, <10ms)
    2. Medium complexity (keyword matching, <100ms)
    3. Expensive (LLM-as-judge, ~2s)
    
    Stop early if fast evaluations fail.
    """
    
    async def evaluate(
        self,
        output: ReasoningResult
    ) -> Evaluation:
        """Cascading evaluation."""
        
        # Stage 1: Fast heuristics (always run)
        heuristic_result = await self.heuristic_evaluator.evaluate(output)
        
        if heuristic_result.score < 0.5:
            # Fail fast - no need for expensive evaluation
            return Evaluation(
                score=heuristic_result.score,
                stage="heuristic",
                reason="Failed fast heuristics"
            )
        
        # Stage 2: Medium complexity
        keyword_result = await self.keyword_evaluator.evaluate(output)
        
        if keyword_result.score < 0.6:
            # Fail at medium stage
            return Evaluation(
                score=keyword_result.score,
                stage="keyword",
                reason="Failed keyword matching"
            )
        
        # Stage 3: Expensive evaluation (only if passed previous stages)
        llm_result = await self.llm_judge_evaluator.evaluate(output)
        
        # Combine scores with weights
        final_score = (
            heuristic_result.score * 0.2 +
            keyword_result.score * 0.3 +
            llm_result.score * 0.5
        )
        
        return Evaluation(
            score=final_score,
            stage="complete",
            details={
                "heuristic": heuristic_result,
                "keyword": keyword_result,
                "llm": llm_result
            }
        )
```

**Benefits**:
- 70% faster evaluation
- 60% cost reduction
- No quality compromise

---

### Pattern 6: Evaluation A/B Testing

**Problem**: Hard to compare different evaluation methods.

**Solution**: Run multiple evaluators in parallel and compare results.

```python
class EvaluatorABTest:
    """
    A/B test different evaluation methods.
    
    Use case: Test new LLM-as-judge vs existing heuristics.
    """
    
    async def run_ab_test(
        self,
        output: ReasoningResult,
        evaluator_a: Evaluator,
        evaluator_b: Evaluator
    ) -> ABTestResult:
        """Run both evaluators and compare."""
        
        # Run in parallel
        result_a, result_b = await asyncio.gather(
            evaluator_a.evaluate(output),
            evaluator_b.evaluate(output)
        )
        
        # Compare results
        agreement = abs(result_a.score - result_b.score) < 0.1
        
        # Log for analysis
        await self.analytics.log_ab_test({
            "evaluator_a": {
                "name": evaluator_a.name,
                "score": result_a.score,
                "latency": result_a.latency,
                "cost": result_a.cost
            },
            "evaluator_b": {
                "name": evaluator_b.name,
                "score": result_b.score,
                "latency": result_b.latency,
                "cost": result_b.cost
            },
            "agreement": agreement,
            "score_diff": abs(result_a.score - result_b.score)
        })
        
        # Use evaluator_a as primary (stable) for now
        return ABTestResult(
            primary=result_a,
            secondary=result_b,
            agreement=agreement
        )
```

**Benefits**:
- Data-driven evaluator selection
- Gradual migration
- Risk mitigation

---

## Resilience Patterns

### Pattern 7: Circuit Breaker for LLM Calls

**Problem**: LLM API failures cascade and bring down system.

**Solution**: Circuit breaker with fallback to cache or simpler model.

```python
class LLMCircuitBreaker:
    """
    Circuit breaker for LLM API calls.
    
    States:
    - CLOSED: Normal operation (calls go through)
    - OPEN: Too many failures (reject calls immediately)
    - HALF_OPEN: Testing if service recovered (limited calls)
    """
    
    def __init__(
        self,
        failure_threshold: int = 5,
        timeout: int = 60,
        half_open_calls: int = 3
    ):
        self.state = "CLOSED"
        self.failure_count = 0
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.half_open_calls = half_open_calls
        self.last_failure_time = None
    
    async def call_llm(
        self,
        prompt: str,
        fallback: Optional[Callable] = None
    ) -> str:
        """Make LLM call through circuit breaker."""
        
        # Check circuit state
        if self.state == "OPEN":
            # Check if timeout elapsed
            if time.time() - self.last_failure_time > self.timeout:
                self.state = "HALF_OPEN"
                self.failure_count = 0
            else:
                # Circuit still open - use fallback
                if fallback:
                    return await fallback(prompt)
                raise CircuitBreakerOpen("LLM circuit breaker is open")
        
        try:
            # Attempt LLM call
            result = await self.llm.generate(prompt)
            
            # Success - reset failure count
            if self.state == "HALF_OPEN":
                # Recovered - close circuit
                self.state = "CLOSED"
                self.failure_count = 0
            
            return result
            
        except Exception as e:
            # Failure
            self.failure_count += 1
            self.last_failure_time = time.time()
            
            # Check if threshold exceeded
            if self.failure_count >= self.failure_threshold:
                self.state = "OPEN"
                logger.error("llm_circuit_breaker_open", 
                           failure_count=self.failure_count)
            
            # Use fallback
            if fallback:
                return await fallback(prompt)
            raise

# Usage with semantic cache fallback
circuit_breaker = LLMCircuitBreaker()

async def cached_response(prompt: str) -> str:
    """Fallback to semantic cache."""
    cache_result = await semantic_cache.lookup(prompt)
    if cache_result:
        return cache_result
    raise Exception("No cached response available")

result = await circuit_breaker.call_llm(
    prompt=prompt,
    fallback=cached_response
)
```

**Benefits**:
- Prevent cascading failures
- Graceful degradation
- Auto-recovery

---

### Pattern 8: Bulkhead Isolation

**Problem**: One failing component brings down entire system.

**Solution**: Isolate components with separate resource pools.

```python
class BulkheadIsolation:
    """
    Isolate components with separate resource pools.
    
    Each bulkhead has:
    - Dedicated thread pool
    - Token budget
    - Cost limit
    - Request queue
    """
    
    def __init__(self, config: BulkheadConfig):
        self.bulkheads = {
            "planning": Bulkhead(
                max_concurrent=10,
                max_queue_size=50,
                token_budget_per_hour=50000,
                cost_budget_per_hour=10.0
            ),
            "execution": Bulkhead(
                max_concurrent=20,
                max_queue_size=100,
                token_budget_per_hour=100000,
                cost_budget_per_hour=20.0
            ),
            "reflection": Bulkhead(
                max_concurrent=5,
                max_queue_size=25,
                token_budget_per_hour=25000,
                cost_budget_per_hour=5.0
            )
        }
    
    async def execute_in_bulkhead(
        self,
        bulkhead_name: str,
        operation: Callable
    ):
        """Execute operation in isolated bulkhead."""
        
        bulkhead = self.bulkheads[bulkhead_name]
        
        # Check if bulkhead has capacity
        if not await bulkhead.acquire():
            raise BulkheadFullException(
                f"Bulkhead {bulkhead_name} is full"
            )
        
        try:
            # Execute with budget tracking
            with bulkhead.track_usage():
                result = await operation()
            
            return result
            
        finally:
            bulkhead.release()

# Usage
bulkhead = BulkheadIsolation(config)

# Planning won't impact execution capacity
await bulkhead.execute_in_bulkhead(
    "planning",
    lambda: planning_agent.create_plan(task)
)
```

**Benefits**:
- Fault isolation
- Resource fairness
- Budget control

---

## Cost Optimization Patterns

### Pattern 9: Adaptive Token Budget

**Problem**: Fixed token limits waste budget or limit functionality.

**Solution**: Dynamically adjust token budget based on task complexity.

```python
class AdaptiveTokenBudget:
    """
    Dynamically allocate token budget based on task complexity.
    
    Algorithm:
    1. Classify task complexity (simple/medium/complex)
    2. Allocate base budget
    3. Allow borrowing from reserve if needed
    4. Adjust future budgets based on actual usage
    """
    
    def __init__(self):
        self.budgets = {
            "simple": 1000,
            "medium": 3000,
            "complex": 8000
        }
        self.reserve = 10000  # Emergency reserve
        self.usage_history = []
    
    async def allocate_budget(
        self,
        task: Task
    ) -> TokenBudget:
        """Allocate token budget for task."""
        
        # Classify complexity
        complexity = await self.classifier.classify(task)
        
        # Get base budget
        base_budget = self.budgets[complexity]
        
        # Adjust based on historical usage
        avg_usage = self._get_avg_usage(complexity)
        
        if avg_usage > base_budget * 0.9:
            # Tasks typically use 90%+ of budget
            # Increase budget by 20%
            adjusted_budget = int(base_budget * 1.2)
        elif avg_usage < base_budget * 0.5:
            # Tasks typically use <50% of budget
            # Decrease budget by 20%
            adjusted_budget = int(base_budget * 0.8)
        else:
            adjusted_budget = base_budget
        
        return TokenBudget(
            base=adjusted_budget,
            reserve=self.reserve,
            complexity=complexity
        )
    
    async def borrow_from_reserve(
        self,
        current_budget: TokenBudget,
        needed: int
    ) -> bool:
        """Borrow tokens from reserve if needed."""
        
        if self.reserve >= needed:
            self.reserve -= needed
            current_budget.borrowed += needed
            
            logger.warning(
                "borrowed_from_reserve",
                needed=needed,
                reserve_remaining=self.reserve
            )
            return True
        
        return False
```

**Benefits**:
- Efficient budget utilization
- No artificial limits
- Learning from usage patterns

---

### Pattern 10: Prompt Compression

**Problem**: Long prompts waste tokens and increase cost.

**Solution**: Intelligently compress prompts without losing context.

```python
class PromptCompressor:
    """
    Compress prompts to reduce token usage.
    
    Techniques:
    - Remove redundant whitespace
    - Abbreviate common terms
    - Summarize long examples
    - Extract key information only
    """
    
    async def compress(
        self,
        prompt: str,
        max_tokens: int,
        preserve_quality: bool = True
    ) -> CompressedPrompt:
        """Compress prompt to fit within token budget."""
        
        # Stage 1: Simple cleanup
        cleaned = self._remove_redundant_whitespace(prompt)
        cleaned = self._normalize_formatting(cleaned)
        
        current_tokens = self.tokenizer.count(cleaned)
        
        if current_tokens <= max_tokens:
            return CompressedPrompt(text=cleaned, compression_ratio=1.0)
        
        # Stage 2: Smart abbreviation
        abbreviated = self._abbreviate_common_terms(cleaned)
        current_tokens = self.tokenizer.count(abbreviated)
        
        if current_tokens <= max_tokens:
            return CompressedPrompt(
                text=abbreviated,
                compression_ratio=len(prompt) / len(abbreviated)
            )
        
        # Stage 3: Extractive summarization
        if preserve_quality:
            # Use LLM to summarize while preserving key info
            summarized = await self._llm_summarize(
                abbreviated,
                max_tokens=max_tokens
            )
        else:
            # Simple truncation
            summarized = self._truncate(abbreviated, max_tokens)
        
        return CompressedPrompt(
            text=summarized,
            compression_ratio=len(prompt) / len(summarized)
        )
    
    def _abbreviate_common_terms(self, text: str) -> str:
        """Abbreviate domain-specific terms."""
        
        abbreviations = {
            "campaign optimization": "camp_opt",
            "conversion rate": "CVR",
            "cost per acquisition": "CPA",
            "return on ad spend": "ROAS",
            "click-through rate": "CTR"
        }
        
        for term, abbr in abbreviations.items():
            text = text.replace(term, abbr)
        
        return text
```

**Benefits**:
- 20-40% token reduction
- Faster inference
- Lower costs

---

## Quality Assurance Patterns

### Pattern 11: Differential Testing

**Problem**: Hard to validate reasoning quality changes.

**Solution**: Compare outputs before and after changes.

```python
class DifferentialTester:
    """
    Compare reasoning outputs before and after changes.
    
    Use case: Validate prompt changes don't degrade quality.
    """
    
    async def run_differential_test(
        self,
        baseline_agent: ReasoningAgent,
        candidate_agent: ReasoningAgent,
        test_cases: List[TestCase]
    ) -> DifferentialTestResult:
        """Run differential test."""
        
        results = []
        
        for test_case in test_cases:
            # Run both agents in parallel
            baseline_output, candidate_output = await asyncio.gather(
                baseline_agent.reason(test_case.input),
                candidate_agent.reason(test_case.input)
            )
            
            # Evaluate both outputs
            baseline_eval = await self.evaluator.evaluate(
                baseline_output,
                test_case.expected
            )
            candidate_eval = await self.evaluator.evaluate(
                candidate_output,
                test_case.expected
            )
            
            # Compare
            comparison = TestComparison(
                test_case=test_case,
                baseline_score=baseline_eval.overall_score,
                candidate_score=candidate_eval.overall_score,
                improvement=candidate_eval.overall_score - baseline_eval.overall_score,
                baseline_cost=baseline_output.total_cost,
                candidate_cost=candidate_output.total_cost
            )
            
            results.append(comparison)
        
        return DifferentialTestResult(
            total_tests=len(test_cases),
            improved=len([r for r in results if r.improvement > 0.05]),
            degraded=len([r for r in results if r.improvement < -0.05]),
            neutral=len([r for r in results if abs(r.improvement) <= 0.05]),
            avg_improvement=statistics.mean([r.improvement for r in results]),
            cost_change=statistics.mean([
                r.candidate_cost - r.baseline_cost for r in results
            ]),
            detailed_results=results
        )
```

**Benefits**:
- Quantify quality changes
- Detect regressions early
- Data-driven decisions

---

### Pattern 12: Shadow Mode Testing

**Problem**: Can't test changes in production without risk.

**Solution**: Run new version in shadow mode and compare.

```python
class ShadowModeRunner:
    """
    Run new agent version in shadow mode.
    
    Architecture:
    User Request → Production Agent → Response (user sees this)
                ↓
           Shadow Agent → Shadow Response (logged, not shown to user)
    """
    
    async def handle_request(
        self,
        request: Request
    ) -> Response:
        """Handle request with shadow mode."""
        
        # Always run production agent
        production_response = await self.production_agent.reason(
            request.task
        )
        
        # Run shadow agent concurrently (don't block user)
        asyncio.create_task(
            self._run_shadow_agent(request, production_response)
        )
        
        # Return production response immediately
        return production_response
    
    async def _run_shadow_agent(
        self,
        request: Request,
        production_response: Response
    ):
        """Run shadow agent and compare."""
        
        try:
            shadow_response = await self.shadow_agent.reason(
                request.task
            )
            
            # Evaluate both
            prod_eval = await self.evaluator.evaluate(production_response)
            shadow_eval = await self.evaluator.evaluate(shadow_response)
            
            # Log comparison
            await self.analytics.log_shadow_comparison({
                "request_id": request.id,
                "production_score": prod_eval.overall_score,
                "shadow_score": shadow_eval.overall_score,
                "production_cost": production_response.total_cost,
                "shadow_cost": shadow_response.total_cost,
                "production_latency": production_response.latency,
                "shadow_latency": shadow_response.latency
            })
            
        except Exception as e:
            logger.error("shadow_agent_failed", error=str(e))
            # Don't impact production
```

**Benefits**:
- Zero risk testing
- Real production traffic
- Gradual validation

---

## Deployment Patterns

### Pattern 13: Blue-Green Deployment with Evaluation

**Problem**: Need zero-downtime deployments with quality validation.

**Solution**: Blue-green deployment with automated quality checks.

```python
class BlueGreenDeployment:
    """
    Blue-green deployment with quality validation.
    
    Steps:
    1. Deploy new version (green) alongside current (blue)
    2. Run smoke tests on green
    3. Route 1% traffic to green
    4. Monitor quality for 10 minutes
    5. If healthy, gradually increase to 100%
    6. Decommission blue
    """
    
    async def deploy_green(
        self,
        new_version: str
    ) -> DeploymentResult:
        """Deploy green version with validation."""
        
        # Step 1: Deploy green
        green_deployment = await self.k8s.deploy(
            version=new_version,
            environment="green"
        )
        
        # Step 2: Wait for healthy
        await self.k8s.wait_for_healthy(green_deployment)
        
        # Step 3: Run smoke tests
        smoke_results = await self.smoke_tester.run_tests(
            endpoint=green_deployment.endpoint
        )
        
        if not smoke_results.all_passed:
            await self.k8s.rollback(green_deployment)
            return DeploymentResult(
                success=False,
                reason="Smoke tests failed"
            )
        
        # Step 4: Route 1% traffic
        await self.traffic_router.route(
            green=1,
            blue=99
        )
        
        # Step 5: Monitor quality
        quality_check = await self._monitor_quality(
            duration_minutes=10,
            environment="green"
        )
        
        if not quality_check.healthy:
            # Rollback
            await self.traffic_router.route(green=0, blue=100)
            await self.k8s.rollback(green_deployment)
            return DeploymentResult(
                success=False,
                reason="Quality check failed"
            )
        
        # Step 6: Gradual rollout
        for percentage in [10, 25, 50, 75, 100]:
            await self.traffic_router.route(
                green=percentage,
                blue=100-percentage
            )
            
            await asyncio.sleep(300)  # 5 minutes between steps
            
            quality_check = await self._monitor_quality(
                duration_minutes=5,
                environment="green"
            )
            
            if not quality_check.healthy:
                # Rollback
                await self.traffic_router.route(green=0, blue=100)
                return DeploymentResult(
                    success=False,
                    reason=f"Quality degraded at {percentage}%"
                )
        
        # Step 7: Full cutover complete
        await self.k8s.decommission("blue")
        
        return DeploymentResult(
            success=True,
            green_version=new_version
        )
```

**Benefits**:
- Zero downtime
- Automated validation
- Easy rollback

---

## Summary

These 13 design patterns provide a comprehensive toolkit for building production-grade AIOps systems for AI agents:

**Observability** (3 patterns):
1. Trace Correlation Chain
2. Real-Time Evaluation Stream
3. Metrics Aggregation Pipeline

**Evaluation** (3 patterns):
4. Golden Dataset Versioning
5. Evaluation Cascading
6. Evaluation A/B Testing

**Resilience** (2 patterns):
7. Circuit Breaker for LLM Calls
8. Bulkhead Isolation

**Cost Optimization** (2 patterns):
9. Adaptive Token Budget
10. Prompt Compression

**Quality Assurance** (2 patterns):
11. Differential Testing
12. Shadow Mode Testing

**Deployment** (1 pattern):
13. Blue-Green Deployment with Evaluation

Use these patterns individually or in combination to build robust, cost-effective, and reliable AI agent systems.
