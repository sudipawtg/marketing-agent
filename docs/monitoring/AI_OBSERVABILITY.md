# AI Observability & Monitoring

This document describes the observability and monitoring setup for the Marketing Agent AI system.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [LangSmith Integration](#langsmith-integration)
- [Prometheus Metrics](#prometheus-metrics)
- [Grafana Dashboards](#grafana-dashboards)
- [Evaluation Framework](#evaluation-framework)
- [Usage Guide](#usage-guide)
- [Troubleshooting](#troubleshooting)

## Overview

The Marketing Agent includes comprehensive observability and monitoring capabilities to track:

- **Performance Metrics**: Latency, throughput, error rates
- **AI Metrics**: Token usage, costs, model performance
- **Evaluation Metrics**: Relevance, accuracy, completeness, coherence, safety
- **System Health**: Resource utilization, availability

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                     Marketing Agent Application                   │
│                                                                    │
│  ┌──────────────────┐         ┌─────────────────────┐           │
│  │  Agent Workflow  │────────▶│ ObservabilityManager│           │
│  └──────────────────┘         └─────────────────────┘           │
│                                         │                         │
└─────────────────────────────────────────┼─────────────────────────┘
                                          │
                  ┌───────────────────────┼───────────────────────┐
                  │                       │                       │
                  ▼                       ▼                       ▼
          ┌──────────────┐       ┌──────────────┐       ┌──────────────┐
          │  LangSmith   │       │  Prometheus  │       │   Sentry     │
          │   (Traces)   │       │  (Metrics)   │       │   (Errors)   │
          └──────────────┘       └──────────────┘       └──────────────┘
                                          │
                                          ▼
                                  ┌──────────────┐
                                  │   Grafana    │
                                  │ (Dashboards) │
                                  └──────────────┘
```

## LangSmith Integration

### Setup

1. **Get API Key**: Sign up at [LangSmith](https://smith.langchain.com/)

2. **Configure Environment**:
```bash
export LANGCHAIN_API_KEY="your-api-key"
export LANGCHAIN_TRACING_V2="true"
export LANGCHAIN_PROJECT="marketing-agent"
```

3. **Initialize in Code**:
```python
from src.evaluation.observability import initialize_observability

# Initialize observability
initialize_observability(
    project_name="marketing-agent",
    enable_tracing=True,
)
```

### Features

- **Automatic Tracing**: All LLM calls are automatically traced
- **Custom Metadata**: Add custom tags and metadata to traces
- **Run Groups**: Organize runs by feature or experiment
- **Feedback System**: Capture human feedback on outputs

### Usage Example

```python
from src.evaluation.observability import get_observability_manager

obs_manager = get_observability_manager()

# Trace a request
with obs_manager.trace_request(
    operation="campaign_optimization",
    metadata={"campaign_id": "CAMP_001"}
) as trace_context:
    # Your code here
    result = agent.run(input_data)
    
    # Record metrics
    obs_manager.record_token_usage(
        prompt_tokens=1000,
        completion_tokens=500,
    )
```

## Prometheus Metrics

### Available Metrics

#### Request Metrics

```prometheus
# Total number of requests
marketing_agent_requests_total{status, endpoint}

# Request latency histogram
marketing_agent_request_latency_seconds{endpoint}

# Concurrent requests
marketing_agent_concurrent_requests
```

#### Token Metrics

```prometheus
# Token usage counter
marketing_agent_tokens_total{type}  # type: prompt|completion

# Token rate gauge
marketing_agent_token_rate{type}
```

#### Cost Metrics

```prometheus
# Total cost in USD
marketing_agent_cost_usd_total

# Cost per request
marketing_agent_cost_per_request
```

#### Evaluation Metrics

```prometheus
# Evaluation scores
marketing_agent_evaluation_score{metric}  # metric: relevance|accuracy|completeness|coherence|safety
```

### Exporting Metrics

Metrics are exposed at `/metrics` endpoint:

```bash
curl http://localhost:8000/metrics
```

### Prometheus Configuration

Add to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'marketing-agent'
    scrape_interval: 15s
    static_configs:
      - targets: ['localhost:8000']
```

## Grafana Dashboards

### Marketing Agent - AI Operations Dashboard

Located at: `monitoring/grafana/dashboards/marketing-agent-aiops.json`

#### Panels

1. **Request Rate by Status**: Shows request throughput and success/error rates
2. **P95 Latency**: 95th percentile latency with thresholds
3. **Evaluation Scores Over Time**: Tracks all evaluation metrics
4. **Token Usage**: Hourly token consumption breakdown
5. **Daily Cost**: Total cost with budget thresholds
6. **Success Rate**: Overall system health indicator
7. **Median Latency**: Typical response time

### Importing Dashboard

1. Open Grafana UI
2. Go to Dashboards → Import
3. Upload `marketing-agent-aiops.json`
4. Select Prometheus datasource
5. Click Import

### Alerts

Configure alerts in Grafana for:

- **High Latency**: P95 > 3000ms
- **Low Success Rate**: < 95%
- **High Cost**: Daily spend > $100
- **Low Evaluation Scores**: Any metric < 0.7

## Evaluation Framework

### Golden Datasets

Golden datasets are used for continuous evaluation and regression testing.

Location: `evaluation/datasets/golden/`

Datasets:
- `campaign_optimization.json`: Campaign optimization test cases
- `creative_performance.json`: Creative analysis test cases

### Running Evaluations

#### Single Dataset

```bash
python scripts/run_evaluation.py campaign_optimization \
  --output-dir evaluation/results
```

#### All Datasets

```bash
python scripts/run_evaluation.py --all \
  --output-dir evaluation/results
```

#### With LangSmith Tracing

```bash
export LANGCHAIN_API_KEY="your-key"
export LANGCHAIN_TRACING_V2="true"

python scripts/run_evaluation.py campaign_optimization
```

### Evaluation Metrics

The evaluator calculates the following metrics:

- **Relevance Score** (0-1): How relevant the output is to the input
- **Accuracy Score** (0-1): Factual correctness of the output
- **Completeness Score** (0-1): Whether all required elements are present
- **Coherence Score** (0-1): Logical flow and structure
- **Safety Score** (0-1): Absence of harmful content

### Custom Evaluators

Create custom evaluators by extending the base evaluator:

```python
from src.evaluation.evaluator import BaseEvaluator

class CustomEvaluator(BaseEvaluator):
    def evaluate(self, input_data, output_data, expected_output):
        # Your evaluation logic
        score = self.calculate_score(output_data, expected_output)
        return score
```

## Usage Guide

### Local Development

1. **Start Observability Stack**:
```bash
docker-compose up -d prometheus grafana
```

2. **Initialize Observability**:
```python
from src.evaluation.observability import initialize_observability

initialize_observability(
    project_name="marketing-agent-dev",
    enable_tracing=True,
)
```

3. **View Dashboards**:
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090

### CI/CD Integration

The `.github/workflows/evaluation.yml` workflow automatically:

1. Runs evaluations on all golden datasets
2. Generates reports
3. Checks threshold violations
4. Comments results on PRs
5. Uploads artifacts

### Production Monitoring

1. **Enable Production Tracing**:
```bash
export LANGCHAIN_PROJECT="marketing-agent-prod"
export LANGCHAIN_TRACING_V2="true"
```

2. **Configure Alerts**:
   - Set up Grafana alerts for critical metrics
   - Configure PagerDuty integration
   - Set up Slack notifications

3. **Schedule Evaluations**:
   - Daily evaluation runs via GitHub Actions
   - Weekly baseline comparisons
   - Monthly performance reviews

## Troubleshooting

### High Latency

**Symptoms**: P95 latency > 3000ms

**Diagnosis**:
```bash
# Check LangSmith traces
# Visit https://smith.langchain.com/

# Check Prometheus metrics
curl http://localhost:8000/metrics | grep latency
```

**Solutions**:
- Optimize prompts to reduce tokens
- Enable caching for common queries
- Scale up infrastructure
- Review LLM model selection

### Low Evaluation Scores

**Symptoms**: Evaluation scores < 0.7

**Diagnosis**:
```bash
# Run evaluation with detailed output
python scripts/run_evaluation.py campaign_optimization \
  --output-dir evaluation/results

# Review failed test cases
cat evaluation/results/campaign_optimization_*.json | jq '.results[] | select(.passed == false)'
```

**Solutions**:
- Review and update prompts
- Add more examples to prompts
- Fine-tune evaluation criteria
- Update golden datasets if expectations changed

### High Costs

**Symptoms**: Daily cost > budget threshold

**Diagnosis**:
```bash
# Check token usage
curl http://localhost:8000/metrics | grep tokens

# Review cost breakdown
cat evaluation/results/*.json | jq '.aggregated.avg_cost_usd'
```

**Solutions**:
- Implement request throttling
- Use cheaper models for simple tasks
- Enable aggressive caching
- Review and optimize prompts

### Missing Traces in LangSmith

**Symptoms**: No traces appearing in LangSmith

**Diagnosis**:
```bash
# Check environment variables
echo $LANGCHAIN_API_KEY
echo $LANGCHAIN_TRACING_V2

# Test connection
python -c "from langsmith import Client; client = Client(); print(client.info())"
```

**Solutions**:
- Verify API key is correct
- Ensure `LANGCHAIN_TRACING_V2="true"`
- Check network connectivity
- Review firewall rules

## Best Practices

1. **Always Enable Tracing in Production**: Essential for debugging and optimization
2. **Set Up Alerts**: Don't wait for users to report issues
3. **Regular Evaluation**: Run golden dataset evaluations daily
4. **Cost Monitoring**: Track costs closely to avoid surprises
5. **Dashboard Reviews**: Review dashboards weekly with the team
6. **Incident Response**: Have a runbook for common issues
7. **Continuous Improvement**: Update evaluators and golden datasets regularly

## Resources

- [LangSmith Documentation](https://docs.smith.langchain.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Marketing Agent Evaluation Framework](../src/evaluation/README.md)

## Support

For questions or issues:
- Create an issue in the repository
- Contact the AI/ML team
- Review existing documentation in `/docs`
