"""Database models for Marketing Agent"""

from datetime import datetime
from typing import Optional
from sqlalchemy import Column, String, DateTime, Float, Integer, JSON, Enum, ForeignKey, Text
from sqlalchemy.orm import relationship, declarative_base
from sqlalchemy.sql import func
import uuid
import enum

Base = declarative_base()


def generate_uuid():
    """Generate UUID string for primary keys"""
    return str(uuid.uuid4())


class WorkflowType(str, enum.Enum):
    """Available workflow types"""
    CREATIVE_REFRESH = "Creative Refresh"
    AUDIENCE_EXPANSION = "Audience Expansion"
    BID_ADJUSTMENT = "Bid Adjustment"
    CAMPAIGN_PAUSE = "Campaign Pause"
    BUDGET_REALLOCATION = "Budget Reallocation"
    CONTINUE_MONITORING = "Continue Monitoring"


class RiskLevel(str, enum.Enum):
    """Risk assessment levels"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class DecisionStatus(str, enum.Enum):
    """Human decision on recommendation"""
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class Campaign(Base):
    """Campaign metadata"""
    __tablename__ = "campaigns"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    external_id = Column(String, unique=True, nullable=False, index=True)
    name = Column(String, nullable=False)
    platform = Column(String, nullable=False)  # google_ads, meta_ads, etc.
    status = Column(String, nullable=False)
    campaign_metadata = Column(JSON, nullable=True)  # Renamed from 'metadata' (reserved word)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    recommendations = relationship("Recommendation", back_populates="campaign")


class Recommendation(Base):
    """Agent recommendations"""
    __tablename__ = "recommendations"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    campaign_id = Column(String, ForeignKey("campaigns.id"), nullable=False)
    
    # Recommendation details
    recommended_workflow = Column(Enum(WorkflowType), nullable=False)
    reasoning = Column(Text, nullable=False)
    expected_impact = Column(Text, nullable=True)
    risk_level = Column(Enum(RiskLevel), nullable=False)
    confidence = Column(Float, nullable=False)
    
    # Context and analysis
    signal_analysis = Column(Text, nullable=True)
    root_cause = Column(String, nullable=True)
    context = Column(JSON, nullable=False)  # Full campaign context
    alternatives = Column(JSON, nullable=True)  # Alternative recommendations
    
    # Human decision
    human_decision = Column(Enum(DecisionStatus), default=DecisionStatus.PENDING)
    decision_feedback = Column(Text, nullable=True)
    decided_at = Column(DateTime, nullable=True)
    decided_by = Column(String, nullable=True)
    
    # Workflow execution
    workflow_triggered = Column(String, nullable=True)
    workflow_result = Column(JSON, nullable=True)
    
    # Metadata
    model_version = Column(String, nullable=True)
    prompt_version = Column(String, nullable=True)
    generation_time_ms = Column(Integer, nullable=True)
    token_usage = Column(JSON, nullable=True)
    cost_usd = Column(Float, nullable=True)
    
    created_at = Column(DateTime, server_default=func.now())
    
    # Relationships
    campaign = relationship("Campaign", back_populates="recommendations")
    evaluations = relationship("EvaluationResult", back_populates="recommendation")


class EvaluationResult(Base):
    """Evaluation results for recommendations"""
    __tablename__ = "evaluation_results"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    recommendation_id = Column(String, ForeignKey("recommendations.id"), nullable=True)
    
    # Evaluation details
    eval_type = Column(String, nullable=False)  # golden_set, llm_judge, outcome_tracking
    eval_name = Column(String, nullable=False)
    
    # Scores
    score = Column(Float, nullable=True)
    passed = Column(String, nullable=True)
    
    # Details
    expected = Column(JSON, nullable=True)
    actual = Column(JSON, nullable=True)
    details = Column(JSON, nullable=True)
    
    run_id = Column(String, nullable=True)
    run_at = Column(DateTime, server_default=func.now())
    
    # Relationships
    recommendation = relationship("Recommendation", back_populates="evaluations")


class AgentExecution(Base):
    """Detailed agent execution logs for debugging"""
    __tablename__ = "agent_executions"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    recommendation_id = Column(String, nullable=True)
    
    # Execution details
    workflow_state = Column(JSON, nullable=False)
    node_executions = Column(JSON, nullable=False)  # List of node executions
    errors = Column(JSON, nullable=True)
    
    # Performance
    total_time_ms = Column(Integer, nullable=True)
    llm_calls = Column(Integer, nullable=True)
    total_tokens = Column(Integer, nullable=True)
    
    executed_at = Column(DateTime, server_default=func.now())
