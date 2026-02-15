# AI Evaluation Framework

Comprehensive evaluation framework for the Marketing Agent AI system with golden datasets, custom evaluators, and automated testing.

## Overview

The evaluation framework provides:

- **Golden Datasets**: Curated test cases with expected outputs
- **Custom Evaluators**: Domain-specific evaluation metrics
- **Automated Testing**: CI/CD integration for continuous evaluation
- **Observability**: LangSmith and Prometheus integration
- **Reporting**: Detailed evaluation reports and dashboards

## Architecture

```
evaluation/
├── datasets/
│   └── golden/              # Golden datasets
│       ├── campaign_optimization.json
│       └── creative_performance.json
├── reports/                 # Generated reports
└── results/                 # Evaluation results

src/evaluation/
├── evaluator.py            # Core evaluation logic
└── observability.py        # Observability integration

scripts/
├── run_evaluation.py       # Run evaluations
├── generate_evaluation_report.py
└── check_evaluation_thresholds.py
```

## Evaluation Metrics

The framework evaluates AI outputs across five key dimensions:

### 1. Relevance Score (0-1)

**What it measures**: How relevant the output is to the input and context

**Calculation**: 
- Keyword overlap between output and expected keywords
- Context matching  
- Topic relevance

**Threshold**: ≥ 0.70

**How to improve**:
- Refine prompts to focus on relevant information
- Add more context to inputs
- Fine-tune keyword matching

### 2. Accuracy Score (0-1)

**What it measures**: Factual correctness and precision of recommendations

**Calculation**:
- Recommendation type matching
- Action item correctness (action type, priority, content)
- Numerical accuracy (budgets, percentages, metrics)

**Threshold**: ≥ 0.70

**How to improve**:
- Validate data sources
- Add fact-checking steps
- Include more examples in prompts

### 3. Completeness Score (0-1)

**What it measures**: Whether all required elements are present

**Calculation**:
- Presence of recommendations
- Inclusion of insights
- Confidence score provided
- Required fields populated

**Threshold**: ≥ 0.80

**How to improve**:
- Use structured output formats
- Add validation checks
- Enforce required fields

### 4. Coherence Score (0-1)

**What it measures**: Logical flow and internal consistency

**Calculation**:
- Structural organization
- Logical connections between parts
- Consistency of recommendations
- Clarity of language

**Threshold**: ≥ 0.70

**How to improve**:
- Improve prompt structure
- Add explicit structure requirements
- Review for contradictions

### 5. Safety Score (0-1)

**What it measures**: Absence of harmful, biased, or inappropriate content

**Calculation**:
- No harmful language detected
- No discriminatory content
- No misleading information
- Compliance with guidelines

**Threshold**: 1.00 (perfect score required)

**How to improve**:
- Add safety guidelines to prompts
- Implement content filtering
- Review edge cases

## Golden Datasets

Golden datasets contain test cases with:
- **Inputs**: Test data (campaigns, creatives, signals)
- **Expected Outputs**: Ideal responses
- **Evaluation Criteria**: Scoring thresholds
- **Metadata**: Context and descriptions

### Campaign Optimization Dataset

**File**: `evaluation/datasets/golden/campaign_optimization.json`

**Test Cases**: 5

**Scenarios**:
1. Low performing campaign needing budget reallocation
2. High performing campaign with scaling opportunity  
3. Seasonal campaign requiring timing optimization
4. Competitor response requiring strategic adjustment
5. Multi-channel attribution and channel mix optimization

### Creative Performance Dataset

**File**: `evaluation/datasets/golden/creative_performance.json`

**Test Cases**: 3

**Scenarios**:
1. Creative fatigue detection and refresh recommendations
2. High performing creative for scaling
3. A/B test analysis with clear winner

## Usage

### Running Evaluations

#### Single Dataset

```bash
# Basic usage
python scripts/run_evaluation.py campaign_optimization

# With custom output directory
python scripts/run_evaluation.py campaign_optimization \
  --output-dir evaluation/results

# Without LangSmith tracing
python scripts/run_evaluation.py campaign_optimization \
  --no-tracing
```

#### All Datasets

```bash
# Evaluate all golden datasets
python scripts/run_evaluation.py --all
```

### Generating Reports

```bash
# Generate markdown and JSON reports
python scripts/generate_evaluation_report.py \
  --results-dir evaluation/results \
  --output-dir evaluation/reports
```

### Checking Thresholds

```bash
# Check if results meet thresholds (used in CI/CD)
python scripts/check_evaluation_thresholds.py \
  --results-dir evaluation/results \
  --min-pass-rate 0.85 \
  --min-relevance 0.70 \
  --min-accuracy 0.70 \
  --min-completeness 0.80 \
  --min-coherence 0.70 \
  --min-safety 1.00
```

## Integration

### In Code

```python
from src.evaluation.evaluator import MarketingAgentEvaluator
from src.evaluation.observability import initialize_observability

# Initialize observability
initialize_observability(
    project_name="marketing-agent",
    enable_tracing=True,
)

# Create evaluator
evaluator = MarketingAgentEvaluator(
    golden_dataset_path=Path("evaluation/datasets/golden")
)

# Evaluate output
metrics = evaluator.evaluate_response(
    input_data=input_data,
    output_data=actual_output,
    expected_output=expected_output,
    context=context,
)

print(f"Relevance: {metrics.relevance_score:.3f}")
print(f"Accuracy: {metrics.accuracy_score:.3f}")
print(f"Completeness: {metrics.completeness_score:.3f}")
```

### In CI/CD

The evaluation workflow (`.github/workflows/evaluation.yml`) automatically:

1. Runs on PRs and main branch pushes
2. Executes all golden dataset evaluations
3. Generates reports
4. Checks threshold violations
5. Comments results on PRs
6. Runs daily at 2 AM UTC

**Triggers**:
- Pull requests to `main` or `develop`
- Pushes to `main` branch
- Schedule (daily at 2 AM UTC)
- Manual dispatch

## Creating Custom Evaluators

```python
from src.evaluation.evaluator import BaseEvaluator

class CustomEvaluator(BaseEvaluator):
    """Custom evaluator for specific use case."""
    
    def evaluate(
        self,
        input_data: Dict[str, Any],
        output_data: Dict[str, Any],
        expected_output: Dict[str,Any],
    ) -> float:
        """Calculate custom evaluation score.
        
        Returns:
            Score between 0 and 1
        """
        # Your custom evaluation logic
        score = self._calculate_score(output_data, expected_output)
        
        return max(0.0, min(1.0, score))
```

## Creating Golden Datasets

```json
{
  "dataset_name": "my_custom_dataset",
  "version": "1.0.0",
  "description": "Description of this dataset",
  "created_at": "2026-02-15T00:00:00Z",
  "metadata": {
    "domain": "marketing",
    "use_case": "my_use_case"
  },
  "test_cases": [
    {
      "id": "test_001",
      "name": "Test Case Name",
      "description": "What this test case covers",
      "input": {
        // Your input data
      },
      "expected_output": {
        "recommendations": [...],
        "insights": [...],
        "confidence": 0.9,
        "keywords": ["key1", "key2"],
        "recommendation_types": ["type1", "type2"]
      }
    }
  ]
}
```

## Monitoring & Observability

### LangSmith

All evaluations are traced in LangSmith for debugging:

1. Set environment variables:
```bash
export LANGCHAIN_API_KEY="your-api-key"
export LANGCHAIN_TRACING_V2="true"
export LANGCHAIN_PROJECT="marketing-agent-eval"
```

2. View traces at: https://smith.langchain.com/

### Prometheus Metrics

Evaluation metrics are exposed for Prometheus:

```bash
curl http://localhost:8000/metrics | grep evaluation
```

Metrics:
- `marketing_agent_evaluation_score{metric="relevance"}` 
- `marketing_agent_evaluation_score{metric="accuracy"}`
- `marketing_agent_evaluation_score{metric="completeness"}`
- `marketing_agent_evaluation_score{metric="coherence"}`
- `marketing_agent_evaluation_score{metric="safety"}`

### Grafana Dashboard

Import the AI Operations dashboard:

1. Open Grafana (http://localhost:3000)
2. Import `monitoring/grafana/dashboards/marketing-agent-aiops.json`
3. View real-time evaluation metrics

## Best Practices

### 1. Regular Evaluation

- Run evaluations on every PR
- Schedule daily evaluation runs
- Review results weekly

### 2. Maintain Golden Datasets

- Update datasets when requirements change
- Add test cases for new features
- Review and prune obsolete cases
- Version datasets appropriately

### 3. Set Appropriate Thresholds

- Start conservative, adjust based on baseline
- Different thresholds for different use cases
- Safety should always be 1.0

### 4. Monitor Trends

- Track metrics over time
- Alert on degradation
- Celebrate improvements

### 5. Iterate on Failures

- Review failed test cases
- Update prompts or code
- Re-evaluate and document changes

## Troubleshooting

### Low Scores

**Problem**: Evaluation scores below thresholds

**Solutions**:
1. Review failed test cases in detail
2. Check if expected outputs are realistic
3. Analyze LangSmith traces for issues
4. Update prompts based on findings
5. Consider if thresholds need adjustment

### Inconsistent Results

**Problem**: Scores vary significantly between runs

**Solutions**:
1. Set temperature to 0 for deterministic outputs
2. Use seed parameter if available
3. Review input data for variability
4. Consider if test case is well-defined

### High Latency/Cost

**Problem**: Evaluations taking too long or costing too much

**Solutions**:
1. Reduce test case complexity
2. Use caching for repeated evaluations
3. Consider cheaper models for evaluation
4. Run evaluations in parallel

## Contributing

When adding new evaluation capabilities:

1. Create golden dataset first
2. Implement evaluator
3. Add tests
4. Update documentation
5. Update CI/CD workflow

## Resources

- [AI Observability Documentation](../docs/AI_OBSERVABILITY.md)
- [CI/CD Pipeline Documentation](../docs/CI_CD_PIPELINE.md)
- [LangSmith Documentation](https://docs.smith.langchain.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
