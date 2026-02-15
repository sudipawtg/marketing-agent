"""Structured output models for agent responses"""

from pydantic import BaseModel, Field
from typing import List, Optional
from enum import Enum


class WorkflowType(str, Enum):
    """Available workflow types"""
    CREATIVE_REFRESH = "Creative Refresh"
    AUDIENCE_EXPANSION = "Audience Expansion"
    BID_ADJUSTMENT = "Bid Adjustment"
    CAMPAIGN_PAUSE = "Campaign Pause"
    BUDGET_REALLOCATION = "Budget Reallocation"
    CONTINUE_MONITORING = "Continue Monitoring"


class RiskLevel(str, Enum):
    """Risk assessment levels"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class SignalAnalysis(BaseModel):
    """Structured signal analysis output"""
    key_signals: str = Field(description="What metrics changed and by how much")
    signal_correlation: str = Field(description="How different signals relate")
    root_cause: str = Field(description="Most likely explanation")
    confidence: float = Field(ge=0.0, le=1.0, description="Confidence in analysis")
    supporting_evidence: str = Field(description="Specific data points")
    alternate_hypotheses: str = Field(description="Other possible explanations")


class AlternativeAction(BaseModel):
    """Alternative recommendation not chosen"""
    workflow: WorkflowType
    why_not_recommended: str


class Recommendation(BaseModel):
    """Structured recommendation output"""
    recommended_workflow: WorkflowType
    reasoning: str = Field(description="Clear explanation connecting cause to action")
    specific_actions: str = Field(description="Concrete steps to take")
    expected_impact: str = Field(description="What metrics should improve")
    risk_level: RiskLevel
    confidence: float = Field(ge=0.0, le=1.0)
    timeline: str = Field(description="When to expect results")
    success_criteria: str = Field(description="How to measure success")
    alternatives: List[AlternativeAction] = Field(default_factory=list)
    
    # Metadata
    signal_analysis: str = Field(description="The analysis this is based on")
    model_version: Optional[str] = None


class CritiqueResult(BaseModel):
    """Critique of a recommendation"""
    is_satisfactory: bool
    critical_issues: List[str] = Field(default_factory=list)
    major_issues: List[str] = Field(default_factory=list)
    minor_issues: List[str] = Field(default_factory=list)
    strengths: List[str] = Field(default_factory=list)
    suggestions: List[str] = Field(default_factory=list)
    overall_assessment: str
