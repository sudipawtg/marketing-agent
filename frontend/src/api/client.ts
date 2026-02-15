import axios from 'axios';

const api = axios.create({
  baseURL: '/api',
  headers: {
    'Content-Type': 'application/json',
  },
});

export interface CampaignMetrics {
  impressions: number;
  clicks: number;
  conversions: number;
  spend: number;
  cpa: number;
  ctr: number;
  conversion_rate: number;
  frequency: number;
}

export interface CreativeMetrics {
  age_days: number;
  frequency: number;
  ctr: number;
  fatigue_score: number;
  last_refresh_days_ago: number;
}

export interface CompetitorSignals {
  total_competitors: number;
  new_entrants_last_week: number;
  market_activity_change_pct: number;
  auction_competition_score: number;
  avg_competitor_bid_change_pct: number;
  impression_share_lost_to_competitors_pct: number;
  competitive_pressure: string;
  pressure_reasoning: string;
}

export interface AlternativeAction {
  workflow_type: string;
  confidence: number;
  reason: string;
}

export interface Recommendation {
  id: string;
  campaign_id: string;
  workflow_type: string;
  confidence_score: number;
  reasoning: string;
  risk_level: string;
  alternative_actions: AlternativeAction[];
  signal_analysis: {
    primary_signals: Record<string, any>;
    secondary_signals: Record<string, any>;
    root_cause: string;
    confidence: number;
  };
  context: {
    campaign_metrics: CampaignMetrics;
    creative_metrics: CreativeMetrics;
    competitor_signals: CompetitorSignals;
    lookback_days: number;
  };
  human_decision?: 'APPROVED' | 'REJECTED' | 'NEEDS_REVISION';
  decision_feedback?: string;
  decided_by?: string;
  decided_at?: string;
  created_at: string;
}

export interface AnalyzeRequest {
  campaign_id: string;
  lookback_days?: number;
  scenario_name?: string;
}

export interface DecisionRequest {
  decision: 'approved' | 'rejected' | 'pending';
  feedback?: string;
  decided_by?: string;
}

export const recommendationsApi = {
  analyze: async (request: AnalyzeRequest): Promise<Recommendation> => {
    const response = await api.post('/recommendations/analyze', request);
    const data = response.data;
    
    // Extract context data with defaults
    const ctx = data.context || {};
    const campaignMetrics = ctx.campaign_metrics || {};
    const creativeMetrics = ctx.creative_metrics || {};
    const competitorSignals = ctx.competitor_signals || {};
    
    // Transform backend response to frontend format
    return {
      id: data.recommendation_id,
      campaign_id: data.campaign_id,
      workflow_type: data.recommendation.recommended_workflow,
      confidence_score: data.recommendation.confidence,
      reasoning: data.recommendation.reasoning,
      risk_level: data.recommendation.risk_level,
      alternative_actions: data.recommendation.alternatives?.map((alt: any) => ({
        workflow_type: alt.workflow_type,
        confidence: alt.confidence,
        reason: alt.reason
      })) || [],
      signal_analysis: {
        primary_signals: {},
        secondary_signals: {},
        root_cause: data.signal_analysis || '',
        confidence: data.recommendation.confidence
      },
      context: {
        campaign_metrics: {
          impressions: campaignMetrics.impressions || 0,
          clicks: campaignMetrics.clicks || 0,
          conversions: campaignMetrics.conversions || 0,
          spend: campaignMetrics.spend || 0,
          cpa: campaignMetrics.cpa || 0,
          ctr: campaignMetrics.ctr || 0,
          conversion_rate: campaignMetrics.conversion_rate || 0,
          frequency: campaignMetrics.frequency || 0
        },
        creative_metrics: {
          age_days: creativeMetrics.avg_creative_age_days || 0,
          frequency: creativeMetrics.frequency || 0,
          ctr: creativeMetrics.avg_ctr || 0,
          fatigue_score: creativeMetrics.engagement_rate || 0,
          last_refresh_days_ago: 0
        },
        competitor_signals: {
          new_competitors_count: competitorSignals.new_competitors_count || 0,
          auction_overlap_increase: competitorSignals.auction_overlap_increase || 0,
          impression_share_lost: competitorSignals.impression_share_lost || 0,
          avg_cpc_change: competitorSignals.avg_cpc_change || 0
        },
        lookback_days: ctx.lookback_days || 30
      },
      human_decision: 'NEEDS_REVISION',
      created_at: data.generated_at
    };
  },

  get: async (id: string): Promise<Recommendation> => {
    const response = await api.get(`/recommendations/${id}`);
    return response.data;
  },

  recordDecision: async (id: string, decision: DecisionRequest): Promise<void> => {
    await api.post(`/recommendations/${id}/decision`, decision);
  },

  list: async (): Promise<Recommendation[]> => {
    const response = await api.get('/recommendations/');
    return response.data.recommendations;
  },
};

export default api;
