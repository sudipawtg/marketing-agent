"""Context builder - orchestrates parallel data collection"""

import asyncio
from typing import Dict, Any
from datetime import datetime
from pydantic import BaseModel

from .campaign_collector import CampaignMetricsCollector, CampaignMetrics
from .creative_collector import CreativeMetricsCollector, CreativeMetrics
from .competitor_collector import CompetitorSignalsCollector, CompetitorSignals


class CampaignContext(BaseModel):
    """Complete context for campaign analysis"""
    campaign_id: str
    campaign_metrics: CampaignMetrics
    creative_metrics: CreativeMetrics
    competitor_signals: CompetitorSignals
    collected_at: datetime
    collection_time_ms: int


class ContextBuilder:
    """Orchestrate parallel data collection from all sources"""
    
    def __init__(self):
        self.campaign_collector = CampaignMetricsCollector()
        self.creative_collector = CreativeMetricsCollector()
        self.competitor_collector = CompetitorSignalsCollector()
    
    async def build_context(self, campaign_id: str, days: int = 7) -> CampaignContext:
        """
        Collect all campaign context in parallel
        
        Args:
            campaign_id: Campaign identifier
            days: Number of days for analysis window
        
        Returns:
            Complete campaign context
        """
        start_time = datetime.now()
        
        # Collect data in parallel
        campaign_metrics, creative_metrics, competitor_signals = await asyncio.gather(
            self.campaign_collector.collect(campaign_id, days=days),
            self.creative_collector.collect(campaign_id),
            self.competitor_collector.collect(campaign_id),
            return_exceptions=True
        )
        
        # Handle potential errors
        if isinstance(campaign_metrics, Exception):
            raise Exception(f"Failed to collect campaign metrics: {campaign_metrics}")
        if isinstance(creative_metrics, Exception):
            raise Exception(f"Failed to collect creative metrics: {creative_metrics}")
        if isinstance(competitor_signals, Exception):
            raise Exception(f"Failed to collect competitor signals: {competitor_signals}")
        
        collection_time = int((datetime.now() - start_time).total_seconds() * 1000)
        
        return CampaignContext(
            campaign_id=campaign_id,
            campaign_metrics=campaign_metrics,
            creative_metrics=creative_metrics,
            competitor_signals=competitor_signals,
            collected_at=datetime.now(),
            collection_time_ms=collection_time
        )
    
    def format_context_for_llm(self, context: CampaignContext) -> str:
        """Format context as readable text for LLM consumption"""
        
        cm = context.campaign_metrics
        cr = context.creative_metrics
        comp = context.competitor_signals
        
        return f"""
## Campaign Overview
- Campaign: {cm.campaign_name} (ID: {cm.campaign_id})
- Platform: {cm.platform}
- Period: {cm.period_start.strftime('%Y-%m-%d')} to {cm.period_end.strftime('%Y-%m-%d')} ({cm.days_running} days)
- Budget: ${cm.budget:,.2f} (${cm.spend:,.2f} spent, {cm.budget_utilization_pct}% utilized)

## Performance Metrics
### Current Period
- Impressions: {cm.impressions:,}
- Clicks: {cm.clicks:,} (CTR: {cm.ctr:.2f}%)
- Conversions: {cm.conversions:,} (CVR: {cm.cvr:.2f}%)
- Spend: ${cm.spend:,.2f}
- CPA: ${cm.cpa:.2f}
- CPM: ${cm.cpm:.2f}

### Changes vs. Previous Period
- CPA: {cm.cpa_change_pct:+.1f}%
- CTR: {cm.ctr_change_pct:+.1f}%
- CVR: {cm.cvr_change_pct:+.1f}%
- Spend: {cm.spend_change_pct:+.1f}%

## Creative Performance
- Total Creatives: {cr.total_creatives}
- Average Creative Age: {cr.avg_creative_age_days} days
- Average CTR: {cr.avg_ctr:.2f}%
- CTR Trend: {cr.ctr_trend.value}
- Frequency: {cr.frequency:.1f} impressions/user
- Engagement Rate: {cr.engagement_rate:.2f}%
- Engagement Trend: {cr.engagement_trend.value}
- Fatigue Detected: {cr.fatigue_detected}
- Refresh Recommended: {cr.refresh_recommended}
- Reasoning: {cr.refresh_reasoning}

### Top Performing Assets
{self._format_assets(cr.top_performers)}

### Underperforming Assets
{self._format_assets(cr.underperformers)}

## Competitive Landscape
- Total Competitors: {comp.total_competitors}
- New Entrants (last 7 days): {comp.new_entrants_last_week}
- Market Activity Change: {comp.market_activity_change_pct:+.1f}%
- Auction Competition Score: {comp.auction_competition_score:.1f}/100
- Avg Competitor Bid Change: {comp.avg_competitor_bid_change_pct:+.1f}%
- Impression Share Lost to Competitors: {comp.impression_share_lost_to_competitors_pct:.1f}%
- Competitive Pressure: {comp.competitive_pressure.upper()}
- Assessment: {comp.pressure_reasoning}

### Top Competitors
{self._format_competitors(comp.top_competitors)}
""".strip()
    
    def _format_assets(self, assets) -> str:
        """Format creative assets for display"""
        if not assets:
            return "  None"
        
        lines = []
        for asset in assets:
            lines.append(
                f"  - {asset.asset_id} ({asset.asset_type}): "
                f"{asset.impressions:,} impressions, CTR {asset.ctr:.2f}%, "
                f"{asset.age_days} days old"
            )
        return "\n".join(lines)
    
    def _format_competitors(self, competitors) -> str:
        """Format competitor data for display"""
        if not competitors:
            return "  None"
        
        lines = []
        for comp in competitors:
            lines.append(
                f"  - {comp.competitor_name}: "
                f"{comp.market_share_pct:.1f}% market share, "
                f"activity {comp.activity_change_pct:+.1f}%, "
                f"spend {comp.estimated_spend_change_pct:+.1f}%"
            )
        return "\n".join(lines)
