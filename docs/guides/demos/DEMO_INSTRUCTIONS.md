# Demo Instructions - See Agent Logs in Real-Time

## Option 1: Two Terminal Setup (Recommended - Shows Logs)

This approach lets you see the backend logs while using the frontend.

### Terminal 1: Backend with Logs
```powershell
.\start_with_logs.ps1
```

You'll see:
- Backend startup logs
- **Live agent analysis logs** when you click "Analyze Campaign"
- LLM API calls and responses
- Signal analysis reasoning
- Recommendation generation process
- Database operations

### Terminal 2: Frontend
```powershell
.\start_frontend_only.ps1
```

Then open: http://localhost:3000

---

## Option 2: Automated Start (No Logs Visible)

If you don't need to see logs:

```powershell
.\start_demo.ps1
```

This starts everything automatically but backend runs in background (no logs shown).

---

## What You'll See in Backend Logs

When you click "Analyze Campaign" in the frontend, watch Terminal 1 for:

### 1. Request Received
```
INFO     | Starting agent analysis for campaign: demo-competitive-pressure
```

### 2. Context Collection
```
INFO     | Collecting context from 3 data sources...
INFO     | Campaign metrics collected: CPA=42.50, CTR=2.8%
INFO     | Creative metrics collected: age=18 days, fatigue=15%
INFO     | Competitor signals collected: 3 new competitors
INFO     | Context collection complete in 1.2s
```

### 3. LLM Signal Analysis
```
INFO     | Analyzing signals with LLM...
DEBUG    | LLM Request: 1847 tokens
DEBUG    | LLM Response: 523 tokens
INFO     | Signal analysis complete
         Root cause: External competitive pressure
         Confidence: 0.82
```

### 4. Recommendation Generation
```
INFO     | Generating recommendation...
INFO     | Recommended workflow: BID_ADJUSTMENT
         Confidence: 82%
         Risk: MEDIUM
```

### 5. Critique Loop
```
INFO     | Running critique on recommendation...
INFO     | Critique passed - reasoning is sound
```

### 6. Response Sent
```
INFO     | Recommendation saved to database
INFO     | Response sent to frontend (recommendation_id: abc-123-def)
```

---

## Viewing Docker Logs

To see PostgreSQL/Redis logs:

```powershell
# View all container logs
docker compose logs -f

# View specific service
docker compose logs -f postgres
docker compose logs -f redis
```

---

## Debugging Tips

### Check Backend Health
```powershell
curl http://localhost:8000/health
```

### View API Documentation
Open: http://localhost:8000/docs

### Test API Directly
```powershell
curl -X POST http://localhost:8000/api/recommendations/analyze `
  -H "Content-Type: application/json" `
  -d '{"campaign_id":"demo-competitive-pressure","scenario_name":"competitive_pressure"}'
```

### Check Database
```powershell
# Connect to PostgreSQL
docker compose exec postgres psql -U marketing_agent -d marketing_agent

# View recommendations
SELECT id, campaign_id, workflow_type, confidence_score, human_decision 
FROM recommendations 
ORDER BY created_at DESC 
LIMIT 5;
```

---

## Log Levels

To see more detailed logs, set environment variable before starting:

```powershell
# In .env file, add:
LOG_LEVEL=DEBUG

# Or set in terminal:
$env:LOG_LEVEL="DEBUG"
.\start_with_logs.ps1
```

Log levels:
- `DEBUG` - Everything (LLM requests/responses, SQL queries)
- `INFO` - Normal operation (agent steps, API calls)
- `WARNING` - Potential issues
- `ERROR` - Actual errors

---

## Common Log Messages

### Good Signs ✅
```
INFO     | Database initialized
INFO     | Agent workflow created successfully
INFO     | Recommendation generated: BID_ADJUSTMENT (confidence: 0.82)
INFO     | Decision recorded: APPROVED
```

### Warnings ⚠️
```
WARNING  | Using mock data - no real API connection
WARNING  | LLM response took longer than expected: 8.5s
WARNING  | Database connection retry attempt 2/3
```

### Errors ❌
```
ERROR    | Failed to call LLM API: Invalid API key
ERROR    | Database connection failed
ERROR    | Recommendation generation failed: timeout
```

---

## Performance Monitoring

Watch for these timing metrics in logs:

- **Context Collection**: Should be 1-3 seconds
- **LLM Analysis**: Typically 3-8 seconds
- **Total Request**: Usually 5-12 seconds

If analysis takes >15 seconds, check:
- LLM API rate limits
- Network connectivity
- Database response time

---

## Example Log Flow (Full Analysis)

Here's what a complete analysis looks like:

```
[2026-02-12 14:30:15] INFO  | POST /api/recommendations/analyze - Request received
[2026-02-12 14:30:15] INFO  | Campaign: demo-competitive-pressure, Scenario: competitive_pressure
[2026-02-12 14:30:15] INFO  | Initializing MarketingAgent workflow
[2026-02-12 14:30:15] INFO  | Node: collect_context - Starting
[2026-02-12 14:30:15] DEBUG | Parallel collection: campaign, creative, competitor
[2026-02-12 14:30:16] INFO  | Campaign metrics: {'cpa': 42.5, 'ctr': 2.8, 'impressions': 145000}
[2026-02-12 14:30:16] INFO  | Creative metrics: {'age_days': 18, 'fatigue_score': 15}
[2026-02-12 14:30:16] INFO  | Competitor signals: {'new_competitors': 3, 'cpc_change': 28}
[2026-02-12 14:30:16] INFO  | Node: analyze_signals - Starting
[2026-02-12 14:30:16] DEBUG | LLM provider: openai, model: gpt-4
[2026-02-12 14:30:16] DEBUG | Prompt tokens: 1847, Max tokens: 1500
[2026-02-12 14:30:19] DEBUG | LLM response received (3.2s): 523 tokens
[2026-02-12 14:30:19] INFO  | Signal analysis complete
[2026-02-12 14:30:19] INFO  | Root cause identified: External competitive pressure
[2026-02-12 14:30:19] INFO  | Primary signals: cpa_change=+32%, new_competitors=3
[2026-02-12 14:30:19] INFO  | Node: generate_recommendation - Starting
[2026-02-12 14:30:19] DEBUG | LLM provider: openai, model: gpt-4
[2026-02-12 14:30:22] DEBUG | LLM response received (2.8s): 412 tokens
[2026-02-12 14:30:22] INFO  | Recommendation: BID_ADJUSTMENT (confidence: 0.82, risk: MEDIUM)
[2026-02-12 14:30:22] INFO  | Node: critique - Starting
[2026-02-12 14:30:25] INFO  | Critique passed: Reasoning sound, no regeneration needed
[2026-02-12 14:30:25] INFO  | Node: finalize - Starting
[2026-02-12 14:30:25] INFO  | Saving recommendation to database
[2026-02-12 14:30:25] INFO  | Recommendation ID: 550e8400-e29b-41d4-a716-446655440000
[2026-02-12 14:30:25] INFO  | Agent workflow complete (10.2s total)
[2026-02-12 14:30:25] INFO  | POST /api/recommendations/analyze - 200 OK
```

---

## Viewing Human Decisions

After you approve/reject in the frontend, watch for:

```
[2026-02-12 14:32:10] INFO  | POST /api/recommendations/{id}/decision - Request received
[2026-02-12 14:32:10] INFO  | Recording decision: APPROVED
[2026-02-12 14:32:10] INFO  | Decided by: Demo User
[2026-02-12 14:32:10] INFO  | Feedback: "External pressure clearly identified from data"
[2026-02-12 14:32:10] INFO  | Decision saved to database
[2026-02-12 14:32:10] INFO  | POST /api/recommendations/{id}/decision - 200 OK
```

---

## Quick Start Summary

**Two Terminal Setup:**
```powershell
# Terminal 1 (Backend with logs):
.\start_with_logs.ps1

# Terminal 2 (Frontend):
.\start_frontend_only.ps1

# Browser:
http://localhost:3000
```

Now click "Analyze Campaign" and watch the logs in Terminal 1! 🎉
