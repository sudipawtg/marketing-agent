"""Streaming API endpoints for real-time reasoning display"""

from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime
import structlog
import json
import uuid
import asyncio

from src.database import Recommendation, Campaign, DecisionStatus
from src.database.connection import AsyncSessionLocal
from src.agent import MarketingAgent
from ..schemas import AnalyzeRequest

logger = structlog.get_logger()
router = APIRouter(prefix="/stream")

# Initialize agent (singleton for POC)
agent = MarketingAgent()


async def get_db_session():
    """Database session dependency"""
    async with AsyncSessionLocal() as session:
        yield session


async def analyze_campaign_stream(campaign_id: str, scenario_name: str = None):
    """Stream analysis progress with reasoning steps"""
    
    try:
        # Yield initial message
        yield json.dumps({
            "type": "init",
            "message": "Starting campaign analysis...",
            "timestamp": datetime.now().isoformat()
        }) + "\n"
        
        await asyncio.sleep(0.1)  # Small delay for UI
        
        # Step 1: Collect Context
        yield json.dumps({
            "type": "step",
            "step": "collect_context",
            "message": "📊 Collecting campaign data...",
            "detail": "Gathering campaign metrics, creative performance, and competitive signals",
            "timestamp": datetime.now().isoformat()
        }) + "\n"
        
        start_time = datetime.now()
        
        # Build context (this is synchronous in the agent, so we'll simulate the step)
        context_start = datetime.now()
        
        # Actually run the agent workflow
        result = await agent.analyze_campaign(campaign_id, scenario_name=scenario_name)
        
        if result.get("errors"):
            yield json.dumps({
                "type": "error",
                "message": f"Analysis failed: {', '.join(result['errors'])}",
                "timestamp": datetime.now().isoformat()
            }) + "\n"
            return
        
        context = result.get("context")
        signal_analysis = result.get("signal_analysis")
        signal_analysis_text = result.get("signal_analysis_text", "")
        recommendation_data = result["recommendation"]
        
        # Yield context collected
        if context:
            yield json.dumps({
                "type": "step_complete",
                "step": "collect_context",
                "message": "✅ Campaign data collected",
                "data": {
                    "impressions": context.campaign_metrics.impressions,
                    "clicks": context.campaign_metrics.clicks,
                    "cpa": context.campaign_metrics.cpa,
                    "ctr": context.campaign_metrics.ctr,
                    "creative_age": context.creative_metrics.avg_creative_age_days,
                    "fatigue_detected": context.creative_metrics.fatigue_detected,
                    "new_competitors": context.competitor_signals.new_entrants_last_week
                },
                "timestamp": datetime.now().isoformat()
            }) + "\n"
        
        await asyncio.sleep(0.2)
        
        # Step 2: Analyze Signals
        yield json.dumps({
            "type": "step",
            "step": "analyze_signals",
            "message": "🔍 Analyzing performance signals...",
            "detail": "Identifying patterns, anomalies, and root causes",
            "timestamp": datetime.now().isoformat()
        }) + "\n"
        
        await asyncio.sleep(0.3)
        
        # Stream the signal analysis reasoning
        if signal_analysis_text:
            # Split into chunks and stream
            lines = signal_analysis_text.split('\n')
            current_section = ""
            
            for line in lines:
                if line.startswith('###'):
                    # New section
                    if current_section:
                        yield json.dumps({
                            "type": "reasoning",
                            "step": "analyze_signals",
                            "content": current_section.strip(),
                            "timestamp": datetime.now().isoformat()
                        }) + "\n"
                        await asyncio.sleep(0.1)
                    current_section = line + "\n"
                else:
                    current_section += line + "\n"
            
            # Final section
            if current_section:
                yield json.dumps({
                    "type": "reasoning",
                    "step": "analyze_signals",
                    "content": current_section.strip(),
                    "timestamp": datetime.now().isoformat()
                }) + "\n"
        
        yield json.dumps({
            "type": "step_complete",
            "step": "analyze_signals",
            "message": "✅ Signal analysis complete",
            "data": {
                "root_cause": signal_analysis.root_cause if signal_analysis else "Analysis complete"
            },
            "timestamp": datetime.now().isoformat()
        }) + "\n"
        
        await asyncio.sleep(0.2)
        
        # Step 3: Generate Recommendation
        yield json.dumps({
            "type": "step",
            "step": "generate_recommendation",
            "message": "💡 Generating recommendation...",
            "detail": "Determining optimal workflow action based on analysis",
            "timestamp": datetime.now().isoformat()
        }) + "\n"
        
        await asyncio.sleep(0.3)
        
        # Stream reasoning
        reasoning_parts = recommendation_data.reasoning.split('\n\n')
        for part in reasoning_parts:
            if part.strip():
                yield json.dumps({
                    "type": "reasoning",
                    "step": "generate_recommendation",
                    "content": part.strip(),
                    "timestamp": datetime.now().isoformat()
                }) + "\n"
                await asyncio.sleep(0.15)
        
        yield json.dumps({
            "type": "step_complete",
            "step": "generate_recommendation",
            "message": f"✅ Recommendation: {recommendation_data.recommended_workflow.value}",
            "data": {
                "workflow": recommendation_data.recommended_workflow.value,
                "confidence": recommendation_data.confidence,
                "risk_level": recommendation_data.risk_level.value
            },
            "timestamp": datetime.now().isoformat()
        }) + "\n"
        
        await asyncio.sleep(0.2)
        
        # Step 4: Store in database
        yield json.dumps({
            "type": "step",
            "step": "store",
            "message": "💾 Recording recommendation...",
            "timestamp": datetime.now().isoformat()
        }) + "\n"
        
        # Store in database
        async with AsyncSessionLocal() as db:
            # Get or create campaign
            from src.api.routers.recommendations import _get_or_create_campaign
            campaign = await _get_or_create_campaign(db, campaign_id, context)
            
            rec_id = str(uuid.uuid4())
            
            db_recommendation = Recommendation(
                id=rec_id,
                campaign_id=campaign.id,
                recommended_workflow=recommendation_data.recommended_workflow.value,
                reasoning=recommendation_data.reasoning,
                expected_impact=recommendation_data.expected_impact,
                risk_level=recommendation_data.risk_level.value,
                confidence=recommendation_data.confidence,
                signal_analysis=signal_analysis_text,
                root_cause=signal_analysis.root_cause if signal_analysis else None,
                context=context.model_dump(mode='json') if context else {},
                alternatives=[alt.model_dump(mode='json') for alt in recommendation_data.alternatives],
                human_decision=DecisionStatus.PENDING,
                model_version=recommendation_data.model_version,
                generation_time_ms=int((datetime.now() - start_time).total_seconds() * 1000),
                token_usage=result.get("metadata", {}).get("token_usage"),
                cost_usd=result.get("metadata", {}).get("cost_usd")
            )
            
            db.add(db_recommendation)
            await db.commit()
            await db.refresh(db_recommendation)
        
        # Final result
        yield json.dumps({
            "type": "complete",
            "message": "✨ Analysis complete! Ready for your decision.",
            "recommendation_id": rec_id,
            "campaign_id": campaign_id,
            "recommendation": {
                "id": rec_id,
                "workflow_type": recommendation_data.recommended_workflow.value,
                "confidence": recommendation_data.confidence,
                "risk_level": recommendation_data.risk_level.value,
                "reasoning": recommendation_data.reasoning,
                "expected_impact": recommendation_data.expected_impact,
                "alternatives": [
                    {
                        "workflow_type": alt.workflow_type.value,
                        "confidence": alt.confidence,
                        "reason": alt.reason
                    } for alt in recommendation_data.alternatives
                ]
            },
            "context": context.model_dump(mode='json') if context else {},
            "signal_analysis": signal_analysis_text,
            "timestamp": datetime.now().isoformat()
        }) + "\n"
        
    except Exception as e:
        logger.error("Streaming analysis failed", error=str(e), campaign_id=campaign_id)
        yield json.dumps({
            "type": "error",
            "message": f"Analysis failed: {str(e)}",
            "timestamp": datetime.now().isoformat()
        }) + "\n"


@router.get("/analyze")
async def stream_analyze_campaign(
    campaign_id: str,
    scenario_name: str = None
):
    """
    Stream campaign analysis with real-time reasoning steps
    
    Returns Server-Sent Events (SSE) with:
    - Progress updates for each workflow step
    - Reasoning content as it's generated
    - Final recommendation with full context
    """
    return StreamingResponse(
        analyze_campaign_stream(campaign_id, scenario_name),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no"
        }
    )
