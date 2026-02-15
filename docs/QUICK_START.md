# Quick Start Guide - Marketing Agent

Get your first Marketing Agent recommendation running in 30 minutes.

## 🎯 Goal

By the end of this guide, you'll have:
1. Development environment set up
2. A simple agent generating recommendations
3. Basic evaluation running
4. Understanding of next steps

## ⚡ Prerequisites Check

```bash
# Check Python version (need 3.11+)
python --version

# Check Docker
docker --version

# Check if you have API keys
echo $OPENAI_API_KEY  # or ANTHROPIC_API_KEY
```

If any are missing, install them first.

## 📦 Step 1: Project Setup (5 min)

```bash
# Create project directory
mkdir marketing-agent
cd marketing-agent

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Create basic structure
mkdir -p src/{agent,data_collectors,api,evaluation}
mkdir -p tests/{unit,integration}
mkdir -p prompts/signal_analysis
mkdir -p test_data
```

## 🔧 Step 2: Install Dependencies (3 min)

Create `requirements.txt`:
```txt
# Core
fastapi==0.115.0
uvicorn[standard]==0.32.0
pydantic==2.9.0
pydantic-settings==2.6.0

# Agent framework
langchain>=0.3.0
langchain-openai>=0.2.0
langgraph>=0.2.0
langsmith>=0.2.0

# Database
sqlmodel>=0.0.22
asyncpg>=0.30.0
redis>=5.2.0

# HTTP & utilities
httpx>=0.27.0
tenacity>=9.0.0
python-dotenv>=1.0.0
structlog>=24.4.0

# Development
pytest>=8.3.0
pytest-asyncio>=0.24.0
ruff>=0.8.0
```

Install:
```bash
pip install -r requirements.txt
```

## 🔑 Step 3: Environment Variables (2 min)

Create `.env`:
```bash
# LLM Provider
OPENAI_API_KEY=your_key_here
# or
ANTHROPIC_API_KEY=your_key_here

# LangSmith (optional but recommended)
LANGCHAIN_TRACING_V2=true
LANGCHAIN_API_KEY=your_langsmith_key
LANGCHAIN_PROJECT=marketing-agent-dev

# Database (for later)
DATABASE_URL=postgresql://user:pass@localhost:5432/marketing_agent
REDIS_URL=redis://localhost:6379/0
```

## 🎨 Step 4: Create Simple Agent (10 min)

### 4.1 Define Data Models

`src/agent/models.py`:
```python
from pydantic import BaseModel, Field
from enum import Enum
from datetime import datetime

class WorkflowType(str, Enum):
    CREATIVE_REFRESH = "Creative Refresh"
    AUDIENCE_EXPANSION = "Audience Expansion"
    BID_ADJUSTMENT = "Bid Adjustment"
    CONTINUE_MONITORING = "Continue Monitoring"

class CampaignMetrics(BaseModel):
    campaign_id: str
    campaign_name: str
    cpa: float
    cpa_change_pct: float
    ctr: float
    impression_share: float

class Recommendation(BaseModel):
    campaign_id: str
    recommended_workflow: WorkflowType
    reasoning: str
    confidence: float = Field(ge=0.0, le=1.0)
    expected_impact: str
    generated_at: datetime = Field(default_factory=datetime.utcnow)
```

### 4.2 Create Basic Prompt

`prompts/signal_analysis/v1.yaml`:
```yaml
version: "1.0"
description: "Simple signal analysis prompt"

prompt: |
  You are a marketing performance analyst. Analyze the campaign data and recommend an action.
  
  Available actions:
  - Creative Refresh: When ads are stale (CTR declining, high frequency)
  - Audience Expansion: When audience is saturated
  - Bid Adjustment: When competitive pressure increased
  - Continue Monitoring: When no action needed
  
  Campaign Data:
  - CPA: ${cpa} (changed ${cpa_change_pct}%)
  - CTR: ${ctr}
  - Impression Share: ${impression_share}%
  
  Provide recommendation in JSON format:
  {
    "recommended_workflow": "Bid Adjustment",
    "reasoning": "Detailed explanation",
    "confidence": 0.85,
    "expected_impact": "What will happen"
  }
```

### 4.3 Simple Agent Implementation

`src/agent/simple_agent.py`:
```python
from langchain_openai import ChatOpenAI
from langchain.prompts import ChatPromptTemplate
from langchain.output_parsers import PydanticOutputParser
from .models import Recommendation, CampaignMetrics
import os

class SimpleMarketingAgent:
    def __init__(self):
        self.llm = ChatOpenAI(
            model="gpt-4o-mini",  # Use mini for dev (cheaper)
            temperature=0.1
        )
    
    async def analyze(self, metrics: CampaignMetrics) -> Recommendation:
        """Generate recommendation for campaign"""
        
        # Load prompt
        prompt_template = ChatPromptTemplate.from_template(
            """You are a marketing analyst. Analyze this campaign and recommend an action.
            
Campaign: {campaign_name}
CPA: ${cpa} (changed {cpa_change_pct}%)
CTR: {ctr}%
Impression Share: {impression_share}%

Available actions:
- Creative Refresh: When ads are stale
- Bid Adjustment: When competitive pressure increased  
- Continue Monitoring: When no action needed

Respond with JSON:
{{
  "recommended_workflow": "Bid Adjustment",
  "reasoning": "Detailed explanation",
  "confidence": 0.85,
  "expected_impact": "CPA will decrease"
}}"""
        )
        
        # Format input
        messages = prompt_template.format_messages(
            campaign_name=metrics.campaign_name,
            cpa=metrics.cpa,
            cpa_change_pct=metrics.cpa_change_pct,
            ctr=metrics.ctr,
            impression_share=metrics.impression_share
        )
        
        # Get LLM response
        response = await self.llm.ainvoke(messages)
        
        # Parse JSON
        import json
        result = json.loads(response.content)
        
        # Create recommendation
        return Recommendation(
            campaign_id=metrics.campaign_id,
            recommended_workflow=result["recommended_workflow"],
            reasoning=result["reasoning"],
            confidence=result["confidence"],
            expected_impact=result["expected_impact"]
        )

# CLI usage
if __name__ == "__main__":
    import asyncio
    
    async def main():
        # Example campaign data
        metrics = CampaignMetrics(
            campaign_id="camp_001",
            campaign_name="Spring Sale 2026",
            cpa=58.50,
            cpa_change_pct=30.0,
            ctr=2.8,
            impression_share=95.0
        )
        
        agent = SimpleMarketingAgent()
        recommendation = await agent.analyze(metrics)
        
        print("\n" + "="*60)
        print(f"Campaign: {metrics.campaign_name}")
        print("="*60)
        print(f"Recommended Action: {recommendation.recommended_workflow}")
        print(f"Confidence: {recommendation.confidence * 100:.0f}%")
        print(f"\nReasoning:\n{recommendation.reasoning}")
        print(f"\nExpected Impact:\n{recommendation.expected_impact}")
        print("="*60 + "\n")
    
    asyncio.run(main())
```

## 🚀 Step 5: Test It! (2 min)

```bash
# Run the agent
python -m src.agent.simple_agent
```

You should see output like:
```
============================================================
Campaign: Spring Sale 2026
============================================================
Recommended Action: Bid Adjustment
Confidence: 82%

Reasoning:
CPA increased 30% which is significant. However, CTR is stable at 2.8%
and impression share is high at 95%, indicating creative isn't fatigued
and audience is saturated. This suggests competitive pressure. 
Recommend bid adjustment to maintain auction competitiveness.

Expected Impact:
CPA should stabilize or decrease within 2-3 days as bid increase 
restores impression share in competitive auctions.
============================================================
```

## ✅ Step 6: Create First Test (5 min)

`tests/unit/test_simple_agent.py`:
```python
import pytest
from src.agent.simple_agent import SimpleMarketingAgent
from src.agent.models import CampaignMetrics

@pytest.mark.asyncio
async def test_agent_generates_recommendation():
    """Test that agent produces valid recommendation"""
    
    metrics = CampaignMetrics(
        campaign_id="test_001",
        campaign_name="Test Campaign",
        cpa=60.0,
        cpa_change_pct=25.0,
        ctr=2.5,
        impression_share=90.0
    )
    
    agent = SimpleMarketingAgent()
    recommendation = await agent.analyze(metrics)
    
    # Assertions
    assert recommendation.campaign_id == "test_001"
    assert recommendation.recommended_workflow is not None
    assert 0.0 <= recommendation.confidence <= 1.0
    assert len(recommendation.reasoning) > 50  # Has explanation
    
    print(f"✓ Generated: {recommendation.recommended_workflow}")
    print(f"✓ Confidence: {recommendation.confidence}")

@pytest.mark.asyncio
async def test_high_confidence_for_clear_signal():
    """Test agent is confident when signal is clear"""
    
    # Very clear competitive pressure signal
    metrics = CampaignMetrics(
        campaign_id="test_002",
        campaign_name="Clear Signal Test",
        cpa=70.0,
        cpa_change_pct=50.0,  # Large CPA increase
        ctr=3.0,              # Good CTR (creative fine)
        impression_share=95.0 # High IS (audience not saturated)
    )
    
    agent = SimpleMarketingAgent()
    recommendation = await agent.analyze(metrics)
    
    # Should be confident
    assert recommendation.confidence > 0.7
    print(f"✓ Confidence for clear signal: {recommendation.confidence}")
```

Run tests:
```bash
pytest tests/unit/test_simple_agent.py -v
```

## 📊 Step 7: Basic Evaluation (3 min)

Create test dataset `test_data/golden_cases.json`:
```json
[
  {
    "campaign_id": "golden_001",
    "campaign_name": "Competitive Pressure Case",
    "metrics": {
      "cpa": 58.50,
      "cpa_change_pct": 30.0,
      "ctr": 2.8,
      "impression_share": 95.0
    },
    "expected_workflow": "Bid Adjustment",
    "human_reasoning": "CPA increase with stable creative performance indicates competitive pressure"
  },
  {
    "campaign_id": "golden_002",
    "campaign_name": "Creative Fatigue Case",
    "metrics": {
      "cpa": 55.0,
      "cpa_change_pct": 20.0,
      "ctr": 1.5,
      "impression_share": 70.0
    },
    "expected_workflow": "Creative Refresh",
    "human_reasoning": "CTR declining significantly - creative fatigue"
  }
]
```

Simple evaluation script `src/evaluation/simple_eval.py`:
```python
import json
import asyncio
from src.agent.simple_agent import SimpleMarketingAgent
from src.agent.models import CampaignMetrics

async def run_evaluation():
    """Run agent on golden dataset and check agreement"""
    
    # Load test cases
    with open('test_data/golden_cases.json') as f:
        test_cases = json.load(f)
    
    agent = SimpleMarketingAgent()
    
    results = []
    for case in test_cases:
        metrics = CampaignMetrics(
            campaign_id=case["campaign_id"],
            campaign_name=case["campaign_name"],
            **case["metrics"]
        )
        
        recommendation = await agent.analyze(metrics)
        
        matches = recommendation.recommended_workflow == case["expected_workflow"]
        
        results.append({
            "campaign": case["campaign_name"],
            "expected": case["expected_workflow"],
            "got": recommendation.recommended_workflow,
            "match": matches,
            "confidence": recommendation.confidence
        })
        
        status = "✓" if matches else "✗"
        print(f"{status} {case['campaign_name']}: {recommendation.recommended_workflow}")
    
    # Calculate metrics
    agreement_rate = sum(r["match"] for r in results) / len(results) * 100
    avg_confidence = sum(r["confidence"] for r in results) / len(results)
    
    print(f"\n{'='*60}")
    print(f"Agreement Rate: {agreement_rate:.0f}%")
    print(f"Average Confidence: {avg_confidence:.2f}")
    print(f"{'='*60}\n")
    
    return results

if __name__ == "__main__":
    asyncio.run(run_evaluation())
```

Run evaluation:
```bash
python -m src.evaluation.simple_eval
```

## 🎉 Success!

You now have:
- ✅ Working agent that generates recommendations
- ✅ Unit tests passing
- ✅ Basic evaluation running
- ✅ Foundation for production system

## 🚀 Next Steps

### Immediate (This Week)
1. **Add more golden test cases** (target: 20+)
2. **Improve prompt** based on test failures
3. **Add data collectors** for real campaign data
4. **Set up Docker Compose** for PostgreSQL + Redis

### Short Term (Next 2 Weeks)
1. **Build LangGraph workflow** (replace simple agent)
2. **Add context collection** from multiple sources
3. **Implement structured output parsing**
4. **Set up LangSmith tracing**

### Medium Term (Month 2-3)
1. **Build FastAPI endpoints**
2. **Create simple UI** for reviewing recommendations
3. **Add monitoring dashboards**
4. **Deploy to staging environment**

## 📚 Resources

- **Full Implementation Guide**: [MARKETING_AGENT_IMPLEMENTATION_GUIDE.md](./MARKETING_AGENT_IMPLEMENTATION_GUIDE.md)
- **LangChain Docs**: https://python.langchain.com/docs/get_started/introduction
- **LangGraph Tutorial**: https://docs.langchain.com/oss/python/langgraph/quickstart
- **Anthropic Agent Guide**: https://www.anthropic.com/research/building-effective-agents

## 🐛 Troubleshooting

**"OpenAI API key not found"?**
```bash
# Make sure .env file is loaded
export $(cat .env | xargs)
```

**"Module not found" errors?**
```bash
# Ensure virtual environment is activated
source venv/bin/activate  # or venv\Scripts\activate on Windows

# Reinstall dependencies
pip install -r requirements.txt
```

**Agent produces poor reasoning?**
- Try GPT-4o instead of gpt-4o-mini (better reasoning)
- Add few-shot examples to prompt
- Increase temperature slightly (0.1 → 0.2)

## 💬 Questions?

- Check the [full guide](./MARKETING_AGENT_IMPLEMENTATION_GUIDE.md)
- Review [Anthropic's agent patterns](https://www.anthropic.com/research/building-effective-agents)
- Ask in #marketing-agent Slack channel

---

**Time to complete**: ~30 minutes  
**Next milestone**: Add real data collection (Week 3-4)

Happy building! 🚀
