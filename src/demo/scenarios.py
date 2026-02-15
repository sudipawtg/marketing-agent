"""Demo scenarios for showcasing the Marketing Agent"""

from typing import Dict, Any
from src.data_collectors.campaign_collector import CampaignMetrics
from src.data_collectors.creative_collector import CreativeMetrics, CreativeTrend, CreativeAsset
from src.data_collectors.competitor_collector import CompetitorSignals, CompetitorActivity
from datetime import datetime, timedelta


class DemoScenarios:
    """Predefined scenarios that showcase different reasoning patterns"""
    
    @staticmethod
    def get_scenario(scenario_name: str) -> Dict[str, Any]:
        """Get a predefined scenario by name"""
        scenarios = {
            "competitive_pressure": DemoScenarios.competitive_pressure_scenario(),
            "creative_fatigue": DemoScenarios.creative_fatigue_scenario(),
            "audience_saturation": DemoScenarios.audience_saturation_scenario(),
            "winning_campaign": DemoScenarios.winning_campaign_scenario(),
            "multi_signal_problem": DemoScenarios.multi_signal_problem_scenario(),
        }
        return scenarios.get(scenario_name, scenarios["competitive_pressure"])
    
    @staticmethod
    def competitive_pressure_scenario() -> Dict[str, Any]:
        """Scenario: Rising CPA due to competitor activity"""
        now = datetime.now()
        
        campaign_metrics = CampaignMetrics(
            campaign_id="demo_competitive_pressure",
            campaign_name="Spring Sale 2026 - Premium Products",
            platform="google_ads",
            impressions=125000,
            clicks=3500,
            conversions=65,
            spend=5850.00,
            cpa=90.00,  # High CPA
            ctr=2.8,    # Stable CTR
            cvr=1.86,
            cpm=46.80,
            cpa_change_pct=32.5,  # CPA increased significantly
            ctr_change_pct=-2.1,  # CTR slightly down but stable
            cvr_change_pct=-1.5,  # Conversion rate stable
            spend_change_pct=15.2,
            period_start=now - timedelta(days=7),
            period_end=now,
            comparison_period_start=now - timedelta(days=14),
            comparison_period_end=now - timedelta(days=7),
            budget=10000.0,
            budget_utilization_pct=58.5,
            days_running=7
        )
        
        creative_metrics = CreativeMetrics(
            campaign_id="demo_competitive_pressure",
            total_creatives=5,
            avg_creative_age_days=18,  # Not old
            avg_ctr=2.85,
            ctr_trend=CreativeTrend.STABLE,
            frequency=4.2,  # Not fatigued
            engagement_rate=2.1,
            engagement_trend=CreativeTrend.STABLE,
            top_performers=[
                CreativeAsset(
                    asset_id="creative_01",
                    asset_type="video",
                    impressions=45000,
                    clicks=1350,
                    ctr=3.0,
                    age_days=18
                ),
                CreativeAsset(
                    asset_id="creative_02",
                    asset_type="image",
                    impressions=38000,
                    clicks=1026,
                    ctr=2.7,
                    age_days=18
                )
            ],
            underperformers=[],
            fatigue_detected=False,
            refresh_recommended=False,
            refresh_reasoning="Creatives performing consistently, no fatigue indicators",
            collected_at=now
        )
        
        competitor_signals = CompetitorSignals(
            campaign_id="demo_competitive_pressure",
            total_competitors=12,
            new_entrants_last_week=3,  # New competitors
            market_activity_change_pct=42.5,  # High increase
            auction_competition_score=87.5,  # Very competitive
            avg_competitor_bid_change_pct=28.3,  # Bids increased
            impression_share_lost_to_competitors_pct=22.5,
            top_competitors=[
                CompetitorActivity(
                    competitor_name="Competitor A",
                    market_share_pct=18.5,
                    activity_change_pct=45.2,
                    estimated_spend_change_pct=38.7
                ),
                CompetitorActivity(
                    competitor_name="Competitor B",
                    market_share_pct=15.3,
                    activity_change_pct=35.8,
                    estimated_spend_change_pct=42.1
                ),
                CompetitorActivity(
                    competitor_name="Competitor C (NEW)",
                    market_share_pct=12.1,
                    activity_change_pct=100.0,  # New entrant
                    estimated_spend_change_pct=100.0
                )
            ],
            competitive_pressure="high",
            pressure_reasoning="High competitive pressure: 3 new market entrants, auction competition score 87.5/100, average competitor bids increased 28.3%, lost 22.5% impression share to competitors",
            collected_at=now
        )
        
        return {
            "campaign_metrics": campaign_metrics,
            "creative_metrics": creative_metrics,
            "competitor_signals": competitor_signals,
            "expected_recommendation": "Bid Adjustment",
            "scenario_description": "CPA spike due to increased competitive pressure, not creative issues"
        }
    
    @staticmethod
    def creative_fatigue_scenario() -> Dict[str, Any]:
        """Scenario: Declining performance due to ad fatigue"""
        now = datetime.now()
        
        campaign_metrics = CampaignMetrics(
            campaign_id="demo_creative_fatigue",
            campaign_name="Summer Collection Launch",
            platform="meta_ads",
            impressions=180000,
            clicks=2700,
            conversions=82,
            spend=4920.00,
            cpa=60.00,
            ctr=1.5,  # Low CTR
            cvr=3.04,
            cpm=27.33,
            cpa_change_pct=25.0,  # CPA increased
            ctr_change_pct=-38.5,  # CTR declined significantly
            cvr_change_pct=2.1,  # CVR stable
            spend_change_pct=5.2,
            period_start=now - timedelta(days=7),
            period_end=now,
            comparison_period_start=now - timedelta(days=14),
            comparison_period_end=now - timedelta(days=7),
            budget=8000.0,
            budget_utilization_pct=61.5,
            days_running=7
        )
        
        creative_metrics = CreativeMetrics(
            campaign_id="demo_creative_fatigue",
            total_creatives=4,
            avg_creative_age_days=42,  # Old creatives
            avg_ctr=1.52,
            ctr_trend=CreativeTrend.DECLINING,
            frequency=7.8,  # High frequency = fatigue
            engagement_rate=0.85,
            engagement_trend=CreativeTrend.DECLINING,
            top_performers=[
                CreativeAsset(
                    asset_id="creative_old_01",
                    asset_type="image",
                    impressions=65000,
                    clicks=975,
                    ctr=1.5,
                    age_days=42
                )
            ],
            underperformers=[
                CreativeAsset(
                    asset_id="creative_old_02",
                    asset_type="video",
                    impressions=55000,
                    clicks=660,
                    ctr=1.2,
                    age_days=42
                ),
                CreativeAsset(
                    asset_id="creative_old_03",
                    asset_type="image",
                    impressions=60000,
                    clicks=540,
                    ctr=0.9,
                    age_days=42
                )
            ],
            fatigue_detected=True,
            refresh_recommended=True,
            refresh_reasoning="Creative fatigue detected: creatives aging (avg 42 days), high frequency (7.8), declining CTR trend, declining engagement",
            collected_at=now
        )
        
        competitor_signals = CompetitorSignals(
            campaign_id="demo_creative_fatigue",
            total_competitors=8,
            new_entrants_last_week=0,
            market_activity_change_pct=8.5,  # Normal activity
            auction_competition_score=52.0,  # Moderate
            avg_competitor_bid_change_pct=5.2,
            impression_share_lost_to_competitors_pct=8.5,
            top_competitors=[
                CompetitorActivity(
                    competitor_name="Competitor X",
                    market_share_pct=22.5,
                    activity_change_pct=7.2,
                    estimated_spend_change_pct=9.1
                )
            ],
            competitive_pressure="medium",
            pressure_reasoning="Moderate competitive pressure: stable market, auction score 52.0/100, normal bid changes",
            collected_at=now
        )
        
        return {
            "campaign_metrics": campaign_metrics,
            "creative_metrics": creative_metrics,
            "competitor_signals": competitor_signals,
            "expected_recommendation": "Creative Refresh",
            "scenario_description": "Performance declining due to creative fatigue, not market conditions"
        }
    
    @staticmethod
    def audience_saturation_scenario() -> Dict[str, Any]:
        """Scenario: Audience saturation limiting reach"""
        now = datetime.now()
        
        campaign_metrics = CampaignMetrics(
            campaign_id="demo_audience_saturation",
            campaign_name="Retargeting - Cart Abandoners Q1",
            platform="google_ads",
            impressions=95000,
            clicks=2375,
            conversions=48,
            spend=3840.00,
            cpa=80.00,
            ctr=2.5,
            cvr=2.02,
            cpm=40.42,
            cpa_change_pct=28.0,
            ctr_change_pct=-12.5,
            cvr_change_pct=-8.2,
            spend_change_pct=22.5,
            period_start=now - timedelta(days=7),
            period_end=now,
            comparison_period_start=now - timedelta(days=14),
            comparison_period_end=now - timedelta(days=7),
            budget=6000.0,
            budget_utilization_pct=64.0,
            days_running=7
        )
        
        creative_metrics = CreativeMetrics(
            campaign_id="demo_audience_saturation",
            total_creatives=6,
            avg_creative_age_days=21,
            avg_ctr=2.48,
            ctr_trend=CreativeTrend.DECLINING,
            frequency=8.5,  # Very high frequency
            engagement_rate=1.2,
            engagement_trend=CreativeTrend.DECLINING,
            top_performers=[
                CreativeAsset(
                    asset_id="retarget_01",
                    asset_type="image",
                    impressions=35000,
                    clicks=875,
                    ctr=2.5,
                    age_days=21
                )
            ],
            underperformers=[],
            fatigue_detected=True,
            refresh_recommended=True,
            refresh_reasoning="High frequency (8.5) indicates audience seeing ads repeatedly",
            collected_at=now
        )
        
        competitor_signals = CompetitorSignals(
            campaign_id="demo_audience_saturation",
            total_competitors=10,
            new_entrants_last_week=1,
            market_activity_change_pct=15.2,
            auction_competition_score=58.0,
            avg_competitor_bid_change_pct=12.5,
            impression_share_lost_to_competitors_pct=11.5,
            top_competitors=[
                CompetitorActivity(
                    competitor_name="Competitor Y",
                    market_share_pct=19.5,
                    activity_change_pct=12.8,
                    estimated_spend_change_pct=15.2
                )
            ],
            competitive_pressure="medium",
            pressure_reasoning="Moderate competitive pressure: some new activity but stable overall",
            collected_at=now
        )
        
        return {
            "campaign_metrics": campaign_metrics,
            "creative_metrics": creative_metrics,
            "competitor_signals": competitor_signals,
            "expected_recommendation": "Audience Expansion",
            "scenario_description": "Audience exhausted with high frequency, need to expand targeting"
        }
    
    @staticmethod
    def winning_campaign_scenario() -> Dict[str, Any]:
        """Scenario: Campaign performing well, continue monitoring"""
        now = datetime.now()
        
        campaign_metrics = CampaignMetrics(
            campaign_id="demo_winning",
            campaign_name="Brand Awareness Q1 - Success Story",
            platform="google_ads",
            impressions=220000,
            clicks=8800,
            conversions=265,
            spend=6890.00,
            cpa=26.00,  # Low CPA
            ctr=4.0,  # High CTR
            cvr=3.01,
            cpm=31.32,
            cpa_change_pct=-15.5,  # CPA improved
            ctr_change_pct=12.3,  # CTR improved
            cvr_change_pct=8.5,  # CVR improved
            spend_change_pct=18.5,
            period_start=now - timedelta(days=7),
            period_end=now,
            comparison_period_start=now - timedelta(days=14),
            comparison_period_end=now - timedelta(days=7),
            budget=10000.0,
            budget_utilization_pct=68.9,
            days_running=7
        )
        
        creative_metrics = CreativeMetrics(
            campaign_id="demo_winning",
            total_creatives=8,
            avg_creative_age_days=15,
            avg_ctr=4.1,
            ctr_trend=CreativeTrend.IMPROVING,
            frequency=3.2,
            engagement_rate=3.8,
            engagement_trend=CreativeTrend.IMPROVING,
            top_performers=[
                CreativeAsset(
                    asset_id="winning_01",
                    asset_type="video",
                    impressions=75000,
                    clicks=3375,
                    ctr=4.5,
                    age_days=15
                ),
                CreativeAsset(
                    asset_id="winning_02",
                    asset_type="image",
                    impressions=62000,
                    clicks=2604,
                    ctr=4.2,
                    age_days=15
                )
            ],
            underperformers=[],
            fatigue_detected=False,
            refresh_recommended=False,
            refresh_reasoning="Creatives performing exceptionally well with improving trends",
            collected_at=now
        )
        
        competitor_signals = CompetitorSignals(
            campaign_id="demo_winning",
            total_competitors=9,
            new_entrants_last_week=0,
            market_activity_change_pct=-5.2,
            auction_competition_score=42.0,
            avg_competitor_bid_change_pct=-3.5,
            impression_share_lost_to_competitors_pct=5.2,
            top_competitors=[
                CompetitorActivity(
                    competitor_name="Competitor Z",
                    market_share_pct=16.5,
                    activity_change_pct=-2.1,
                    estimated_spend_change_pct=-4.8
                )
            ],
            competitive_pressure="low",
            pressure_reasoning="Low competitive pressure: market stable, competitors reducing spend",
            collected_at=now
        )
        
        return {
            "campaign_metrics": campaign_metrics,
            "creative_metrics": creative_metrics,
            "competitor_signals": competitor_signals,
            "expected_recommendation": "Continue Monitoring",
            "scenario_description": "Campaign performing excellently across all metrics, no action needed"
        }
    
    @staticmethod
    def multi_signal_problem_scenario() -> Dict[str, Any]:
        """Scenario: Multiple issues requiring prioritization"""
        now = datetime.now()
        
        campaign_metrics = CampaignMetrics(
            campaign_id="demo_complex",
            campaign_name="Holiday Sale 2026 - Multi-Product",
            platform="meta_ads",
            impressions=155000,
            clicks=3100,
            conversions=58,
            spend=5220.00,
            cpa=90.00,
            ctr=2.0,
            cvr=1.87,
            cpm=33.68,
            cpa_change_pct=35.5,
            ctr_change_pct=-22.8,
            cvr_change_pct=-5.5,
            spend_change_pct=28.5,
            period_start=now - timedelta(days=7),
            period_end=now,
            comparison_period_start=now - timedelta(days=14),
            comparison_period_end=now - timedelta(days=7),
            budget=9000.0,
            budget_utilization_pct=58.0,
            days_running=7
        )
        
        creative_metrics = CreativeMetrics(
            campaign_id="demo_complex",
            total_creatives=6,
            avg_creative_age_days=35,  # Getting old
            avg_ctr=2.05,
            ctr_trend=CreativeTrend.DECLINING,
            frequency=6.2,  # Moderate fatigue
            engagement_rate=1.35,
            engagement_trend=CreativeTrend.DECLINING,
            top_performers=[
                CreativeAsset(
                    asset_id="complex_01",
                    asset_type="image",
                    impressions=52000,
                    clicks=1092,
                    ctr=2.1,
                    age_days=35
                )
            ],
            underperformers=[
                CreativeAsset(
                    asset_id="complex_02",
                    asset_type="video",
                    impressions=48000,
                    clicks=816,
                    ctr=1.7,
                    age_days=35
                )
            ],
            fatigue_detected=True,
            refresh_recommended=True,
            refresh_reasoning="Creative fatigue detected: aging creatives (35 days), frequency at 6.2, declining trends",
            collected_at=now
        )
        
        competitor_signals = CompetitorSignals(
            campaign_id="demo_complex",
            total_competitors=15,
            new_entrants_last_week=2,
            market_activity_change_pct=32.5,
            auction_competition_score=75.0,
            avg_competitor_bid_change_pct=22.8,
            impression_share_lost_to_competitors_pct=18.5,
            top_competitors=[
                CompetitorActivity(
                    competitor_name="Major Competitor A",
                    market_share_pct=21.5,
                    activity_change_pct=35.2,
                    estimated_spend_change_pct=38.5
                ),
                CompetitorActivity(
                    competitor_name="Major Competitor B",
                    market_share_pct=18.3,
                    activity_change_pct=28.7,
                    estimated_spend_change_pct=32.1
                )
            ],
            competitive_pressure="high",
            pressure_reasoning="High competitive pressure: 2 new entrants, auction score 75.0/100, competitor bids up 22.8%",
            collected_at=now
        )
        
        return {
            "campaign_metrics": campaign_metrics,
            "creative_metrics": creative_metrics,
            "competitor_signals": competitor_signals,
            "expected_recommendation": "Creative Refresh or Bid Adjustment",
            "scenario_description": "Both creative fatigue AND competitive pressure - agent must prioritize root cause"
        }
    
    @classmethod
    def list_scenarios(cls) -> list:
        """List all available demo scenarios"""
        return [
            {
                "name": "competitive_pressure",
                "title": "🎯 Competitive Pressure Scenario",
                "summary": "CPA spike due to increased competitor activity, not internal issues"
            },
            {
                "name": "creative_fatigue",
                "title": "🎨 Creative Fatigue Scenario",
                "summary": "Performance declining due to old, worn-out ad creatives"
            },
            {
                "name": "audience_saturation",
                "title": "👥 Audience Saturation Scenario",
                "summary": "High frequency indicates audience exhaustion, need expansion"
            },
            {
                "name": "winning_campaign",
                "title": "🏆 Winning Campaign Scenario",
                "summary": "Everything performing well, no action needed"
            },
            {
                "name": "multi_signal_problem",
                "title": "🔀 Complex Multi-Signal Scenario",
                "summary": "Multiple issues present, agent must prioritize correctly"
            }
        ]
