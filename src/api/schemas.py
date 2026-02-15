"""Pydantic schemas for API requests and responses"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class WorkflowTypeSchema(str, Enum):
    """Available workflow types"""
    CREATIVE_REFRESH = "Creative Refresh"
    AUDIENCE_EXPANSION = "Audience Expansion"
    BID_ADJUSTMENT = "Bid Adjustment"
    CAMPAIGN_PAUSE = "Campaign Pause"
    BUDGET_REALLOCATION = "Budget Reallocation"
    CONTINUE_MONITORING = "Continue Monitoring"


class RiskLevelSchema(str, Enum):
    """Risk levels"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class DecisionStatusSchema(str, Enum):
    """Decision status"""
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


# Request schemas
class AnalyzeRequest(BaseModel):
    """Request to analyze a campaign"""
    campaign_id: str = Field(..., description="Campaign identifier")
    force_refresh: bool = Field(default=False, description="Skip cache and regenerate")


class DecisionRequest(BaseModel):
    """Record human decision on recommendation"""
    decision: DecisionStatusSchema
    feedback: Optional[str] = None
    decided_by: Optional[str] = None


# Response schemas
class AlternativeActionResponse(BaseModel):
    """Alternative action not chosen"""
    workflow: WorkflowTypeSchema
    why_not_recommended: str


class RecommendationResponse(BaseModel):
    """Recommendation details"""
    recommended_workflow: WorkflowTypeSchema
    reasoning: str
    specific_actions: str
    expected_impact: str
    risk_level: RiskLevelSchema
    confidence: float
    timeline: str
    success_criteria: str
    alternatives: List[AlternativeActionResponse] = []


class AnalyzeResponse(BaseModel):
    """Response from analyze endpoint"""
    recommendation_id: str
    campaign_id: str
    recommendation: RecommendationResponse
    context: Optional[dict] = None
    signal_analysis: Optional[str] = None
    status: str
    generated_at: datetime
    generation_time_ms: Optional[int] = None


class RecommendationDetailResponse(BaseModel):
    """Detailed recommendation with context"""
    id: str
    campaign_id: str
    recommendation: RecommendationResponse
    signal_analysis: Optional[str] = None
    human_decision: DecisionStatusSchema
    decision_feedback: Optional[str] = None
    decided_at: Optional[datetime] = None
    decided_by: Optional[str] = None
    created_at: datetime


class RecommendationListItem(BaseModel):
    """Summary for recommendation list"""
    id: str
    campaign_id: str
    recommended_workflow: WorkflowTypeSchema
    risk_level: RiskLevelSchema
    confidence: float
    human_decision: DecisionStatusSchema
    created_at: datetime


class ListRecommendationsResponse(BaseModel):
    """List of recommendations"""
    recommendations: List[RecommendationListItem]
    total: int
    page: int
    page_size: int


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    version: str
    timestamp: datetime


class ErrorResponse(BaseModel):
    """Error response"""
    error: str
    detail: Optional[str] = None
    timestamp: datetime
