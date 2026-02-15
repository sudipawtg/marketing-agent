"""Competitor signals collector (stub implementation)"""

from datetime import datetime
from typing import List
from pydantic import BaseModel
from .base import BaseCollector
import random


class CompetitorActivity(BaseModel):
    """Individual competitor data"""
    competitor_name: str
    market_share_pct: float
    activity_change_pct: float
    estimated_spend_change_pct: float


class CompetitorSignals(BaseModel):
    """Competitor activity indicators"""
    campaign_id: str
    
    # Overall market dynamics
    total_competitors: int
    new_entrants_last_week: int
    market_activity_change_pct: float
    
    # Competitive pressure
    auction_competition_score: float  # 0-100
    avg_competitor_bid_change_pct: float
    impression_share_lost_to_competitors_pct: float
    
    # Top competitors
    top_competitors: List[CompetitorActivity]
    
    # Assessment
    competitive_pressure: str  # low, medium, high
    pressure_reasoning: str
    
    collected_at: datetime


class CompetitorSignalsCollector(BaseCollector[CompetitorSignals]):
    """Collect competitor intelligence
    
    NOTE: This is a stub implementation returning mock data for POC
    In production, this would integrate with SEMrush, SpyFu, etc.
    """
    
    async def collect(self, campaign_id: str) -> CompetitorSignals:
        """Collect competitor signals"""
        cache_key = self._get_cache_key(campaign_id)
        cached = self._get_from_cache(cache_key)
        if cached:
            return cached
        
        metrics = self._generate_mock_metrics(campaign_id)
        self._set_cache(cache_key, metrics)
        return metrics
    
    def _generate_mock_metrics(self, campaign_id: str) -> CompetitorSignals:
        """Generate realistic mock competitor data"""
        
        total_competitors = random.randint(5, 15)
        new_entrants = random.randint(0, 4)
        market_activity_change = random.uniform(-20, 60)
        auction_score = random.uniform(30, 95)
        bid_change = random.uniform(-15, 40)
        impression_share_lost = random.uniform(5, 35)
        
        # Generate top competitors
        top_competitors = [
            CompetitorActivity(
                competitor_name=f"Competitor {chr(65+i)}",
                market_share_pct=random.uniform(10, 30),
                activity_change_pct=random.uniform(-10, 50),
                estimated_spend_change_pct=random.uniform(-5, 45)
            )
            for i in range(min(5, total_competitors))
        ]
        
        # Assess pressure level
        pressure_score = (
            (auction_score / 100 * 40) +
            (min(abs(market_activity_change), 50) / 50 * 30) +
            (min(abs(bid_change), 40) / 40 * 30)
        )
        
        if pressure_score > 70:
            pressure = "high"
            reasoning = f"High competitive pressure: auction competition score {auction_score:.0f}/100, "
            reasoning += f"market activity up {market_activity_change:.1f}%, "
            reasoning += f"avg bid increase {bid_change:.1f}%"
        elif pressure_score > 40:
            pressure = "medium"
            reasoning = f"Moderate competitive pressure: auction score {auction_score:.0f}/100, "
            reasoning += f"{new_entrants} new entrants, market activity change {market_activity_change:.1f}%"
        else:
            pressure = "low"
            reasoning = f"Low competitive pressure: stable auction environment, "
            reasoning += f"market activity change {market_activity_change:.1f}%"
        
        return CompetitorSignals(
            campaign_id=campaign_id,
            total_competitors=total_competitors,
            new_entrants_last_week=new_entrants,
            market_activity_change_pct=round(market_activity_change, 1),
            auction_competition_score=round(auction_score, 1),
            avg_competitor_bid_change_pct=round(bid_change, 1),
            impression_share_lost_to_competitors_pct=round(impression_share_lost, 1),
            top_competitors=top_competitors,
            competitive_pressure=pressure,
            pressure_reasoning=reasoning,
            collected_at=datetime.now()
        )
