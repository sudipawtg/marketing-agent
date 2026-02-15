"""
AI Model Evaluation Framework

This module provides comprehensive evaluation capabilities for the marketing agent,
including metrics calculation, golden dataset testing, and observability.
"""

import json
import time
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

import structlog
from langsmith import Client
from langsmith.evaluation import EvaluationResult, RunEvaluator

logger = structlog.get_logger(__name__)


@dataclass
class EvaluationMetrics:
    """Container for evaluation metrics."""
    
    relevance_score: float
    accuracy_score: float
    completeness_score: float
    coherence_score: float
    safety_score: float
    latency_ms: float
    token_count: int
    cost_usd: float
    timestamp: datetime
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert metrics to dictionary."""
        return {
            "relevance_score": self.relevance_score,
            "accuracy_score": self.accuracy_score,
            "completeness_score": self.completeness_score,
            "coherence_score": self.coherence_score,
            "safety_score": self.safety_score,
            "latency_ms": self.latency_ms,
            "token_count": self.token_count,
            "cost_usd": self.cost_usd,
            "timestamp": self.timestamp.isoformat(),
        }


class RelevanceEvaluator(RunEvaluator):
    """Evaluates relevance of agent outputs to inputs."""
    
    def evaluate_run(self, run, example) -> EvaluationResult:
        """Evaluate a single run for relevance."""
        # Extract output and expected
        output = run.outputs.get("output", "")
        expected = example.outputs.get("expected_keywords", [])
        
        # Calculate relevance score based on keyword matching
        if not expected:
            return EvaluationResult(key="relevance", score=1.0)
        
        matches = sum(1 for keyword in expected if keyword.lower() in output.lower())
        score = matches / len(expected)
        
        return EvaluationResult(
            key="relevance",
            score=score,
            comment=f"Matched {matches}/{len(expected)} keywords"
        )


class AccuracyEvaluator(RunEvaluator):
    """Evaluates accuracy of recommendations."""
    
    def evaluate_run(self, run, example) -> EvaluationResult:
        """Evaluate a single run for accuracy."""
        output = run.outputs.get("recommendations", [])
        expected = example.outputs.get("expected_recommendations", [])
        
        if not expected:
            return EvaluationResult(key="accuracy", score=1.0)
        
        # Compare recommendation types
        output_types = {rec.get("type") for rec in output if isinstance(rec, dict)}
        expected_types = set(expected)
        
        matches = len(output_types.intersection(expected_types))
        score = matches / len(expected_types) if expected_types else 1.0
        
        return EvaluationResult(
            key="accuracy",
            score=score,
            comment=f"Matched {matches}/{len(expected_types)} recommendation types"
        )


class SafetyEvaluator(RunEvaluator):
    """Evaluates safety of agent outputs."""
    
    UNSAFE_PATTERNS = [
        "offensive",
        "discriminatory",
        "harmful",
        "inappropriate",
        "misleading",
        "false claim",
    ]
    
    def evaluate_run(self, run, example) -> EvaluationResult:
        """Evaluate a single run for safety."""
        output = str(run.outputs.get("output", "")).lower()
        
        # Check for unsafe patterns
        unsafe_found = [pattern for pattern in self.UNSAFE_PATTERNS if pattern in output]
        
        score = 1.0 if not unsafe_found else 0.0
        comment = f"Unsafe patterns found: {unsafe_found}" if unsafe_found else "Safe"
        
        return EvaluationResult(
            key="safety",
            score=score,
            comment=comment
        )


class MarketingAgentEvaluator:
    """Main evaluator for marketing agent performance."""
    
    def __init__(
        self,
        langsmith_client: Optional[Client] = None,
        golden_dataset_path: Optional[Path] = None,
    ):
        """Initialize evaluator.
        
        Args:
            langsmith_client: LangSmith client for tracking
            golden_dataset_path: Path to golden dataset directory
        """
        self.langsmith_client = langsmith_client or Client()
        self.golden_dataset_path = golden_dataset_path or Path("evaluation/datasets/golden")
        self.logger = logger.bind(component="evaluator")
        
        # Initialize custom evaluators
        self.evaluators = [
            RelevanceEvaluator(),
            AccuracyEvaluator(),
            SafetyEvaluator(),
        ]
    
    def evaluate_response(
        self,
        input_data: Dict[str, Any],
        output_data: Dict[str, Any],
        expected_output: Optional[Dict[str, Any]] = None,
        context: Optional[Dict[str, Any]] = None,
    ) -> EvaluationMetrics:
        """Evaluate a single agent response.
        
        Args:
            input_data: Input to the agent
            output_data: Output from the agent
            expected_output: Expected output for comparison
            context: Additional context (latency, tokens, cost)
            
        Returns:
            EvaluationMetrics object
        """
        start_time = time.time()
        
        # Calculate individual metrics
        relevance = self._calculate_relevance(output_data, expected_output)
        accuracy = self._calculate_accuracy(output_data, expected_output)
        completeness = self._calculate_completeness(output_data, expected_output)
        coherence = self._calculate_coherence(output_data)
        safety = self._calculate_safety(output_data)
        
        # Get performance metrics from context
        latency_ms = context.get("latency_ms", 0) if context else 0
        token_count = context.get("token_count", 0) if context else 0
        cost_usd = context.get("cost_usd", 0.0) if context else 0.0
        
        metrics = EvaluationMetrics(
            relevance_score=relevance,
            accuracy_score=accuracy,
            completeness_score=completeness,
            coherence_score=coherence,
            safety_score=safety,
            latency_ms=latency_ms,
            token_count=token_count,
            cost_usd=cost_usd,
            timestamp=datetime.now(),
        )
        
        self.logger.info(
            "evaluation_complete",
            metrics=metrics.to_dict(),
            duration_ms=(time.time() - start_time) * 1000,
        )
        
        return metrics
    
    def _calculate_relevance(
        self,
        output: Dict[str, Any],
        expected: Optional[Dict[str, Any]],
    ) -> float:
        """Calculate relevance score (0-1)."""
        if not expected:
            return 1.0
        
        # Check if output contains expected keywords
        output_text = json.dumps(output).lower()
        expected_keywords = expected.get("keywords", [])
        
        if not expected_keywords:
            return 1.0
        
        matches = sum(1 for keyword in expected_keywords if keyword.lower() in output_text)
        return matches / len(expected_keywords)
    
    def _calculate_accuracy(
        self,
        output: Dict[str, Any],
        expected: Optional[Dict[str, Any]],
    ) -> float:
        """Calculate accuracy score (0-1)."""
        if not expected:
            return 1.0
        
        recommendations = output.get("recommendations", [])
        expected_types = expected.get("recommendation_types", [])
        
        if not expected_types:
            return 1.0
        
        output_types = {rec.get("type") for rec in recommendations if isinstance(rec, dict)}
        matches = len(output_types.intersection(set(expected_types)))
        
        return matches / len(expected_types)
    
    def _calculate_completeness(
        self,
        output: Dict[str, Any],
        expected: Optional[Dict[str, Any]],
    ) -> float:
        """Calculate completeness score (0-1)."""
        if not expected:
            return 1.0
        
        # Check if all required fields are present
        required_fields = expected.get("required_fields", [])
        if not required_fields:
            return 1.0
        
        present_fields = [field for field in required_fields if field in output]
        return len(present_fields) / len(required_fields)
    
    def _calculate_coherence(self, output: Dict[str, Any]) -> float:
        """Calculate coherence score (0-1)."""
        # Basic coherence check - ensure output has structure
        if not isinstance(output, dict):
            return 0.5
        
        # Check for key components
        has_analysis = "analysis" in output or "reasoning" in output
        has_recommendations = "recommendations" in output
        has_confidence = "confidence" in output
        
        components = [has_analysis, has_recommendations, has_confidence]
        return sum(components) / len(components)
    
    def _calculate_safety(self, output: Dict[str, Any]) -> float:
        """Calculate safety score (0-1)."""
        output_text = json.dumps(output).lower()
        
        # Check for unsafe patterns
        unsafe_patterns = [
            "offensive",
            "discriminatory",
            "harmful",
            "misleading",
            "false",
            "inappropriate",
        ]
        
        unsafe_found = sum(1 for pattern in unsafe_patterns if pattern in output_text)
        
        # Return 0 if any unsafe pattern found, otherwise 1
        return 0.0 if unsafe_found > 0 else 1.0
    
    def run_golden_dataset_evaluation(self, dataset_name: str) -> Dict[str, Any]:
        """Run evaluation against golden dataset.
        
        Args:
            dataset_name: Name of the golden dataset
            
        Returns:
            Aggregated evaluation results
        """
        self.logger.info("starting_golden_dataset_evaluation", dataset=dataset_name)
        
        dataset_path = self.golden_dataset_path / f"{dataset_name}.json"
        if not dataset_path.exists():
            raise FileNotFoundError(f"Golden dataset not found: {dataset_path}")
        
        # Load golden dataset
        with open(dataset_path) as f:
            golden_data = json.load(f)
        
        results = []
        for i, test_case in enumerate(golden_data.get("test_cases", [])):
            self.logger.info(
                "evaluating_test_case",
                case_id=test_case.get("id"),
                index=i + 1,
                total=len(golden_data.get("test_cases", [])),
            )
            
            # Here you would actually run the agent
            # For now, we'll use the expected output as a placeholder
            output = test_case.get("expected_output", {})
            
            metrics = self.evaluate_response(
                input_data=test_case.get("input", {}),
                output_data=output,
                expected_output=test_case.get("expected_output", {}),
                context=test_case.get("context", {}),
            )
            
            results.append({
                "test_case_id": test_case.get("id"),
                "metrics": metrics.to_dict(),
            })
        
        # Aggregate results
        aggregated = self._aggregate_results(results)
        
        self.logger.info(
            "golden_dataset_evaluation_complete",
            dataset=dataset_name,
            aggregated_metrics=aggregated,
        )
        
        return aggregated
    
    def _aggregate_results(self, results: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Aggregate evaluation results."""
        if not results:
            return {}
        
        metrics_keys = [
            "relevance_score",
            "accuracy_score",
            "completeness_score",
            "coherence_score",
            "safety_score",
            "latency_ms",
            "token_count",
            "cost_usd",
        ]
        
        aggregated = {
            "total_cases": len(results),
            "timestamp": datetime.now().isoformat(),
        }
        
        for key in metrics_keys:
            values = [r["metrics"][key] for r in results if key in r["metrics"]]
            if values:
                aggregated[f"avg_{key}"] = sum(values) / len(values)
                aggregated[f"min_{key}"] = min(values)
                aggregated[f"max_{key}"] = max(values)
        
        # Calculate pass rate (all scores > 0.7)
        passing = sum(
            1 for r in results
            if all(
                r["metrics"].get(f"{key}_score", 0) >= 0.7
                for key in ["relevance", "accuracy", "completeness", "coherence", "safety"]
            )
        )
        aggregated["pass_rate"] = passing / len(results)
        
        return aggregated
