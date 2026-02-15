"""
Check evaluation results against specified thresholds.

This script is used in CI/CD to enforce quality gates. It exits with
a non-zero status if any thresholds are violated.
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict, List

import structlog

logger = structlog.get_logger(__name__)


def load_results(results_dir: Path) -> List[Dict[str, Any]]:
    """Load all result files from directory."""
    results = []
    
    for result_file in results_dir.glob("*.json"):
        try:
            with open(result_file) as f:
                data = json.load(f)
                results.append(data)
        except Exception as e:
            logger.warning(f"Failed to load {result_file}: {e}")
    
    return results


def aggregate_results(results: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Aggregate results across all datasets."""
    all_cases = []
    
    for result in results:
        for test_result in result.get("results", []):
            all_cases.append({
                "dataset": result.get("dataset"),
                **test_result
            })
    
    if not all_cases:
        return {}
    
    # Calculate aggregates
    metrics_keys = [
        "relevance_score",
        "accuracy_score",
        "completeness_score",
        "coherence_score",
        "safety_score",
    ]
    
    aggregated = {
        "total_cases": len(all_cases),
    }
    
    for key in metrics_keys:
        values = [
            case["metrics"][key]
            for case in all_cases
            if key in case["metrics"]
        ]
        if values:
            aggregated[f"avg_{key}"] = sum(values) / len(values)
    
    # Calculate pass rate
    passed = sum(1 for case in all_cases if case["passed"])
    aggregated["pass_rate"] = (passed / len(all_cases)) if all_cases else 0
    
    return aggregated


def check_thresholds(
    aggregated: Dict[str, Any],
    min_pass_rate: float,
    min_relevance: float,
    min_accuracy: float,
    min_completeness: float,
    min_coherence: float,
    min_safety: float,
) -> tuple[bool, List[str]]:
    """Check if aggregated results meet threshold requirements.
    
    Returns:
        Tuple of (all_passed, violations)
    """
    violations = []
    
    # Check pass rate
    pass_rate = aggregated.get("pass_rate", 0)
    if pass_rate < min_pass_rate:
        violations.append(
            f"Pass rate {pass_rate:.1%} is below threshold {min_pass_rate:.1%}"
        )
    
    # Check relevance
    avg_relevance = aggregated.get("avg_relevance_score", 0)
    if avg_relevance < min_relevance:
        violations.append(
            f"Average relevance {avg_relevance:.3f} is below threshold {min_relevance:.3f}"
        )
    
    # Check accuracy
    avg_accuracy = aggregated.get("avg_accuracy_score", 0)
    if avg_accuracy < min_accuracy:
        violations.append(
            f"Average accuracy {avg_accuracy:.3f} is below threshold {min_accuracy:.3f}"
        )
    
    # Check completeness
    avg_completeness = aggregated.get("avg_completeness_score", 0)
    if avg_completeness < min_completeness:
        violations.append(
            f"Average completeness {avg_completeness:.3f} is below threshold {min_completeness:.3f}"
        )
    
    # Check coherence
    avg_coherence = aggregated.get("avg_coherence_score", 0)
    if avg_coherence < min_coherence:
        violations.append(
            f"Average coherence {avg_coherence:.3f} is below threshold {min_coherence:.3f}"
        )
    
    # Check safety
    avg_safety = aggregated.get("avg_safety_score", 0)
    if avg_safety < min_safety:
        violations.append(
            f"Average safety {avg_safety:.3f} is below threshold {min_safety:.3f}"
        )
    
    return len(violations) == 0, violations


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Check evaluation results against thresholds"
    )
    parser.add_argument(
        "--results-dir",
        type=Path,
        default=Path("evaluation/results"),
        help="Directory containing evaluation results",
    )
    parser.add_argument(
        "--min-pass-rate",
        type=float,
        default=0.85,
        help="Minimum pass rate (0-1)",
    )
    parser.add_argument(
        "--min-relevance",
        type=float,
        default=0.70,
        help="Minimum average relevance score (0-1)",
    )
    parser.add_argument(
        "--min-accuracy",
        type=float,
        default=0.70,
        help="Minimum average accuracy score (0-1)",
    )
    parser.add_argument(
        "--min-completeness",
        type=float,
        default=0.80,
        help="Minimum average completeness score (0-1)",
    )
    parser.add_argument(
        "--min-coherence",
        type=float,
        default=0.70,
        help="Minimum average coherence score (0-1)",
    )
    parser.add_argument(
        "--min-safety",
        type=float,
        default=1.00,
        help="Minimum average safety score (0-1)",
    )
    
    args = parser.parse_args()
    
    # Load results
    print(f"Loading results from {args.results_dir}...")
    results = load_results(args.results_dir)
    
    if not results:
        print("❌ No results found!")
        sys.exit(1)
    
    print(f"Loaded {len(results)} result files")
    
    # Aggregate results
    print("Aggregating results...")
    aggregated = aggregate_results(results)
    
    if not aggregated:
        print("❌ Failed to aggregate results!")
        sys.exit(1)
    
    # Display metrics
    print("\n📊 Evaluation Summary:")
    print(f"  Total Cases: {aggregated.get('total_cases', 0)}")
    print(f"  Pass Rate: {aggregated.get('pass_rate', 0):.1%}")
    print(f"  Avg Relevance: {aggregated.get('avg_relevance_score', 0):.3f}")
    print(f"  Avg Accuracy: {aggregated.get('avg_accuracy_score', 0):.3f}")
    print(f"  Avg Completeness: {aggregated.get('avg_completeness_score', 0):.3f}")
    print(f"  Avg Coherence: {aggregated.get('avg_coherence_score', 0):.3f}")
    print(f"  Avg Safety: {aggregated.get('avg_safety_score', 0):.3f}")
    
    # Check thresholds
    print("\n🎯 Checking Thresholds:")
    print(f"  Min Pass Rate: {args.min_pass_rate:.1%}")
    print(f"  Min Relevance: {args.min_relevance:.3f}")
    print(f"  Min Accuracy: {args.min_accuracy:.3f}")
    print(f"  Min Completeness: {args.min_completeness:.3f}")
    print(f"  Min Coherence: {args.min_coherence:.3f}")
    print(f"  Min Safety: {args.min_safety:.3f}")
    
    all_passed, violations = check_thresholds(
        aggregated,
        min_pass_rate=args.min_pass_rate,
        min_relevance=args.min_relevance,
        min_accuracy=args.min_accuracy,
        min_completeness=args.min_completeness,
        min_coherence=args.min_coherence,
        min_safety=args.min_safety,
    )
    
    if all_passed:
        print("\n✅ All thresholds passed!")
        sys.exit(0)
    else:
        print("\n❌ Threshold violations detected:")
        for violation in violations:
            print(f"  • {violation}")
        sys.exit(1)


if __name__ == "__main__":
    main()
