# Marketing Agent - Demo Guide 🚀

## Quick Demo Options

### Option 1: 🎨 Visual Frontend Demo (Recommended for Stakeholders)

The best way to showcase the POC to non-technical audiences:

```bash
# One-command launch (starts backend + frontend)
.\start_demo.ps1

# OR start separately:
# Terminal 1:
uvicorn src.api.main:app --reload

# Terminal 2:
.\start_frontend.ps1
```

**Access the demo:**
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000/docs

**What you'll see:**
- Clean web interface with scenario cards
- Click "Analyze Campaign" to trigger agent reasoning
- See full AI analysis breakdown:
  - Root cause identification
  - Signal analysis (primary & secondary)
  - Campaign context metrics
  - Confidence scores & risk levels
- **Human-in-the-loop approval:** Approve/Reject buttons with feedback
- Decision history tracking

### Option 2: 📟 Terminal Demo (For Technical Audiences)

Quick terminal-based demo:

```bash
# Interactive demo with beautiful terminal UI
python -m src.demo.run_demo
```

This launches an interactive menu where you can:
- Select from 5 pre-built scenarios
- See the agent analyze each situation
- Watch it reason through the decision

## Demo Scenarios

### 1. 🎯 Competitive Pressure
**What happens:** CPA spikes 32.5% over a week
- Creative performance is stable (CTR only -2%)
- **BUT** 3 new competitors entered market
- Auction competition score: 87.5/100
- Competitor bids increased 28%

**Agent's reasoning:** "CPA increase is driven by external auction pressure, not internal issues. Creative CTR remains healthy at 2.8%, indicating ads still resonate. The auction environment has become significantly more competitive."

**Recommendation:** Bid Adjustment (+15-20% to restore competitiveness)
**NOT:** Creative Refresh (creatives are performing fine)

---

### 2. 🎨 Creative Fatigue
**What happens:** CTR drops 38.5%, performance declining
- Creatives are 42 days old
- Ad frequency at 7.8 (users seeing ads repeatedly)
- Engagement trend declining
- **BUT** competitors are stable (only +8% market activity)

**Agent's reasoning:** "Performance decline is internal. High frequency and old creatives indicate fatigue. Market conditions are stable, so the issue is our ads, not competition."

**Recommendation:** Creative Refresh
**NOT:** Bid Adjustment (won't help tired creative)

---

### 3. 👥 Audience Saturation
**What happens:** Frequency at 8.5, CTR declining
- Same users seeing ads too many times
- Audience near exhaustion
- Competitive pressure moderate

**Agent's reasoning:** "High frequency indicates we've saturated our current audience. Creative is fine, but we need fresh eyeballs."

**Recommendation:** Audience Expansion
**NOT:** Creative Refresh (not a creative problem)

---

### 4. 🏆 Winning Campaign
**What happens:** Everything is going great!
- CPA down 15.5%
- CTR up 12.3%
- CVR improving
- Low competitive pressure

**Agent's reasoning:** "Campaign is performing exceptionally. All metrics improving, creatives fresh, no external threats. No intervention needed."

**Recommendation:** Continue Monitoring
**Risk:** LOW - Don't break what's working

---

### 5. 🔀 Complex Multi-Signal Problem
**What happens:** BOTH creative fatigue AND competitive pressure
- Creatives 35 days old, frequency 6.2
- Competition score 75/100, +2 new entrants
- CPA up 35.5%, CTR down 22.8%

**Agent's reasoning:** "Multiple signals present. Agent must weigh which is the PRIMARY cause and prioritize accordingly."

**Recommendation:** [Agent must reason through which is more impactful]

---

## Command Line Options

```bash
# Run specific scenario
python -m src.demo.run_demo competitive_pressure

# Run all scenarios in sequence
python -m src.demo.run_demo --all

# List available scenarios
python -m src.demo.run_demo --list

# Interactive mode (default)
python -m src.demo.run_demo
```

## What Makes This Demo Impressive 🌟

### 1. **Context-Aware Reasoning**
The agent doesn't just look at one metric. It correlates:
- Campaign performance (CPA, CTR, spend)
- Creative health (age, frequency, engagement)
- Market dynamics (competitors, auction pressure)

### 2. **Causal Analysis**
It identifies ROOT CAUSE, not just symptoms:
- "CPA increased" ← Symptom
- "Because new competitors drove up auction costs" ← Root cause

### 3. **Specific, Actionable Recommendations**
Not vague like "optimize campaign" but specific:
- "Increase bids by 15-20%"
- "Refresh creative with new messaging"
- "Expand audience to include adjacent interests"

### 4. **Risk Assessment**
Evaluates what could go wrong:
- HIGH risk: Campaign Pause (lose momentum)
- MEDIUM risk: Bid Adjustment (potential overspend)
- LOW risk: Continue Monitoring (no changes)

### 5. **Confidence Scoring**
Honest about uncertainty:
- 85% confidence: Strong signal correlation
- 65% confidence: Mixed signals, less certain
- 50% confidence: Needs human judgment

## Demo Tips for Stakeholders 💡

### For Marketing Team:
**Show:** Competitive Pressure scenario first
- This is their pain point: "Why is CPA up?"
- Agent clearly separates internal vs external factors
- Specific recommendation they can act on immediately

### For Technical Leadership:
**Show:** All scenarios to demonstrate breadth
- Multi-signal reasoning capability
- Error handling and graceful degradation
- Production-ready architecture

### For Executive Team:
**Show:** The ROI story
- Time saved: Minutes vs hours of analysis
- Better decisions: Data-driven, not gut-feel
- Scalability: One agent, unlimited campaigns

## Sample Demo Script 📋

```
"Let me show you how the agent handles a common scenario..."

[Run competitive_pressure scenario]

"Notice how it identified THREE key facts:
1. CPA increased 32% ← The problem
2. Creative CTR stable ← Rules out ad fatigue  
3. Competition score 87/100 ← The real cause

It recommended Bid Adjustment, NOT Creative Refresh.
A human might waste time testing new creatives when the 
real issue is we're being outbid in auctions.

The agent saved us from a week of wrong optimizations."

[Show confidence score and risk assessment]

"It's also honest: 78% confidence with MEDIUM risk.
It's not pretending to be certain when it's not.

And here's the key: Marketing exec still approves.
The agent recommends, humans decide. As we build trust,
we can automate low-risk, high-confidence cases."
```

## Next: Live API Demo

After showing scenarios, demonstrate the API:

```bash
# Start API server
uvicorn src.api.main:app --reload

# Open http://localhost:8000/api/docs
# Show the Swagger UI - POST /analyze endpoint
```

This shows it's a real, production-ready system, not just a demo script.

## Troubleshooting Demo

**Agent takes too long?**
- Mock data loads instantly (< 1 second)
- LLM calls take 5-15 seconds (normal)
- Show progress spinner (already built in)

**Want different scenarios?**
- Edit `src/demo/scenarios.py`
- Add custom `CampaignMetrics`, `CreativeMetrics`, etc.
- Agent will reason over your data

**API Key issues?**
- Demo runs on MOCK DATA first (doesn't need API)
- For LLM reasoning, need OpenAI or Anthropic key in `.env`
- Can run without LLM to show data collection

---

## The Big Picture 🎯

This POC demonstrates:

✅ **The Problem:** Workflows can't reason about context
✅ **The Solution:** Agent that correlates signals and recommends actions
✅ **The Value:** Faster, better decisions at scale
✅ **The Safety:** Human approval, gradual autonomy
✅ **The Tech:** Production-ready, not a prototype

**Next Steps After Demo:**
1. Integrate real campaign APIs (Google Ads, Meta)
2. Build approval UI for marketing team
3. Establish evaluation framework
4. Deploy to staging → shadow mode → production
