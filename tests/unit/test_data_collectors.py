"""Test suite for data collectors"""

import pytest
from src.data_collectors import (
    CampaignMetricsCollector,
    CreativeMetricsCollector,
    CompetitorSignalsCollector,
    ContextBuilder
)


@pytest.mark.asyncio
async def test_campaign_metrics_collector():
    """Test campaign metrics collection"""
    collector = CampaignMetricsCollector()
    result = await collector.collect("test_campaign_123")
    
    assert result.campaign_id == "test_campaign_123"
    assert result.impressions > 0
    assert result.clicks > 0
    assert result.cpa > 0
    assert -100 < result.cpa_change_pct < 100


@pytest.mark.asyncio
async def test_creative_metrics_collector():
    """Test creative metrics collection"""
    collector = CreativeMetricsCollector()
    result = await collector.collect("test_campaign_123")
    
    assert result.campaign_id == "test_campaign_123"
    assert result.total_creatives > 0
    assert len(result.top_performers) > 0
    assert result.fatigue_detected in [True, False]


@pytest.mark.asyncio
async def test_competitor_signals_collector():
    """Test competitor signals collection"""
    collector = CompetitorSignalsCollector()
    result = await collector.collect("test_campaign_123")
    
    assert result.campaign_id == "test_campaign_123"
    assert result.total_competitors > 0
    assert result.competitive_pressure in ["low", "medium", "high"]
    assert len(result.top_competitors) > 0


@pytest.mark.asyncio
async def test_context_builder():
    """Test parallel context building"""
    builder = ContextBuilder()
    context = await builder.build_context("test_campaign_123")
    
    assert context.campaign_id == "test_campaign_123"
    assert context.campaign_metrics is not None
    assert context.creative_metrics is not None
    assert context.competitor_signals is not None
    assert context.collection_time_ms > 0
    
    # Test context formatting
    context_text = builder.format_context_for_llm(context)
    assert "Campaign Overview" in context_text
    assert "Performance Metrics" in context_text
    assert "Creative Performance" in context_text
    assert "Competitive Landscape" in context_text
