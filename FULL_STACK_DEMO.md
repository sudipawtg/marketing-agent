# Full Stack Demo Walkthrough

This guide shows how to demo the complete Marketing Agent POC with backend reasoning and frontend human-in-the-loop interface.

## 🎯 Demo Scenario: "Competitive Pressure"

This walkthrough demonstrates:
1. AI analyzing complex campaign context
2. Identifying root causes (external vs internal)
3. Recommending specific workflow action
4. Human approval/rejection process

---

## Step 1: Start the Services

### Backend (FastAPI + Agent)
```bash
# Terminal 1
uvicorn src.api.main:app --reload
```

Backend starts at: http://localhost:8000
- API Documentation: http://localhost:8000/docs
- Health Check: http://localhost:8000/health

### Frontend (React)
```bash
# Terminal 2
cd frontend
npm install  # First time only
npm run dev
```

Frontend starts at: http://localhost:3000

---

## Step 2: Open the Frontend

Navigate to http://localhost:3000

**You'll see:**
- Header with "Marketing Agent POC" branding
- Info banner explaining the process
- 5 scenario cards with descriptions

---

## Step 3: Select "Competitive Pressure" Scenario

**Scenario Card Shows:**
- 🎯 Competitive Pressure
- "CPA increased 32% but creative performing well. Market competition intensified."
- Expected Outcome: "Agent should recommend BID_ADJUSTMENT, not creative changes"

**Click: "Analyze Campaign"**

---

## Step 4: Watch the Agent Work

**Backend Logs Show:**
```
[info] Starting agent analysis for campaign: demo-competitive-pressure
[info] Collecting context: campaign_metrics, creative_metrics, competitor_signals
[info] Context collected in 1.2s
[info] Analyzing signals with LLM...
[info] Signal analysis complete (confidence: 0.82)
[info] Generating recommendation...
[info] Recommendation generated: BID_ADJUSTMENT
[info] Running critique...
[info] Critique passed - recommendation approved
```

**Frontend Shows:**
- Loading spinner: "Analyzing..."
- Takes ~5-10 seconds (real LLM reasoning)

---

## Step 5: Review the AI Reasoning

### Header Section
**Displays:**
- 💰 Bid Adjustment (workflow icon + name)
- Campaign ID: demo-competitive-pressure
- **Confidence: 82%**
- **Risk Level: MEDIUM** (yellow badge)

### AI Reasoning Panel (Blue gradient box)
**Shows full explanation:**
```
CPA increased 32.5% over 7 days. Analysis shows:
- Creative CTR stable at 2.8% (no fatigue detected)
- 3 new competitors entered market
- Auction competition score: 87.5/100
- Competitor bids increased 28%

Root Cause: Increased competitive pressure in auction 
environment, not creative performance issues.

Recommended Action: Bid Adjustment (+15-20% to restore 
impression volume) rather than creative refresh.

This addresses the actual problem - we're losing auctions 
to higher bids - while preserving well-performing creative 
assets.
```

### Signal Analysis Section
**Root Cause (Yellow box):**
"External competitive pressure driving auction saturation"

**Primary Signals:**
- CPA Change: +32.5%
- New Competitors: 3
- Auction Score: 87.5/100
- CTR Stability: -2% (minimal)

**Secondary Signals:**
- Impression Share Lost: 14.2%
- Avg CPC Change: +28%

### Campaign Context (3 columns)
**Campaign Metrics:**
- Impressions: 145,000
- Clicks: 4,060
- CPA: $42.50
- CTR: 2.8%

**Creative Health:**
- Age: 18 days (fresh)
- Frequency: 3.2 (healthy)
- Fatigue Score: 15% (low)
- Last Refresh: 18 days ago

**Market Context:**
- New Competitors: 3
- Auction Overlap: +40%
- Impression Share Lost: 14.2%
- Avg CPC Change: +28%

### Alternative Actions Considered
**Shows agent also evaluated:**
1. Creative Refresh - 45% confidence
   "CTR still healthy, not primary issue"
2. Pause Campaign - 20% confidence
   "Performance not bad enough to pause"

---

## Step 6: Human-in-the-Loop Decision

### Review Section (Blue bordered box)
**Header:** "Human Review Required"

**Text:** 
"Review the AI's reasoning and decide whether to approve or reject this recommendation. Your decisions help the agent learn and improve over time."

**Two buttons:**
- ✅ Approve Recommendation (green)
- ❌ Reject Recommendation (red)

---

## Step 7: Make Decision

**Demo Path 1: Approval**

1. Click "Approve Recommendation"
2. Decision badge changes to "APPROVED" (green)
3. Optional feedback text area appears:
   - "Add any comments about your decision..."
   - Example: "Makes sense - auction pressure is clear from the data"
4. Click "Submit Decision"
5. Backend receives decision via POST /recommendations/{id}/decision
6. Decision recorded in database
7. Recommendation moves to history

**Demo Path 2: Rejection**

1. Click "Reject Recommendation"
2. Decision badge changes to "REJECTED" (red)
3. Feedback area appears
   - Example: "Want to wait another week to confirm trend"
4. Click "Submit Decision"
5. Decision recorded with feedback

---

## Step 8: View Decision History

Bottom section shows all analyzed campaigns:

**History Card Shows:**
- 💰 Bid Adjustment
- Campaign: demo-competitive-pressure
- APPROVED badge (green)
- Confidence: 82%
- Timestamp: Feb 11, 2026 2:15 PM
- Feedback: "Makes sense - auction pressure is clear..."

---

## Demo Flow: Complete Run-through

**Total time: 2-3 minutes per scenario**

1. **Select scenario** (5 seconds)
   - Explain what the scenario demonstrates
   
2. **Wait for analysis** (10 seconds)
   - Note: Real LLM reasoning happening

3. **Review reasoning** (60 seconds)
   - Walk through AI's logic
   - Show signal correlation
   - Highlight root cause identification

4. **Make decision** (30 seconds)
   - Approve or reject with reasoning
   - Submit with feedback

5. **Show history** (15 seconds)
   - Demonstrate tracking
   - Show decision accountability

---

## Key Talking Points During Demo

### During Analysis
- "The agent is collecting metrics from 3 sources in parallel"
- "Using LangGraph workflow with critique loop for quality"
- "Notice it takes real time - actual LLM reasoning, not templates"

### During Reasoning Review
- "See how it **correlates multiple signals**"
- "Identifies **root cause**, not just symptoms"
- "Distinguishes external (competition) vs internal (creative) factors"
- "Recommends **specific workflow action**, not generic advice"

### During Decision
- "Every recommendation requires **human approval**"
- "Feedback captures **why** you agree/disagree"
- "Builds training data for future improvements"
- "Gradual autonomy as patterns prove reliable"

### Showing History
- "Full **audit trail** of all recommendations"
- "Track approval rates by scenario type"
- "Measure **time saved** vs manual analysis"

---

## Running Multiple Scenarios

### Scenario Comparison Matrix

| Scenario | Root Cause | Recommendation | Key Learning |
|----------|-----------|----------------|--------------|
| Competitive Pressure | External | Bid Adjustment | Distinguishes market vs creative issues |
| Creative Fatigue | Internal | Creative Refresh | Detects when creative is the problem |
| Audience Saturation | Internal | Audience Expansion | Recognizes frequency vs competition |
| Winning Campaign | None | Continue Monitoring | Shows restraint - don't break what works |
| Multi-Signal | Both | Prioritized Action | Handles complex scenarios with multiple issues |

**Demo Strategy:**
1. **Start with Competitive Pressure** (clearest signal)
2. **Then Creative Fatigue** (opposite root cause)
3. **Then Winning Campaign** (shows agent won't over-react)

This demonstrates the agent can:
- ✅ Distinguish similar symptoms with different causes
- ✅ Recommend different actions for similar metrics
- ✅ Exercise restraint when appropriate

---

## Troubleshooting

### Backend not responding
```bash
# Check backend health
curl http://localhost:8000/health

# Expected: {"status": "healthy"}
```

### Frontend can't connect
- Verify backend is running: http://localhost:8000/docs
- Check browser console for CORS errors
- Verify Vite proxy config in frontend/vite.config.ts

### Analysis fails
- Check .env has OPENAI_API_KEY or ANTHROPIC_API_KEY
- Verify API key is valid
- Check backend logs for LLM errors

### Slow performance
- First request to LLM takes longer (cold start)
- Subsequent analyses are faster (warm model)
- Demo scenarios use cached mock data (2-5s)

---

## Customizing for Your Demo

### Change Scenario Details
Edit: `src/demo/scenarios.py`

### Adjust Frontend Colors
Edit: `frontend/tailwind.config.js`

### Add New Workflow Types
1. Update: `src/database/models.py` (WorkflowType enum)
2. Update: `frontend/src/components/RecommendationView.tsx` (WORKFLOW_LABELS)

### Modify Metrics Display
Edit: `frontend/src/components/RecommendationView.tsx`

---

## After Demo: Next Steps

1. **Show API Documentation**
   - http://localhost:8000/docs
   - "This is production-ready RESTful API"
   - "Can integrate with any frontend/workflow tool"

2. **Show Database Schema**
   - `src/database/models.py`
   - "Full audit trail, ready for analytics"

3. **Show LangGraph Workflow**
   - `src/agent/workflow.py`
   - "State machine with critique loop"
   - "Extensible for new reasoning patterns"

4. **Discuss Production Path**
   - Real API integrations (Google Ads, Meta)
   - Evaluation framework for quality measurement
   - Gradual rollout with A/B testing
   - Monitoring and alerting

---

## Success Metrics to Highlight

**Time Savings**
- Manual analysis: 15-30 minutes per campaign
- Agent analysis: 10 seconds
- **95% time reduction**

**Scalability**
- One agent handles unlimited campaigns
- Parallel processing
- No human bottleneck

**Quality**
- Multi-source context (3+ signals)
- Root cause identification
- Confidence scoring
- Self-critique for quality

**Safety**
- Human approval required
- Full audit trail
- Explainable reasoning
- Gradual autonomy

---

## Q&A Preparation

**Q: What if the agent is wrong?**
A: "That's why we have human approval. Every decision is reviewed. The feedback helps the agent learn."

**Q: How do you measure quality?**
A: "We track approval rates, decision feedback, and actual campaign outcomes. The evaluation framework measures against historical expert decisions."

**Q: When can it run autonomously?**
A: "Gradually. As patterns prove reliable (e.g., 95%+ approval for specific scenarios), we'll reduce oversight. But that's months away - we start with 100% human review."

**Q: What's the cost?**
A: "LLM API calls cost ~$0.10 per analysis. Compare that to 20 minutes of expert time. ROI is clear even at 100% supervision."

**Q: Can it handle our specific campaigns?**
A: "Yes. The demo uses mock data, but the architecture supports real integrations. We'd connect to your Google Ads/Meta APIs and train on your campaign patterns."
