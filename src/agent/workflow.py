"""LangGraph-based Marketing Agent workflow"""

from typing import TypedDict, Annotated, Sequence, Literal
from datetime import datetime
from langchain_core.messages import BaseMessage, HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic
from langgraph.graph import StateGraph, END
import operator
import structlog

from src.config import settings
from src.data_collectors import ContextBuilder, CampaignContext
from .prompts import (
    SIGNAL_ANALYSIS_PROMPT,
    RECOMMENDATION_GENERATION_PROMPT,
    CRITIQUE_PROMPT
)
from .models import (
    SignalAnalysis,
    Recommendation,
    CritiqueResult,
    WorkflowType,
    RiskLevel,
    AlternativeAction
)

logger = structlog.get_logger()


class AgentState(TypedDict):
    """State passed between nodes in the workflow"""
    campaign_id: str
    context: CampaignContext | None
    context_text: str
    messages: Annotated[Sequence[BaseMessage], operator.add]
    signal_analysis: SignalAnalysis | None
    signal_analysis_text: str
    recommendation: Recommendation | None
    recommendation_text: str
    critique: CritiqueResult | None
    iteration_count: int
    errors: list[str]
    metadata: dict


class MarketingAgent:
    """Marketing Reasoning Agent using LangGraph"""
    
    def __init__(self):
        self.context_builder = ContextBuilder()
        
        # Initialize LLM
        if settings.default_llm_provider == "openai":
            self.llm = ChatOpenAI(
                model=settings.default_model,
                temperature=0.1,  # Low temperature for consistency
                api_key=settings.openai_api_key
            )
        else:
            self.llm = ChatAnthropic(
                model=settings.default_model,
                temperature=0.1,
                api_key=settings.anthropic_api_key
            )
        
        # Build workflow
        self.workflow = self._build_workflow()
    
    def _build_workflow(self) -> StateGraph:
        """Build the LangGraph workflow"""
        
        workflow = StateGraph(AgentState)
        
        # Add nodes
        workflow.add_node("collect_context", self._collect_context_node)
        workflow.add_node("analyze_signals", self._analyze_signals_node)
        workflow.add_node("generate_recommendation", self._generate_recommendation_node)
        workflow.add_node("critique", self._critique_node)
        workflow.add_node("finalize", self._finalize_node)
        
        # Define edges
        workflow.set_entry_point("collect_context")
        workflow.add_edge("collect_context", "analyze_signals")
        workflow.add_edge("analyze_signals", "generate_recommendation")
        workflow.add_edge("generate_recommendation", "critique")
        
        # Conditional edge: regenerate if critique fails
        workflow.add_conditional_edges(
            "critique",
            self._should_regenerate,
            {
                "regenerate": "generate_recommendation",
                "finalize": "finalize"
            }
        )
        
        workflow.add_edge("finalize", END)
        
        return workflow.compile()
    
    async def _collect_context_node(self, state: AgentState) -> AgentState:
        """Collect all campaign context in parallel"""
        logger.info("Collecting campaign context", campaign_id=state["campaign_id"])
        
        try:
            context = await self.context_builder.build_context(state["campaign_id"])
            context_text = self.context_builder.format_context_for_llm(context)
            
            return {
                **state,
                "context": context,
                "context_text": context_text,
                "metadata": {
                    **state.get("metadata", {}),
                    "context_collection_ms": context.collection_time_ms
                }
            }
        except Exception as e:
            logger.error("Context collection failed", error=str(e))
            return {
                **state,
                "errors": state.get("errors", []) + [f"Context collection failed: {str(e)}"]
            }
    
    async def _analyze_signals_node(self, state: AgentState) -> AgentState:
        """LLM-powered signal analysis"""
        logger.info("Analyzing signals")
        
        try:
            prompt = SIGNAL_ANALYSIS_PROMPT.format(context=state["context_text"])
            
            messages = [
                SystemMessage(content="You are a marketing performance analyst."),
                HumanMessage(content=prompt)
            ]
            
            response = await self.llm.ainvoke(messages)
            analysis_text = response.content
            
            # For POC, we'll parse the text response
            # In production, use structured output
            analysis = self._parse_signal_analysis(analysis_text)
            
            return {
                **state,
                "signal_analysis": analysis,
                "signal_analysis_text": analysis_text,
                "messages": state.get("messages", []) + messages + [response]
            }
        except Exception as e:
            logger.error("Signal analysis failed", error=str(e))
            return {
                **state,
                "errors": state.get("errors", []) + [f"Signal analysis failed: {str(e)}"]
            }
    
    async def _generate_recommendation_node(self, state: AgentState) -> AgentState:
        """Generate structured recommendation"""
        logger.info("Generating recommendation", iteration=state.get("iteration_count", 0))
        
        try:
            prompt = RECOMMENDATION_GENERATION_PROMPT.format(
                signal_analysis=state["signal_analysis_text"]
            )
            
            messages = [
                SystemMessage(content="You are a marketing strategist."),
                HumanMessage(content=prompt)
            ]
            
            response = await self.llm.ainvoke(messages)
            recommendation_text = response.content
            
            # Parse recommendation
            recommendation = self._parse_recommendation(
                recommendation_text,
                state["signal_analysis_text"]
            )
            
            return {
                **state,
                "recommendation": recommendation,
                "recommendation_text": recommendation_text,
                "messages": state.get("messages", []) + messages + [response]
            }
        except Exception as e:
            logger.error("Recommendation generation failed", error=str(e))
            return {
                **state,
                "errors": state.get("errors", []) + [f"Recommendation generation failed: {str(e)}"]
            }
    
    async def _critique_node(self, state: AgentState) -> AgentState:
        """Critique the recommendation"""
        logger.info("Critiquing recommendation")
        
        try:
            prompt = CRITIQUE_PROMPT.format(
                recommendation=state["recommendation_text"]
            )
            
            messages = [
                SystemMessage(content="You are a quality assurance analyst."),
                HumanMessage(content=prompt)
            ]
            
            response = await self.llm.ainvoke(messages)
            critique_text = response.content
            
            critique = self._parse_critique(critique_text)
            
            return {
                **state,
                "critique": critique,
                "messages": state.get("messages", []) + messages + [response]
            }
        except Exception as e:
            logger.error("Critique failed", error=str(e))
            # If critique fails, accept recommendation
            return {
                **state,
                "critique": CritiqueResult(
                    is_satisfactory=True,
                    overall_assessment="Critique failed, accepting recommendation"
                )
            }
    
    async def _finalize_node(self, state: AgentState) -> AgentState:
        """Finalize the workflow"""
        logger.info("Finalizing recommendation")
        
        return {
            **state,
            "metadata": {
                **state.get("metadata", {}),
                "completed_at": datetime.now().isoformat(),
                "total_iterations": state.get("iteration_count", 0)
            }
        }
    
    def _should_regenerate(self, state: AgentState) -> Literal["regenerate", "finalize"]:
        """Decide if recommendation needs regeneration"""
        critique = state.get("critique")
        iteration = state.get("iteration_count", 0)
        
        # Max iterations check
        if iteration >= settings.max_iterations:
            logger.warning("Max iterations reached", iteration=iteration)
            return "finalize"
        
        # If critique failed or is satisfactory, finalize
        if not critique or critique.is_satisfactory:
            return "finalize"
        
        # If there are critical issues, regenerate
        if critique.critical_issues:
            logger.info("Regenerating due to critical issues", issues=critique.critical_issues)
            return "regenerate"
        
        return "finalize"
    
    def _parse_signal_analysis(self, text: str) -> SignalAnalysis:
        """Parse signal analysis from text (simplified for POC)"""
        # In production, use structured output or better parsing
        return SignalAnalysis(
            key_signals=self._extract_section(text, "Key Signals"),
            signal_correlation=self._extract_section(text, "Signal Correlation"),
            root_cause=self._extract_section(text, "Root Cause"),
            confidence=0.75,  # Default for POC
            supporting_evidence=self._extract_section(text, "Supporting Evidence"),
            alternate_hypotheses=self._extract_section(text, "Alternate")
        )
    
    def _parse_recommendation(self, text: str, analysis: str) -> Recommendation:
        """Parse recommendation from text (simplified for POC)"""
        return Recommendation(
            recommended_workflow=self._extract_workflow(text),
            reasoning=self._extract_section(text, "Reasoning"),
            specific_actions=self._extract_section(text, "Specific Actions"),
            expected_impact=self._extract_section(text, "Expected Impact"),
            risk_level=self._extract_risk_level(text),
            confidence=0.75,  # Default for POC
            timeline=self._extract_section(text, "Timeline"),
            success_criteria=self._extract_section(text, "Success Criteria"),
            alternatives=[],  # Parse if needed
            signal_analysis=analysis,
            model_version=settings.default_model
        )
    
    def _parse_critique(self, text: str) -> CritiqueResult:
        """Parse critique from text (simplified for POC)"""
        is_satisfactory = "Is Satisfactory: yes" in text or "satisfactory: yes" in text.lower()
        
        return CritiqueResult(
            is_satisfactory=is_satisfactory,
            critical_issues=[],  # Parse if needed
            major_issues=[],
            minor_issues=[],
            strengths=[],
            suggestions=[],
            overall_assessment=self._extract_section(text, "Overall Assessment")
        )
    
    def _extract_section(self, text: str, section: str) -> str:
        """Extract a section from formatted text"""
        lines = text.split('\n')
        content = []
        capture = False
        
        for line in lines:
            if section.lower() in line.lower() and ':' in line:
                capture = True
                # Get content after colon
                parts = line.split(':', 1)
                if len(parts) > 1:
                    content.append(parts[1].strip())
                continue
            elif capture and line.strip() and not line.startswith('**'):
                content.append(line.strip())
            elif capture and line.startswith('**'):
                break
        
        return ' '.join(content) if content else "Not specified"
    
    def _extract_workflow(self, text: str) -> WorkflowType:
        """Extract workflow type from text"""
        text_lower = text.lower()
        
        for workflow in WorkflowType:
            if workflow.value.lower() in text_lower:
                return workflow
        
        # Default
        return WorkflowType.CONTINUE_MONITORING
    
    def _extract_risk_level(self, text: str) -> RiskLevel:
        """Extract risk level from text"""
        text_lower = text.lower()
        
        if "risk level: high" in text_lower or "risk: high" in text_lower:
            return RiskLevel.HIGH
        elif "risk level: medium" in text_lower or "risk: medium" in text_lower:
            return RiskLevel.MEDIUM
        else:
            return RiskLevel.LOW
    
    async def analyze_campaign(self, campaign_id: str, scenario_name: str = None) -> dict:
        """
        Main entry point: analyze a campaign and generate recommendation
        
        Args:
            campaign_id: Campaign identifier
            scenario_name: Optional scenario name for demo purposes
            
        Returns:
            Dictionary with recommendation and metadata
        """
        logger.info("Starting campaign analysis", campaign_id=campaign_id, scenario=scenario_name)
        
        initial_state = {
            "campaign_id": campaign_id,
            "context": None,
            "context_text": "",
            "messages": [],
            "signal_analysis": None,
            "signal_analysis_text": "",
            "recommendation": None,
            "recommendation_text": "",
            "critique": None,
            "iteration_count": 0,
            "errors": [],
            "metadata": {
                "started_at": datetime.now().isoformat()
            }
        }
        
        # Run workflow
        final_state = await self.workflow.ainvoke(initial_state)
        
        # Extract results
        return {
            "campaign_id": campaign_id,
            "recommendation": final_state.get("recommendation"),
            "signal_analysis": final_state.get("signal_analysis"),
            "context": final_state.get("context"),
            "critique": final_state.get("critique"),
            "metadata": final_state.get("metadata"),
            "errors": final_state.get("errors", [])
        }
