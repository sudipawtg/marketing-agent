"""Recommendations API router"""

from fastapi import APIRouter, HTTPException, status, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from datetime import datetime
from typing import Optional
import structlog
import uuid

from src.database import Recommendation, Campaign, DecisionStatus
from src.database.connection import AsyncSessionLocal
from src.agent import MarketingAgent
from ..schemas import (
    AnalyzeRequest,
    AnalyzeResponse,
    DecisionRequest,
    RecommendationDetailResponse,
    RecommendationListItem,
    ListRecommendationsResponse,
    RecommendationResponse,
    AlternativeActionResponse,
    WorkflowTypeSchema,
    RiskLevelSchema,
    DecisionStatusSchema
)

logger = structlog.get_logger()
router = APIRouter(prefix="/recommendations")

# Initialize agent (singleton for POC)
agent = MarketingAgent()


async def get_db_session():
    """Database session dependency"""
    async with AsyncSessionLocal() as session:
        yield session


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze_campaign(
    request: AnalyzeRequest,
    db: AsyncSession = Depends(get_db_session)
):
    """
    Analyze a campaign and generate recommendation
    
    This endpoint triggers the agent workflow to:
    1. Collect campaign context (metrics, creative, competitor data)
    2. Analyze signals to identify root causes
    3. Generate actionable recommendation
    4. Store results in database
    """
    logger.info("Analyzing campaign", campaign_id=request.campaign_id)
    
    try:
        # Run agent analysis
        start_time = datetime.now()
        result = await agent.analyze_campaign(request.campaign_id)
        generation_time_ms = int((datetime.now() - start_time).total_seconds() * 1000)
        
        if result.get("errors"):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Analysis failed: {', '.join(result['errors'])}"
            )
        
        # Get or create campaign
        campaign = await _get_or_create_campaign(db, request.campaign_id, result["context"])
        
        # Store recommendation
        rec_id = str(uuid.uuid4())
        recommendation_data = result["recommendation"]
        
        db_recommendation = Recommendation(
            id=rec_id,
            campaign_id=campaign.id,
            recommended_workflow=recommendation_data.recommended_workflow.value,
            reasoning=recommendation_data.reasoning,
            expected_impact=recommendation_data.expected_impact,
            risk_level=recommendation_data.risk_level.value,
            confidence=recommendation_data.confidence,
            signal_analysis=result["signal_analysis_text"] if result.get("signal_analysis_text") else recommendation_data.signal_analysis,
            root_cause=result["signal_analysis"].root_cause if result.get("signal_analysis") else None,
            context=result["context"].model_dump(mode='json') if result.get("context") else {},
            alternatives=[alt.model_dump(mode='json') for alt in recommendation_data.alternatives],
            human_decision=DecisionStatus.PENDING,
            model_version=recommendation_data.model_version,
            generation_time_ms=generation_time_ms,
            token_usage=result.get("metadata", {}).get("token_usage"),
            cost_usd=result.get("metadata", {}).get("cost_usd")
        )
        
        db.add(db_recommendation)
        await db.commit()
        await db.refresh(db_recommendation)
        
        logger.info("Analysis complete", recommendation_id=str(rec_id), time_ms=generation_time_ms)
        
        # Build response
        return AnalyzeResponse(
            recommendation_id=str(rec_id),
            campaign_id=request.campaign_id,
            recommendation=_build_recommendation_response(recommendation_data),
            context=result.get("context").model_dump(mode='json') if result.get("context") else None,
            signal_analysis=result.get("signal_analysis_text"),
            status="completed",
            generated_at=datetime.now(),
            generation_time_ms=generation_time_ms
        )
        
    except Exception as e:
        logger.error("Analysis failed", error=str(e), campaign_id=request.campaign_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/{recommendation_id}", response_model=RecommendationDetailResponse)
async def get_recommendation(
    recommendation_id: str,
    db: AsyncSession = Depends(get_db_session)
):
    """Get detailed recommendation by ID"""
    # Validate UUID format but query with string (SQLite stores as string)
    try:
        uuid.UUID(recommendation_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid recommendation ID format"
        )
    
    result = await db.execute(
        select(Recommendation).where(Recommendation.id == recommendation_id)
    )
    recommendation = result.scalar_one_or_none()
    
    if not recommendation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Recommendation not found"
        )
    
    return _build_detail_response(recommendation)


@router.post("/{recommendation_id}/decision")
async def record_decision(
    recommendation_id: str,
    decision: DecisionRequest,
    db: AsyncSession = Depends(get_db_session)
):
    """Record human decision on a recommendation"""
    # Validate UUID format but query with string (SQLite stores as string)
    try:
        uuid.UUID(recommendation_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid recommendation ID format"
        )
    
    result = await db.execute(
        select(Recommendation).where(Recommendation.id == recommendation_id)
    )
    recommendation = result.scalar_one_or_none()
    
    if not recommendation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Recommendation not found"
        )
    
    # Update decision - convert from string enum to database enum
    recommendation.human_decision = DecisionStatus(decision.decision.value)
    recommendation.decision_feedback = decision.feedback
    recommendation.decided_at = datetime.now()
    recommendation.decided_by = decision.decided_by
    
    await db.commit()
    
    logger.info(
        "Decision recorded",
        recommendation_id=recommendation_id,
        decision=decision.decision.value
    )
    
    return {
        "status": "recorded",
        "recommendation_id": recommendation_id,
        "decision": decision.decision.value,
        "timestamp": datetime.now().isoformat()
    }


@router.get("/", response_model=ListRecommendationsResponse)
async def list_recommendations(
    status_filter: Optional[str] = None,
    campaign_id: Optional[str] = None,
    page: int = 1,
    page_size: int = 20,
    db: AsyncSession = Depends(get_db_session)
):
    """List recommendations with optional filtering"""
    query = select(Recommendation).order_by(desc(Recommendation.created_at))
    
    # Apply filters
    if status_filter:
        try:
            status_enum = DecisionStatus[status_filter.upper()]
            query = query.where(Recommendation.human_decision == status_enum)
        except KeyError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid status: {status_filter}"
            )
    
    if campaign_id:
        # Find campaign first
        campaign_result = await db.execute(
            select(Campaign).where(Campaign.external_id == campaign_id)
        )
        campaign = campaign_result.scalar_one_or_none()
        if campaign:
            query = query.where(Recommendation.campaign_id == campaign.id)
    
    # Count total
    count_result = await db.execute(query)
    total = len(count_result.all())
    
    # Paginate
    offset = (page - 1) * page_size
    query = query.offset(offset).limit(page_size)
    
    result = await db.execute(query)
    recommendations = result.scalars().all()
    
    return ListRecommendationsResponse(
        recommendations=[_build_list_item(rec) for rec in recommendations],
        total=total,
        page=page,
        page_size=page_size
    )


# Helper functions
async def _get_or_create_campaign(db: AsyncSession, campaign_id: str, context):
    """Get or create campaign record"""
    result = await db.execute(
        select(Campaign).where(Campaign.external_id == campaign_id)
    )
    campaign = result.scalar_one_or_none()
    
    if not campaign:
        campaign = Campaign(
            external_id=campaign_id,
            name=context.campaign_metrics.campaign_name if context else campaign_id,
            platform=context.campaign_metrics.platform if context else "unknown",
            status="active"
        )
        db.add(campaign)
        await db.commit()
        await db.refresh(campaign)
    
    return campaign


def _build_recommendation_response(rec) -> RecommendationResponse:
    """Build recommendation response"""
    return RecommendationResponse(
        recommended_workflow=WorkflowTypeSchema(rec.recommended_workflow),
        reasoning=rec.reasoning,
        specific_actions=rec.specific_actions,
        expected_impact=rec.expected_impact,
        risk_level=RiskLevelSchema(rec.risk_level),
        confidence=rec.confidence,
        timeline=rec.timeline,
        success_criteria=rec.success_criteria,
        alternatives=[
            AlternativeActionResponse(**alt) for alt in rec.alternatives
        ] if rec.alternatives else []
    )


def _build_detail_response(db_rec: Recommendation) -> RecommendationDetailResponse:
    """Build detailed response"""
    return RecommendationDetailResponse(
        id=str(db_rec.id),
        campaign_id=str(db_rec.campaign_id),
        recommendation=RecommendationResponse(
            recommended_workflow=WorkflowTypeSchema(db_rec.recommended_workflow),
            reasoning=db_rec.reasoning,
            specific_actions="Not specified",  # Parse from reasoning
            expected_impact=db_rec.expected_impact or "Not specified",
            risk_level=RiskLevelSchema(db_rec.risk_level),
            confidence=db_rec.confidence,
            timeline="Not specified",
            success_criteria="Not specified",
            alternatives=[]
        ),
        signal_analysis=db_rec.signal_analysis,
        human_decision=DecisionStatusSchema(db_rec.human_decision.value),
        decision_feedback=db_rec.decision_feedback,
        decided_at=db_rec.decided_at,
        decided_by=db_rec.decided_by,
        created_at=db_rec.created_at
    )


def _build_list_item(db_rec: Recommendation) -> RecommendationListItem:
    """Build list item"""
    return RecommendationListItem(
        id=str(db_rec.id),
        campaign_id=str(db_rec.campaign_id),
        recommended_workflow=WorkflowTypeSchema(db_rec.recommended_workflow),
        risk_level=RiskLevelSchema(db_rec.risk_level),
        confidence=db_rec.confidence,
        human_decision=DecisionStatusSchema(db_rec.human_decision.value),
        created_at=db_rec.created_at
    )
