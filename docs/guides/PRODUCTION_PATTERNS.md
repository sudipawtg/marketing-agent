# Production Patterns for AI Engineering

## Overview

This document outlines production-grade patterns for deploying and operating GenAI systems, specifically focused on agentic architectures with LangChain/LangGraph.

---

## Table of Contents

1. [Prompt Engineering as Code](#prompt-engineering-as-code)
2. [Context Management](#context-management)
3. [Error Handling & Retries](#error-handling--retries)
4. [Cost & Latency Optimization](#cost--latency-optimization)
5. [Evaluation & Testing](#evaluation--testing)
6. [Observability Patterns](#observability-patterns)
7. [Security & Compliance](#security--compliance)
8. [Deployment Strategies](#deployment-strategies)

---

## Prompt Engineering as Code

### ❌ Don't: Inline prompts in business logic

```python
async def analyze_campaign(campaign_data: dict) -> str:
    # Hard to version, test, or change
    prompt = f"Analyze this campaign: {json.dumps(campaign_data)}"
    return await llm.ainvoke(prompt)
```

### ✅ Do: Separate prompts from logic

```python
# prompts/campaign_analysis.py
from langchain.prompts import ChatPromptTemplate

CAMPAIGN_ANALYSIS_PROMPT = ChatPromptTemplate.from_messages([
    ("system", """You are an expert marketing analyst.
    Analyze the campaign data and provide actionable insights.
    
    Output Format (JSON):
    {
        "performance_score": <0-100>,
        "key_insights": [<list of insights>],
        "recommendations": [<list of recommendations>]
    }
    """),
    ("human", "Campaign Data:\n{campaign_data}")
])

# src/agent/workflow.py
from prompts.campaign_analysis import CAMPAIGN_ANALYSIS_PROMPT

async def analyze_campaign(campaign_data: dict) -> CampaignAnalysis:
    """Analyze campaign with versioned prompt."""
    messages = CAMPAIGN_ANALYSIS_PROMPT.format_messages(
        campaign_data=json.dumps(campaign_data, indent=2)
    )
    
    response = await llm.ainvoke(messages)
    
    # Parse and validate with Pydantic
    return CampaignAnalysis.parse_raw(response.content)
```

### Benefits:
- ✅ Version control for prompts
- ✅ A/B testing different versions
- ✅ Reusable across features
- ✅ Testable in isolation
- ✅ Clear separation of concerns

---

## Context Management

### Pattern: Dynamic Context Window Optimization

```python
from typing import List
from src.data_collectors.base import DataCollector

class SmartContextBuilder:
    """Intelligently manage context within token limits."""
    
    def __init__(self, max_tokens: int = 8000):
        self.max_tokens = max_tokens
        self.tokenizer = tiktoken.get_encoding("cl100k_base")
    
    def build_context(
        self,
        required: List[str],  # Must include
        optional: List[str],  # Include if space
        priority: List[str],  # Include first from optional
    ) -> str:
        """Build optimized context within token budget."""
        
        # Always include required content
        context_parts = required.copy()
        tokens_used = sum(len(self.tokenizer.encode(p)) for p in context_parts)
        
        # Add priority items if they fit
        for item in priority:
            item_tokens = len(self.tokenizer.encode(item))
            if tokens_used + item_tokens < self.max_tokens:
                context_parts.append(item)
                tokens_used += item_tokens
        
        # Add optional items if space remains
        for item in optional:
            item_tokens = len(self.tokenizer.encode(item))
            if tokens_used + item_tokens < self.max_tokens:
                context_parts.append(item)
                tokens_used += item_tokens
        
        return "\n\n".join(context_parts)

# Usage
async def optimize_campaign(campaign_id: str) -> dict:
    """Optimize campaign with smart context management."""
    
    builder = SmartContextBuilder(max_tokens=6000)
    
    # Required: Current campaign data
    campaign_data = await get_campaign_data(campaign_id)
    
    # Priority: Recent performance metrics
    performance = await get_performance_metrics(campaign_id, days=7)
    
    # Optional: Historical comparisons, competitor data
    historical = await get_historical_data(campaign_id)
    competitor = await get_competitor_data()
    
    context = builder.build_context(
        required=[format_campaign(campaign_data)],
        optional=[format_historical(historical), format_competitor(competitor)],
        priority=[format_performance(performance)]
    )
    
    return await llm.ainvoke(context)
```

---

## Error Handling & Retries

### Pattern: Structured Error Recovery

```python
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type
)
from datadog import statsd

class LLMError(Exception):
    """Base exception for LLM errors."""
    pass

class RateLimitError(LLMError):
    """Rate limit exceeded."""
    pass

class ModelError(LLMError):
    """Model returned error."""
    pass

@retry(
    retry=retry_if_exception_type((RateLimitError, ModelError)),
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=10),
    before_sleep=lambda retry_state: statsd.increment(
        "marketing_agent.llm.retry",
        tags=[f"attempt:{retry_state.attempt_number}"]
    )
)
async def call_llm_with_retry(
    messages: List[dict],
    model: str = "gpt-4"
) -> str:
    """Call LLM with automatic retry on failures."""
    
    try:
        response = await llm.ainvoke(messages, model=model)
        
        # Track success
        statsd.increment("marketing_agent.llm.success")
        
        return response.content
        
    except openai.RateLimitError as e:
        statsd.increment("marketing_agent.llm.rate_limit")
        raise RateLimitError("Rate limit exceeded") from e
    
    except openai.APIError as e:
        statsd.increment("marketing_agent.llm.api_error")
        
        # Check if error is retryable
        if e.status_code >= 500:
            raise ModelError(f"Model error: {e}") from e
        else:
            raise LLMError(f"API error: {e}") from e

# Fallback pattern
async def analyze_with_fallback(data: dict) -> dict:
    """Try primary model, fallback to secondary if needed."""
    
    try:
        # Try GPT-4 first
        return await call_llm_with_retry(data, model="gpt-4")
    
    except LLMError as e:
        logger.warning(f"GPT-4 failed: {e}, falling back to GPT-3.5")
        statsd.increment("marketing_agent.llm.fallback")
        
        # Fallback to faster, cheaper model
        return await call_llm_with_retry(data, model="gpt-3.5-turbo")
```

---

## Cost & Latency Optimization

### Pattern: Multi-Tier Model Strategy

```python
from enum import Enum
from typing import Optional

class ComplexityTier(Enum):
    """Task complexity levels."""
    SIMPLE = "simple"      # GPT-3.5 Turbo
    MEDIUM = "medium"      # GPT-4
    COMPLEX = "complex"    # GPT-4 Turbo

class ModelSelector:
    """Select appropriate model based on task complexity."""
    
    MODEL_MAP = {
        ComplexityTier.SIMPLE: {
            "model": "gpt-3.5-turbo",
            "cost_per_1k": 0.0015,
            "max_tokens": 4096
        },
        ComplexityTier.MEDIUM: {
            "model": "gpt-4",
            "cost_per_1k": 0.03,
            "max_tokens": 8192
        },
        ComplexityTier.COMPLEX: {
            "model": "gpt-4-turbo-preview",
            "cost_per_1k": 0.01,
            "max_tokens": 128000
        }
    }
    
    @classmethod
    def select_model(cls, task: str, context_size: int) -> dict:
        """Select optimal model for task."""
        
        # Simple heuristics (can be ML model)
        if context_size < 2000 and "simple" in task.lower():
            tier = ComplexityTier.SIMPLE
        elif context_size < 6000:
            tier = ComplexityTier.MEDIUM
        else:
            tier = ComplexityTier.COMPLEX
        
        return cls.MODEL_MAP[tier]

# Usage
async def process_task(task: str, context: str) -> dict:
    """Process task with optimal model."""
    
    # Calculate context size
    context_tokens = len(tokenizer.encode(context))
    
    # Select model
    model_config = ModelSelector.select_model(task, context_tokens)
    
    logger.info(
        f"Selected model: {model_config['model']} for task complexity",
        extra={"model": model_config["model"], "tokens": context_tokens}
    )
    
    # Track model usage
    statsd.increment(
        "marketing_agent.model.selection",
        tags=[f"model:{model_config['model']}", f"task:{task}"]
    )
    
    response = await llm.ainvoke(
        context,
        model=model_config["model"],
        max_tokens=model_config["max_tokens"]
    )
    
    # Track cost
    estimated_cost = (response.usage.total_tokens / 1000) * model_config["cost_per_1k"]
    statsd.histogram("marketing_agent.llm.cost", estimated_cost)
    
    return response
```

### Pattern: Caching Strategy

```python
from functools import wraps
import hashlib
import redis

redis_client = redis.Redis()

def cache_llm_response(ttl: int = 3600):
    """Cache LLM responses to avoid redundant calls."""
    
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Create cache key from function args
            cache_key = f"llm:{func.__name__}:{hashlib.md5(str(args).encode()).hexdigest()}"
            
            # Check cache
            cached = redis_client.get(cache_key)
            if cached:
                statsd.increment("marketing_agent.llm.cache_hit")
                return json.loads(cached)
            
            # Call LLM
            result = await func(*args, **kwargs)
            
            # Store in cache
            redis_client.setex(cache_key, ttl, json.dumps(result))
            statsd.increment("marketing_agent.llm.cache_miss")
            
            return result
        return wrapper
    return decorator

@cache_llm_response(ttl=3600)  # Cache for 1 hour
async def analyze_competitor(competitor_id: str) -> dict:
    """Analyze competitor (cached)."""
    data = await fetch_competitor_data(competitor_id)
    return await llm.ainvoke(f"Analyze: {data}")
```

---

## Evaluation & Testing

### Pattern: Golden Dataset Testing

```python
from dataclasses import dataclass
from typing import List, Dict
import pytest

@dataclass
class GoldenTestCase:
    """Single test case from golden dataset."""
    input: dict
    expected_output: dict
    evaluation_criteria: List[str]
    min_score: float = 0.8

class EvaluationRunner:
    """Run evaluations against golden datasets."""
    
    def __init__(self, dataset_path: str):
        with open(dataset_path) as f:
            self.test_cases = [
                GoldenTestCase(**case) 
                for case in json.load(f)
            ]
    
    async def run_evaluation(self) -> Dict[str, float]:
        """Run all test cases and return metrics."""
        results = []
        
        for test_case in self.test_cases:
            # Run the agent
            output = await run_agent(test_case.input)
            
            # Evaluate
            scores = await self.evaluate_output(
                output,
                test_case.expected_output,
                test_case.evaluation_criteria
            )
            
            results.append({
                "test_case": test_case,
                "output": output,
                "scores": scores,
                "passed": all(s >= test_case.min_score for s in scores.values())
            })
        
        # Aggregate metrics
        return self.aggregate_results(results)

# Pytest integration
@pytest.mark.asyncio
@pytest.mark.parametrize("test_case", get_golden_test_cases())
async def test_agent_golden_dataset(test_case: GoldenTestCase):
    """Test agent against golden dataset."""
    
    output = await run_agent(test_case.input)
    
    scores = await evaluate_output(
        output,
        test_case.expected_output,
        test_case.evaluation_criteria
    )
    
    for metric, score in scores.items():
        assert score >= test_case.min_score, \
            f"{metric} score {score} below threshold {test_case.min_score}"
```

---

## Observability Patterns

### Pattern: Comprehensive LLM Tracing

```python
from contextlib import asynccontextmanager
from datetime import datetime
import uuid

@asynccontextmanager
async def trace_llm_call(operation: str, metadata: dict = None):
    """Trace LLM call with comprehensive metrics."""
    
    trace_id = str(uuid.uuid4())
    start_time = datetime.utcnow()
    
    # Start trace
    logger.info(
        f"Starting LLM operation: {operation}",
        extra={
            "trace_id": trace_id,
            "operation": operation,
            **(metadata or {})
        }
    )
    
    try:
        yield trace_id
        
        # Success metrics
        duration = (datetime.utcnow() - start_time).total_seconds()
        
        statsd.histogram(
            f"marketing_agent.llm.{operation}.duration",
            duration,
            tags=[f"operation:{operation}"]
        )
        
        statsd.increment(
            f"marketing_agent.llm.{operation}.success",
            tags=[f"operation:{operation}"]
        )
        
        logger.info(
            f"Completed LLM operation: {operation}",
            extra={
                "trace_id": trace_id,
                "duration_seconds": duration,
                "status": "success"
            }
        )
        
    except Exception as e:
        # Error metrics
        duration = (datetime.utcnow() - start_time).total_seconds()
        
        statsd.increment(
            f"marketing_agent.llm.{operation}.error",
            tags=[
                f"operation:{operation}",
                f"error_type:{type(e).__name__}"
            ]
        )
        
        logger.error(
            f"Failed LLM operation: {operation}",
            extra={
                "trace_id": trace_id,
                "duration_seconds": duration,
                "error": str(e),
                "error_type": type(e).__name__
            },
            exc_info=True
        )
        
        raise

# Usage
async def analyze_campaign(campaign_data: dict) -> dict:
    """Analyze campaign with full tracing."""
    
    async with trace_llm_call("campaign_analysis", {"campaign_id": campaign_data["id"]}) as trace_id:
        response = await llm.ainvoke(campaign_data)
        
        # Track specific metrics within trace
        statsd.histogram(
            "marketing_agent.llm.tokens",
            response.usage.total_tokens,
            tags=[f"trace_id:{trace_id}"]
        )
        
        return response
```

---

## Security & Compliance

### Pattern: PII Detection and Redaction

```python
import re
from typing import Dict, List

class PIIRedactor:
    """Detect and redact PII before sending to LLM."""
    
    PATTERNS = {
        "email": r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
        "phone": r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b',
        "ssn": r'\b\d{3}-\d{2}-\d{4}\b',
        "credit_card": r'\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b',
    }
    
    def redact(self, text: str) -> tuple[str, Dict[str, List[str]]]:
        """Redact PII and return redacted text + found PII."""
        
        redacted_text = text
        found_pii = {}
        
        for pii_type, pattern in self.PATTERNS.items():
            matches = re.findall(pattern, text)
            if matches:
                found_pii[pii_type] = matches
                
                # Replace with placeholder
                redacted_text = re.sub(
                    pattern,
                    f"[REDACTED_{pii_type.upper()}]",
                    redacted_text
                )
                
                # Log PII detection
                statsd.increment(
                    "marketing_agent.security.pii_detected",
                    tags=[f"type:{pii_type}"]
                )
        
        return redacted_text, found_pii

# Usage
async def process_user_input(user_input: str) -> dict:
    """Process user input with PII protection."""
    
    redactor = PIIRedactor()
    
    # Redact PII
    redacted_input, found_pii = redactor.redact(user_input)
    
    if found_pii:
        logger.warning(
            "PII detected in user input",
            extra={"pii_types": list(found_pii.keys())}
        )
    
    # Send redacted version to LLM
    response = await llm.ainvoke(redacted_input)
    
    return response
```

---

## Deployment Strategies

### Pattern: Canary Deployment with Evaluation

```python
from enum import Enum

class DeploymentVariant(Enum):
    CURRENT = "current"
    CANARY = "canary"

class ABTestRouter:
    """Route requests to different model versions."""
    
    def __init__(self, canary_percentage: int = 10):
        self.canary_percentage = canary_percentage
    
    def select_variant(self) -> DeploymentVariant:
        """Select deployment variant for request."""
        import random
        
        if random.randint(1, 100) <= self.canary_percentage:
            return DeploymentVariant.CANARY
        return DeploymentVariant.CURRENT

router = ABTestRouter(canary_percentage=10)

async def run_agent_with_variant(input_data: dict) -> dict:
    """Run agent with A/B testing."""
    
    variant = router.select_variant()
    
    # Track variant selection
    statsd.increment(
        "marketing_agent.variant.selection",
        tags=[f"variant:{variant.value}"]
    )
    
    if variant == DeploymentVariant.CANARY:
        # Use new prompt/model
        response = await run_canary_agent(input_data)
    else:
        # Use current production version
        response = await run_current_agent(input_data)
    
    # Track variant performance
    statsd.histogram(
        "marketing_agent.variant.latency",
        response.latency,
        tags=[f"variant:{variant.value}"]
    )
    
    return response
```

---

## Best Practices Summary

### DO ✅
1. **Separate prompts from code** - Version, test, A/B test
2. **Use structured outputs** - Pydantic models for reliability
3. **Implement retry logic** - With exponential backoff
4. **Cache responses** - Avoid redundant LLM calls
5. **Track everything** - Costs, latency, tokens, errors
6. **Test with golden datasets** - Prevent regressions
7. **Redact PII** - Before sending to LLMs
8. **Use appropriate models** - Balance cost vs quality
9. **Implement circuit breakers** - Fail fast when needed
10. **Monitor in production** - Real-time alerts

### DON'T ❌
1. **Inline prompts** - Hard to maintain
2. **Ignore token limits** - Will fail at scale
3. **Skip error handling** - APIs will fail
4. **Send all requests to GPT-4** - Expensive
5. **Forget to log** - Can't debug
6. **Skip evaluation** - Can't measure quality
7. **Expose PII** - Compliance risk
8. **Deploy without testing** - Will break in production
9. **Ignore costs** - Bills add up fast
10. **Use blocking calls** - Kills performance

---

## Additional Resources

- [LangChain Best Practices](https://python.langchain.com/docs/guides/productionization/)
- [OpenAI Production Best Practices](https://platform.openai.com/docs/guides/production-best-practices)
- [Evaluating LLMs](https://www.promptingguide.ai/introduction/evaluations)

---

**This document is continuously updated with new patterns and learnings from production.**
