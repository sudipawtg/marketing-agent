"""
Observability and monitoring for AI operations.

Provides integration with LangSmith, metrics collection, and monitoring.
"""

import os
import time
from contextlib import contextmanager
from typing import Any, Dict, Optional

import structlog
from langsmith import Client, traceable
from langsmith.run_trees import RunTree
from prometheus_client import Counter, Histogram, Gauge

logger = structlog.get_logger(__name__)


# Prometheus metrics
AGENT_REQUESTS = Counter(
    "marketing_agent_requests_total",
    "Total number of agent requests",
    ["endpoint", "status"],
)

AGENT_LATENCY = Histogram(
    "marketing_agent_latency_seconds",
    "Agent request latency",
    ["endpoint"],
    buckets=[0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 30.0],
)

AGENT_TOKENS = Histogram(
    "marketing_agent_tokens_total",
    "Total tokens used per request",
    ["model"],
    buckets=[100, 500, 1000, 2000, 5000, 10000, 20000],
)

AGENT_COST = Histogram(
    "marketing_agent_cost_usd",
    "Cost per request in USD",
    ["model"],
    buckets=[0.001, 0.01, 0.05, 0.1, 0.5, 1.0, 5.0],
)

EVALUATION_SCORES = Gauge(
    "marketing_agent_evaluation_score",
    "Current evaluation scores",
    ["metric_type"],
)

ACTIVE_REQUESTS = Gauge(
    "marketing_agent_active_requests",
    "Number of active requests",
)


class ObservabilityManager:
    """Manages observability for the marketing agent."""
    
    def __init__(
        self,
        langsmith_api_key: Optional[str] = None,
        project_name: str = "marketing-agent",
        enable_tracing: bool = True,
    ):
        """Initialize observability manager.
        
        Args:
            langsmith_api_key: LangSmith API key (defaults to env var)
            project_name: LangSmith project name
            enable_tracing: Whether to enable LangSmith tracing
        """
        self.project_name = project_name
        self.enable_tracing = enable_tracing
        self.logger = logger.bind(component="observability")
        
        # Initialize LangSmith client
        api_key = langsmith_api_key or os.getenv("LANGSMITH_API_KEY")
        if api_key and enable_tracing:
            self.langsmith_client = Client(api_key=api_key)
            os.environ["LANGCHAIN_TRACING_V2"] = "true"
            os.environ["LANGCHAIN_PROJECT"] = project_name
            self.logger.info("langsmith_initialized", project=project_name)
        else:
            self.langsmith_client = None
            self.logger.warning("langsmith_disabled")
    
    @contextmanager
    def trace_request(
        self,
        endpoint: str,
        inputs: Dict[str, Any],
        metadata: Optional[Dict[str, Any]] = None,
    ):
        """Context manager for tracing agent requests.
        
        Args:
            endpoint: API endpoint or operation name
            inputs: Input data for the request
            metadata: Additional metadata
            
        Yields:
            Dictionary to store outputs and metrics
        """
        ACTIVE_REQUESTS.inc()
        start_time = time.time()
        
        context = {
            "endpoint": endpoint,
            "inputs": inputs,
            "metadata": metadata or {},
            "outputs": None,
            "error": None,
            "metrics": {},
        }
        
        # Create LangSmith run tree if enabled
        run_tree = None
        if self.langsmith_client and self.enable_tracing:
            run_tree = RunTree(
                name=endpoint,
                inputs=inputs,
                project_name=self.project_name,
                extra=metadata or {},
            )
        
        try:
            yield context
            
            # Record success
            status = "success" if not context.get("error") else "error"
            AGENT_REQUESTS.labels(endpoint=endpoint, status=status).inc()
            
        except Exception as e:
            context["error"] = str(e)
            AGENT_REQUESTS.labels(endpoint=endpoint, status="error").inc()
            self.logger.error(
                "request_failed",
                endpoint=endpoint,
                error=str(e),
                exc_info=True,
            )
            raise
        
        finally:
            # Calculate latency
            latency = time.time() - start_time
            AGENT_LATENCY.labels(endpoint=endpoint).observe(latency)
            context["metrics"]["latency_seconds"] = latency
            
            # Update LangSmith run tree
            if run_tree:
                run_tree.end(
                    outputs=context.get("outputs"),
                    error=context.get("error"),
                )
                run_tree.post()
            
            # Log request completion
            self.logger.info(
                "request_complete",
                endpoint=endpoint,
                latency_seconds=latency,
                status="success" if not context.get("error") else "error",
                metrics=context["metrics"],
            )
            
            ACTIVE_REQUESTS.dec()
    
    def record_token_usage(
        self,
        model: str,
        prompt_tokens: int,
        completion_tokens: int,
        total_tokens: int,
    ):
        """Record token usage metrics.
        
        Args:
            model: Model name
            prompt_tokens: Number of prompt tokens
            completion_tokens: Number of completion tokens
            total_tokens: Total tokens used
        """
        AGENT_TOKENS.labels(model=model).observe(total_tokens)
        
        self.logger.info(
            "token_usage",
            model=model,
            prompt_tokens=prompt_tokens,
            completion_tokens=completion_tokens,
            total_tokens=total_tokens,
        )
    
    def record_cost(self, model: str, cost_usd: float):
        """Record cost metrics.
        
        Args:
            model: Model name
            cost_usd: Cost in USD
        """
        AGENT_COST.labels(model=model).observe(cost_usd)
        
        self.logger.info("cost_recorded", model=model, cost_usd=cost_usd)
    
    def record_evaluation_scores(self, scores: Dict[str, float]):
        """Record evaluation scores.
        
        Args:
            scores: Dictionary of metric names to scores
        """
        for metric_name, score in scores.items():
            EVALUATION_SCORES.labels(metric_type=metric_name).set(score)
        
        self.logger.info("evaluation_scores_recorded", scores=scores)
    
    def create_feedback(
        self,
        run_id: str,
        score: float,
        feedback_type: str = "thumbs",
        comment: Optional[str] = None,
    ):
        """Create feedback for a run in LangSmith.
        
        Args:
            run_id: LangSmith run ID
            score: Feedback score
            feedback_type: Type of feedback
            comment: Optional comment
        """
        if not self.langsmith_client:
            self.logger.warning("feedback_skipped_no_client")
            return
        
        try:
            self.langsmith_client.create_feedback(
                run_id=run_id,
                key=feedback_type,
                score=score,
                comment=comment,
            )
            self.logger.info("feedback_created", run_id=run_id, score=score)
        except Exception as e:
            self.logger.error("feedback_creation_failed", error=str(e))


# Decorator for tracing functions
def trace_operation(operation_name: str):
    """Decorator to trace a function with LangSmith.
    
    Args:
        operation_name: Name of the operation
    """
    def decorator(func):
        # Use LangSmith's traceable decorator if available
        return traceable(name=operation_name)(func)
    
    return decorator


# Global observability manager instance
_observability_manager: Optional[ObservabilityManager] = None


def get_observability_manager() -> ObservabilityManager:
    """Get or create global observability manager."""
    global _observability_manager
    if _observability_manager is None:
        _observability_manager = ObservabilityManager()
    return _observability_manager


def initialize_observability(
    langsmith_api_key: Optional[str] = None,
    project_name: str = "marketing-agent",
    enable_tracing: bool = True,
):
    """Initialize global observability manager.
    
    Args:
        langsmith_api_key: LangSmith API key
        project_name: LangSmith project name
        enable_tracing: Whether to enable tracing
    """
    global _observability_manager
    _observability_manager = ObservabilityManager(
        langsmith_api_key=langsmith_api_key,
        project_name=project_name,
        enable_tracing=enable_tracing,
    )
    return _observability_manager
