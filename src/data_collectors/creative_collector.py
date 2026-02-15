"""Creative performance collector (stub implementation)"""

from datetime import datetime, timedelta
from typing import List
from pydantic import BaseModel
from enum import Enum
from .base import BaseCollector
import random


class CreativeTrend(str, Enum):
    IMPROVING = "improving"
    STABLE = "stable"
    DECLINING = "declining"


class CreativeAsset(BaseModel):
    """Individual creative asset"""
    asset_id: str
    asset_type: str  # image, video, text
    impressions: int
    clicks: int
    ctr: float
    age_days: int


class CreativeMetrics(BaseModel):
    """Creative performance and fatigue indicators"""
    campaign_id: str
    
    # Overall creative performance
    total_creatives: int
    avg_creative_age_days: int
    avg_ctr: float
    ctr_trend: CreativeTrend
    
    # Fatigue indicators
    frequency: float  # Average impressions per user
    engagement_rate: float
    engagement_trend: CreativeTrend
    
    # Individual assets (top performers)
    top_performers: List[CreativeAsset]
    underperformers: List[CreativeAsset]
    
    # Recommendations
    fatigue_detected: bool
    refresh_recommended: bool
    refresh_reasoning: str
    
    collected_at: datetime


class CreativeMetricsCollector(BaseCollector[CreativeMetrics]):
    """Collect creative performance and fatigue signals
    
    NOTE: This is a stub implementation returning mock data for POC
    """
    
    async def collect(self, campaign_id: str) -> CreativeMetrics:
        """Collect creative metrics"""
        cache_key = self._get_cache_key(campaign_id)
        cached = self._get_from_cache(cache_key)
        if cached:
            return cached
        
        metrics = self._generate_mock_metrics(campaign_id)
        self._set_cache(cache_key, metrics)
        return metrics
    
    def _generate_mock_metrics(self, campaign_id: str) -> CreativeMetrics:
        """Generate realistic mock creative data"""
        
        # Simulate creative performance
        total_creatives = random.randint(3, 10)
        avg_age = random.randint(5, 45)
        avg_ctr = random.uniform(1.5, 4.0)
        frequency = random.uniform(2.5, 8.0)
        engagement_rate = random.uniform(0.5, 3.0)
        
        # Determine trends
        ctr_trend = random.choice([
            CreativeTrend.IMPROVING,
            CreativeTrend.STABLE,
            CreativeTrend.DECLINING
        ])
        
        engagement_trend = random.choice([
            CreativeTrend.IMPROVING,
            CreativeTrend.STABLE,
            CreativeTrend.DECLINING
        ])
        
        # Generate asset examples
        top_performers = [
            CreativeAsset(
                asset_id=f"asset_{i}",
                asset_type=random.choice(["image", "video"]),
                impressions=random.randint(10000, 50000),
                clicks=random.randint(300, 2000),
                ctr=random.uniform(2.5, 5.0),
                age_days=random.randint(1, 30)
            )
            for i in range(min(3, total_creatives))
        ]
        
        underperformers = [
            CreativeAsset(
                asset_id=f"asset_{i+10}",
                asset_type=random.choice(["image", "video"]),
                impressions=random.randint(5000, 15000),
                clicks=random.randint(50, 300),
                ctr=random.uniform(0.5, 1.5),
                age_days=random.randint(20, 60)
            )
            for i in range(min(2, total_creatives))
        ]
        
        # Detect fatigue
        fatigue_detected = (
            avg_age > 30 or
            frequency > 6.0 or
            ctr_trend == CreativeTrend.DECLINING
        )
        
        refresh_reasoning = ""
        if fatigue_detected:
            reasons = []
            if avg_age > 30:
                reasons.append(f"creatives aging (avg {avg_age} days)")
            if frequency > 6.0:
                reasons.append(f"high frequency ({frequency:.1f})")
            if ctr_trend == CreativeTrend.DECLINING:
                reasons.append("declining CTR trend")
            refresh_reasoning = "Creative fatigue detected: " + ", ".join(reasons)
        else:
            refresh_reasoning = "Creatives performing well, no refresh needed"
        
        return CreativeMetrics(
            campaign_id=campaign_id,
            total_creatives=total_creatives,
            avg_creative_age_days=avg_age,
            avg_ctr=round(avg_ctr, 2),
            ctr_trend=ctr_trend,
            frequency=round(frequency, 1),
            engagement_rate=round(engagement_rate, 2),
            engagement_trend=engagement_trend,
            top_performers=top_performers,
            underperformers=underperformers,
            fatigue_detected=fatigue_detected,
            refresh_recommended=fatigue_detected,
            refresh_reasoning=refresh_reasoning,
            collected_at=datetime.now()
        )
