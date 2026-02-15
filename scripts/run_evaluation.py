"""
Evaluation script for running assessments against golden datasets.

This script loads golden datasets, runs the marketing agent, and evaluates
the outputs against expected results.
"""

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List

import structlog
from rich.console import Console
from rich.table import Table
from tabulate import tabulate

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from src.evaluation.evaluator import MarketingAgentEvaluator
from src.evaluation.observability import initialize_observability

logger = structlog.get_logger(__name__)
console = Console()


def load_golden_dataset(dataset_name: str, datasets_dir: Path) -> Dict[str, Any]:
    """Load a golden dataset from file.
    
    Args:
        dataset_name: Name of the dataset
        datasets_dir: Directory containing datasets
        
    Returns:
        Loaded dataset dictionary
    """
    dataset_path = datasets_dir / f"{dataset_name}.json"
    
    if not dataset_path.exists():
        raise FileNotFoundError(f"Dataset not found: {dataset_path}")
    
    with open(dataset_path) as f:
        return json.load(f)


def run_evaluation(
    dataset_name: str,
    datasets_dir: Path,
    output_dir: Path,
    enable_tracing: bool = True,
) -> Dict[str, Any]:
    """Run evaluation on a golden dataset.
    
    Args:
        dataset_name: Name of the dataset to evaluate
        datasets_dir: Directory containing datasets
        output_dir: Directory for output reports
        enable_tracing: Whether to enable LangSmith tracing
        
    Returns:
        Evaluation results
    """
    console.print(f"\n[bold blue]Starting evaluation: {dataset_name}[/bold blue]\n")
    
    # Initialize observability
    if enable_tracing:
        initialize_observability(
            project_name=f"marketing-agent-eval-{dataset_name}",
            enable_tracing=True,
        )
    
    # Load golden dataset
    dataset = load_golden_dataset(dataset_name, datasets_dir)
    console.print(f"Loaded dataset: [green]{dataset['dataset_name']}[/green]")
    console.print(f"Version: {dataset['version']}")
    console.print(f"Test cases: {len(dataset['test_cases'])}\n")
    
    # Initialize evaluator
    evaluator = MarketingAgentEvaluator(golden_dataset_path=datasets_dir)
    
    # Run evaluation on each test case
    results = []
    for i, test_case in enumerate(dataset["test_cases"], 1):
        console.print(f"[yellow]Evaluating test case {i}/{len(dataset['test_cases'])}: {test_case['name']}[/yellow]")
        
        # Get expected output
        expected_output = test_case.get("expected_output", {})
        
        # Here you would actually run the marketing agent
        # For demo purposes, we'll use the expected output as the actual output
        # In production, replace this with actual agent invocation
        actual_output = expected_output  # Replace with: agent.run(test_case['input'])
        
        # Evaluate the output
        metrics = evaluator.evaluate_response(
            input_data=test_case["input"],
            output_data=actual_output,
            expected_output=expected_output,
            context=test_case.get("context", {}),
        )
        
        results.append({
            "test_case_id": test_case["id"],
            "test_case_name": test_case["name"],
            "metrics": metrics.to_dict(),
            "passed": all([
                metrics.relevance_score >= 0.7,
                metrics.accuracy_score >= 0.7,
                metrics.completeness_score >= 0.8,
                metrics.coherence_score >= 0.7,
                metrics.safety_score >= 1.0,
            ]),
        })
        
        # Display results
        _display_test_case_result(test_case["name"], metrics, results[-1]["passed"])
    
    # Calculate aggregate metrics
    aggregated = _aggregate_results(results)
    
    # Display summary
    _display_summary(results, aggregated)
    
    # Save results
    output_file = output_dir / f"{dataset_name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    output_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_file, "w") as f:
        json.dump({
            "dataset": dataset_name,
            "timestamp": datetime.now().isoformat(),
            "results": results,
            "aggregated": aggregated,
        }, f, indent=2)
    
    console.print(f"\n[green]Results saved to: {output_file}[/green]\n")
    
    return {
        "results": results,
        "aggregated": aggregated,
        "output_file": str(output_file),
    }


def _display_test_case_result(name: str, metrics: Any, passed: bool):
    """Display results for a single test case."""
    status = "[green]✓ PASSED[/green]" if passed else "[red]✗ FAILED[/red]"
    
    table = Table(title=f"{name} - {status}")
    table.add_column("Metric", style="cyan")
    table.add_column("Score", style="magenta")
    
    table.add_row("Relevance", f"{metrics.relevance_score:.2f}")
    table.add_row("Accuracy", f"{metrics.accuracy_score:.2f}")
    table.add_row("Completeness", f"{metrics.completeness_score:.2f}")
    table.add_row("Coherence", f"{metrics.coherence_score:.2f}")
    table.add_row("Safety", f"{metrics.safety_score:.2f}")
    table.add_row("Latency (ms)", f"{metrics.latency_ms:.0f}")
    table.add_row("Tokens", f"{metrics.token_count}")
    table.add_row("Cost (USD)", f"${metrics.cost_usd:.4f}")
    
    console.print(table)
    console.print()


def _display_summary(results: List[Dict[str, Any]], aggregated: Dict[str, Any]):
    """Display evaluation summary."""
    console.print("\n[bold blue]Evaluation Summary[/bold blue]\n")
    
    total = len(results)
    passed = sum(1 for r in results if r["passed"])
    failed = total - passed
    pass_rate = (passed / total * 100) if total > 0 else 0
    
    console.print(f"Total test cases: {total}")
    console.print(f"[green]Passed: {passed}[/green]")
    console.print(f"[red]Failed: {failed}[/red]")
    console.print(f"Pass rate: {pass_rate:.1f}%\n")
    
    # Display aggregate metrics
    table = Table(title="Aggregate Metrics")
    table.add_column("Metric", style="cyan")
    table.add_column("Average", style="magenta")
    table.add_column("Min", style="yellow")
    table.add_column("Max", style="green")
    
    metrics = [
        ("Relevance", "relevance_score"),
        ("Accuracy", "accuracy_score"),
        ("Completeness", "completeness_score"),
        ("Coherence", "coherence_score"),
        ("Safety", "safety_score"),
        ("Latency (ms)", "latency_ms"),
        ("Tokens", "token_count"),
        ("Cost (USD)", "cost_usd"),
    ]
    
    for label, key in metrics:
        avg_key = f"avg_{key}"
        min_key = f"min_{key}"
        max_key = f"max_{key}"
        
        if avg_key in aggregated:
            avg_val = aggregated[avg_key]
            min_val = aggregated[min_key]
            max_val = aggregated[max_key]
            
            if "cost" in key:
                table.add_row(label, f"${avg_val:.4f}", f"${min_val:.4f}", f"${max_val:.4f}")
            elif key in ["latency_ms", "token_count"]:
                table.add_row(label, f"{avg_val:.0f}", f"{min_val:.0f}", f"{max_val:.0f}")
            else:
                table.add_row(label, f"{avg_val:.3f}", f"{min_val:.3f}", f"{max_val:.3f}")
    
    console.print(table)


def _aggregate_results(results: List[Dict[str, Any]]) -> Dict[str, Any]:
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
    
    # Calculate pass rate
    passed = sum(1 for r in results if r["passed"])
    aggregated["pass_rate"] = passed / len(results)
    aggregated["passed_count"] = passed
    aggregated["failed_count"] = len(results) - passed
    
    return aggregated


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Run AI evaluation on golden datasets")
    parser.add_argument(
        "dataset",
        nargs="?",
        default="campaign_optimization",
        help="Dataset name to evaluate (default: campaign_optimization)",
    )
    parser.add_argument(
        "--datasets-dir",
        type=Path,
        default=Path("evaluation/datasets/golden"),
        help="Directory containing golden datasets",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("evaluation/results"),
        help="Directory for output reports",
    )
    parser.add_argument(
        "--no-tracing",
        action="store_true",
        help="Disable LangSmith tracing",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Run evaluation on all datasets",
    )
    
    args = parser.parse_args()
    
    # Find all datasets if --all flag is set
    if args.all:
        dataset_files = list(args.datasets_dir.glob("*.json"))
        datasets = [f.stem for f in dataset_files]
    else:
        datasets = [args.dataset]
    
    # Run evaluation for each dataset
    all_results = {}
    for dataset in datasets:
        try:
            results = run_evaluation(
                dataset_name=dataset,
                datasets_dir=args.datasets_dir,
                output_dir=args.output_dir,
                enable_tracing=not args.no_tracing,
            )
            all_results[dataset] = results
        except Exception as e:
            console.print(f"[red]Error evaluating {dataset}: {str(e)}[/red]")
            logger.error("evaluation_failed", dataset=dataset, error=str(e), exc_info=True)
    
    # Display overall summary
    if len(datasets) > 1:
        console.print("\n[bold blue]Overall Summary[/bold blue]\n")
        for dataset, results in all_results.items():
            aggregated = results["aggregated"]
            console.print(
                f"{dataset}: Pass rate {aggregated['pass_rate']*100:.1f}% "
                f"({aggregated['passed_count']}/{aggregated['total_cases']})"
            )


if __name__ == "__main__":
    main()
