# Datadog Integration Guide

## Overview

This guide covers the complete Datadog integration for the Marketing Agent platform, including APM, logs, metrics, traces, and custom dashboards.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [APM (Application Performance Monitoring)](#apm)
5. [Log Collection](#log-collection)
6. [Custom Metrics](#custom-metrics)
7. [Dashboards & Alerts](#dashboards--alerts)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- Kubernetes cluster running
- Datadog account and API key
- Helm 3.x installed
- kubectl configured

```bash
# Verify cluster access
kubectl cluster-info

# Add Datadog Helm repository
helm repo add datadog https://helm.datadoghq.com
helm repo update
```

---

## Installation

### Option 1: Terraform (Recommended)

Enable Datadog in your Terraform configuration:

```hcl
# infrastructure/terraform/terraform.tfvars
enable_datadog = true
datadog_api_key = "your-datadog-api-key-here"
```

Apply the configuration:

```bash
cd infrastructure/terraform
terraform apply
```

### Option 2: Helm Direct Install

```bash
# Create namespace
kubectl create namespace monitoring

# Create secret for API key
kubectl create secret generic datadog-secret \
  --from-literal api-key=YOUR_DATADOG_API_KEY \
  --namespace monitoring

# Install Datadog agent
helm install datadog datadog/datadog \
  --namespace monitoring \
  --values infrastructure/datadog/values.yaml
```

### Datadog Helm Values

Create `infrastructure/datadog/values.yaml`:

```yaml
datadog:
  apiKey: YOUR_API_KEY
  site: datadoghq.com
  
  # APM Configuration
  apm:
    enabled: true
    portEnabled: true
    socketEnabled: true
    socketPath: /var/run/datadog/apm.socket
  
  # Process Monitoring
  processAgent:
    enabled: true
    processCollection: true
  
  # Log Collection
  logs:
    enabled: true
    containerCollectAll: true
    containerCollectUsingFiles: true
  
  # Kubernetes Events
  collectEvents: true
  
  # DogStatsD
  dogstatsd:
    port: 8125
    nonLocalTraffic: true
    useHostPort: true
  
  # Tags
  tags:
    - "env:production"
    - "service:marketing-agent"
    - "team:ai-engineering"
    - "version:1.0.0"

# Cluster Agent
clusterAgent:
  enabled: true
  replicas: 2
  
  # Metrics Provider (for HPA)
  metricsProvider:
    enabled: true
    useDatadogMetrics: true
  
  # Admission Controller (for auto-instrumentation)
  admissionController:
    enabled: true
    mutateUnlabelled: false

# Node Agents
agents:
  image:
    tag: "7"
  
  # Resource limits
  containers:
    agent:
      resources:
        requests:
          cpu: 200m
          memory: 256Mi
        limits:
          cpu: 500m
          memory: 512Mi
    
    processAgent:
      resources:
        requests:
          cpu: 100m
          memory: 200Mi
        limits:
          cpu: 200m
          memory: 256Mi
    
    traceAgent:
      resources:
        requests:
          cpu: 100m
          memory: 200Mi
        limits:
          cpu: 200m
          memory: 256Mi
  
  # Pod annotations for libraries injection
  podAnnotations:
    ad.datadoghq.com/agent.logs: '[{"source": "datadog-agent", "service": "agent"}]'
```

---

## APM (Application Performance Monitoring)

### Python Backend Instrumentation

#### 1. Install Datadog Tracing Library

Add to `pyproject.toml`:

```toml
dependencies = [
    "ddtrace>=2.0.0",
]
```

Install:

```bash
pip install ddtrace
```

#### 2. Instrument FastAPI Application

Update `src/api/main.py`:

```python
from fastapi import FastAPI
from ddtrace import tracer, patch_all
from ddtrace.contrib.fastapi import get_middleware

# Auto-instrument all supported libraries
patch_all()

app = FastAPI(title="Marketing Agent API")

# Add Datadog middleware
app.add_middleware(
    get_middleware(
        service="marketing-agent-api",
        distributed_tracing=True
    )
)

# Configure tracer
tracer.configure(
    hostname="localhost",
    port=8126,
    enabled=True,
)
```

#### 3. Custom Spans for LLM Calls

Instrument `src/agent/workflow.py`:

```python
from ddtrace import tracer

@tracer.wrap(service="marketing-agent", resource="campaign_optimization")
async def run_campaign_optimization(input_data: dict) -> dict:
    """Run campaign optimization with Datadog tracing."""
    
    with tracer.trace("collect_campaign_data") as span:
        span.set_tag("campaign_id", input_data.get("campaign_id"))
        campaign_data = await collect_campaign_data(input_data)
    
    with tracer.trace("llm_analysis") as span:
        span.set_tag("model", "gpt-4")
        span.set_tag("temperature", 0.7)
        
        # Track token usage
        response = await llm.ainvoke(campaign_data)
        
        span.set_metric("tokens.prompt", response.usage.prompt_tokens)
        span.set_metric("tokens.completion", response.usage.completion_tokens)
        span.set_metric("tokens.total", response.usage.total_tokens)
        span.set_metric("cost.usd", calculate_cost(response.usage))
    
    return response
```

#### 4. Kubernetes Deployment Configuration

Update deployment to inject Datadog tracer:

```yaml
# infrastructure/k8s/base/backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: marketing-agent-backend
spec:
  template:
    metadata:
      annotations:
        # Enable Datadog APM
        ad.datadoghq.com/marketing-agent.check_names: '["python"]'
        ad.datadoghq.com/marketing-agent.init_configs: '[{}]'
        ad.datadoghq.com/marketing-agent.logs: '[{"source": "python", "service": "marketing-agent"}]'
    spec:
      containers:
      - name: marketing-agent
        image: marketing-agent-backend:latest
        env:
        - name: DD_AGENT_HOST
          valueFrom:
            fieldRef:
              fieldPath: status.hostIP
        - name: DD_TRACE_AGENT_PORT
          value: "8126"
        - name: DD_SERVICE
          value: "marketing-agent-api"
        - name: DD_ENV
          value: "production"
        - name: DD_VERSION
          value: "1.0.0"
        - name: DD_LOGS_INJECTION
          value: "true"
        - name: DD_TRACE_ANALYTICS_ENABLED
          value: "true"
        - name: DD_PROFILING_ENABLED
          value: "true"
```

---

## Log Collection

### Structured Logging

Update `src/config/settings.py`:

```python
import logging
import json
from ddtrace import tracer

class DatadogFormatter(logging.Formatter):
    """Custom formatter for Datadog logs."""
    
    def format(self, record):
        # Get current trace context
        span = tracer.current_span()
        trace_id = span.trace_id if span else 0
        span_id = span.span_id if span else 0
        
        log_record = {
            "timestamp": self.formatTime(record),
            "level": record.levelname,
            "message": record.getMessage(),
            "logger": record.name,
            "dd.trace_id": str(trace_id),
            "dd.span_id": str(span_id),
            "dd.service": "marketing-agent",
            "dd.env": settings.ENVIRONMENT,
        }
        
        # Add exception info if present
        if record.exc_info:
            log_record["error.kind"] = record.exc_info[0].__name__
            log_record["error.message"] = str(record.exc_info[1])
            log_record["error.stack"] = self.formatException(record.exc_info)
        
        return json.dumps(log_record)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    handlers=[logging.StreamHandler()]
)

# Set formatter
for handler in logging.root.handlers:
    handler.setFormatter(DatadogFormatter())
```

---

## Custom Metrics

### DogStatsD Integration

Create `src/monitoring/datadog_metrics.py`:

```python
from datadog import initialize, statsd
from functools import wraps
import time

# Initialize DogStatsD
initialize(
    statsd_host=os.getenv("DD_AGENT_HOST", "localhost"),
    statsd_port=int(os.getenv("DD_DOGSTATSD_PORT", 8125))
)

def track_execution_time(metric_name: str):
    """Decorator to track function execution time."""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            start = time.time()
            try:
                result = await func(*args, **kwargs)
                duration = time.time() - start
                
                statsd.histogram(
                    f"marketing_agent.{metric_name}.duration",
                    duration,
                    tags=[
                        f"function:{func.__name__}",
                        f"env:{settings.ENVIRONMENT}"
                    ]
                )
                
                statsd.increment(
                    f"marketing_agent.{metric_name}.success",
                    tags=[f"function:{func.__name__}"]
                )
                
                return result
            except Exception as e:
                statsd.increment(
                    f"marketing_agent.{metric_name}.error",
                    tags=[
                        f"function:{func.__name__}",
                        f"error_type:{type(e).__name__}"
                    ]
                )
                raise
        return wrapper
    return decorator

# Track LLM costs
def track_llm_cost(model: str, tokens: int, cost: float):
    """Track LLM usage and cost."""
    statsd.increment(
        "marketing_agent.llm.requests",
        tags=[f"model:{model}"]
    )
    
    statsd.histogram(
        "marketing_agent.llm.tokens",
        tokens,
        tags=[f"model:{model}"]
    )
    
    statsd.histogram(
        "marketing_agent.llm.cost",
        cost,
        tags=[f"model:{model}"]
    )

# Track evaluation scores
def track_evaluation_score(metric: str, score: float):
    """Track AI evaluation scores."""
    statsd.gauge(
        f"marketing_agent.evaluation.{metric}",
        score,
        tags=[f"env:{settings.ENVIRONMENT}"]
    )
```

Usage in application:

```python
from src.monitoring.datadog_metrics import track_execution_time, track_llm_cost

@track_execution_time("campaign_optimization")
async def optimize_campaign(data: dict) -> dict:
    response = await llm.ainvoke(data)
    
    # Track costs
    track_llm_cost(
        model="gpt-4",
        tokens=response.usage.total_tokens,
        cost=calculate_cost(response.usage)
    )
    
    return response
```

---

## Dashboards & Alerts

### Create Custom Dashboard

```python
# scripts/create_datadog_dashboard.py
from datadog_api_client import ApiClient, Configuration
from datadog_api_client.v1.api.dashboards_api import DashboardsApi
from datadog_api_client.v1.model.dashboard import Dashboard
from datadog_api_client.v1.model.widget import Widget

configuration = Configuration()
configuration.api_key["apiKeyAuth"] = os.getenv("DATADOG_API_KEY")
configuration.api_key["appKeyAuth"] = os.getenv("DATADOG_APP_KEY")

with ApiClient(configuration) as api_client:
    api_instance = DashboardsApi(api_client)
    
    dashboard = Dashboard(
        title="Marketing Agent - AI Operations",
        widgets=[
            # LLM Request Rate
            Widget(
                definition={
                    "type": "timeseries",
                    "requests": [{
                        "q": "sum:marketing_agent.llm.requests{*}.as_count()",
                        "display_type": "line"
                    }],
                    "title": "LLM Request Rate"
                }
            ),
            # Token Usage
            Widget(
                definition={
                    "type": "query_value",
                    "requests": [{
                        "q": "sum:marketing_agent.llm.tokens{*}",
                        "aggregator": "sum"
                    }],
                    "title": "Total Tokens Used"
                }
            ),
            # Cost Tracking
            Widget(
                definition={
                    "type": "timeseries",
                    "requests": [{
                        "q": "sum:marketing_agent.llm.cost{*}",
                        "display_type": "line"
                    }],
                    "title": "LLM Cost ($)"
                }
            ),
        ],
        layout_type="ordered"
    )
    
    response = api_instance.create_dashboard(dashboard)
    print(f"Dashboard created: {response.url}")
```

### Configure Alerts

```python
# scripts/create_datadog_monitors.py
from datadog_api_client.v1.api.monitors_api import MonitorsApi
from datadog_api_client.v1.model.monitor import Monitor

with ApiClient(configuration) as api_client:
    api_instance = MonitorsApi(api_client)
    
    # High error rate alert
    monitor = Monitor(
        name="High Error Rate - Marketing Agent",
        type="metric alert",
        query="avg(last_5m):sum:marketing_agent.requests.error{*}.as_rate() > 0.05",
        message="""
        Error rate is above 5% for Marketing Agent.
        
        @slack-alerts
        @pagerduty-critical
        """,
        tags=["service:marketing-agent", "team:ai-engineering"],
        priority=1
    )
    
    api_instance.create_monitor(monitor)
```

---

## Troubleshooting

### Verify Agent Installation

```bash
# Check agent status
kubectl exec -it $(kubectl get pods -n monitoring -l app=datadog -o name | head -1) -n monitoring -- agent status

# Check APM
kubectl exec -it $(kubectl get pods -n monitoring -l app=datadog -o name | head -1) -n monitoring -- agent status | grep -A 20 "APM Agent"

# Check logs
kubectl logs -n monitoring -l app=datadog --tail=100
```

### Common Issues

#### 1. No traces appearing

**Problem**: APM enabled but no traces in Datadog

**Solution**:
```bash
# Check environment variables
kubectl exec -it <backend-pod> -- env | grep DD_

# Verify agent connectivity
kubectl exec -it <backend-pod> -- curl http://$DD_AGENT_HOST:8126/info
```

#### 2. High memory usage

**Problem**: Datadog agent consuming too much memory

**Solution**:
```yaml
# Reduce collection intervals
agents:
  containers:
    agent:
      env:
        - name: DD_PROCESS_AGENT_COLLECTION_INTERVAL
          value: "60"  # seconds
```

#### 3. Missing logs

**Problem**: Application logs not appearing in Datadog

**Solution**:
```bash
# Verify log collection is enabled
kubectl get cm -n monitoring datadog -o yaml | grep logs.enabled

# Check log files
kubectl logs <backend-pod> | head -20
# Should see JSON formatted logs with dd.trace_id
```

---

## Best Practices

1. **Use consistent service naming** across all integrations
2. **Tag everything** - environment, version, team, etc.
3. **Set up SLOs** for critical metrics
4. **Create runbooks** linked to alerts
5. **Monitor costs** - set budget alerts
6. **Regular dashboard reviews** with team
7. **Test alerts** in staging first
8. **Document custom metrics** and their meaning

---

## Additional Resources

- [Datadog Python APM](https://docs.datadoghq.com/tracing/setup_overview/setup/python/)
- [Datadog Kubernetes Integration](https://docs.datadoghq.com/agent/kubernetes/)
- [DogStatsD](https://docs.datadoghq.com/developers/dogstatsd/)
- [Datadog API](https://docs.datadoghq.com/api/latest/)

---

**Next Steps**: [New Relic Integration](NEWRELIC_INTEGRATION.md) | [Sumologic Integration](SUMOLOGIC_INTEGRATION.md)
