"""Campaign metrics collector (stub implementation)"""

from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field
from .base import BaseCollector
import random


class CampaignMetrics(BaseModel):
    """Campaign performance metrics"""
    campaign_id: str
    campaign_name: str
    platform: str
    
    # Current period metrics
    impressions: int
    clicks: int
    conversions: int
    spend: float
    cpa: float  # Cost per acquisition
    ctr: float  # Click-through rate
    cvr: float  # Conversion rate
    cpm: float  # Cost per mille
    
    # Comparison to previous period
    cpa_change_pct: float
    ctr_change_pct: float
    cvr_change_pct: float
    spend_change_pct: float
    
    # Time range
    period_start: datetime
    period_end: datetime
    comparison_period_start: datetime
    comparison_period_end: datetime
    
    # Additional context
    budget: float
    budget_utilization_pct: float
    days_running: int


class CampaignMetricsCollector(BaseCollector[CampaignMetrics]):
    """Collect campaign performance data from ad platforms
    
    NOTE: This is a stub implementation returning mock data for POC
    """
    
    async def collect(self, campaign_id: str, days: int = 7) -> CampaignMetrics:
        """Collect campaign metrics
        
        Args:
            campaign_id: Campaign identifier
            days: Number of days to analyze
        """
        # Check cache
        cache_key = self._get_cache_key(campaign_id, days=days)
        cached = self._get_from_cache(cache_key)
        if cached:
            return cached
        
        # Generate mock data (in production, this would call actual APIs)
        metrics = self._generate_mock_metrics(campaign_id, days)
        
        # Cache result
        self._set_cache(cache_key, metrics)
        
        return metrics
    
    def _generate_mock_metrics(self, campaign_id: str, days: int) -> CampaignMetrics:
        """Generate realistic mock data for testing"""
        
        # Base metrics with some variation
        impressions = random.randint(50000, 150000)
        clicks = int(impressions * random.uniform(0.01, 0.05))
        conversions = int(clicks * random.uniform(0.02, 0.08))
        spend = random.uniform(3000, 8000)
        
        cpa = spend / conversions if conversions > 0 else 0
        ctr = (clicks / impressions * 100) if impressions > 0 else 0
        cvr = (conversions / clicks * 100) if clicks > 0 else 0
        cpm = (spend / impressions * 1000) if impressions > 0 else 0
        
        # Simulate performance changes
        cpa_change = random.uniform(-40, 50)  # -40% to +50%
        ctr_change = random.uniform(-20, 30)
        cvr_change = random.uniform(-25, 25)
        spend_change = random.uniform(-10, 20)
        
        now = datetime.now()
        
        return CampaignMetrics(
            campaign_id=campaign_id,
            campaign_name=f"Campaign {campaign_id[-4:]}",
            platform="google_ads",
            impressions=impressions,
            clicks=clicks,
            conversions=conversions,
            spend=round(spend, 2),
            cpa=round(cpa, 2),
            ctr=round(ctr, 2),
            cvr=round(cvr, 2),
            cpm=round(cpm, 2),
            cpa_change_pct=round(cpa_change, 1),
            ctr_change_pct=round(ctr_change, 1),
            cvr_change_pct=round(cvr_change, 1),
            spend_change_pct=round(spend_change, 1),
            period_start=now - timedelta(days=days),
            period_end=now,
            comparison_period_start=now - timedelta(days=days*2),
            comparison_period_end=now - timedelta(days=days),
            budget=10000.0,
            budget_utilization_pct=round((spend / 10000) * 100, 1),
            days_running=days
        )
