import { useState } from 'react';
import { 
  Brain, 
  CheckCircle2, 
  XCircle, 
  Clock,
  Target,
  Zap,
  ThumbsUp,
  ThumbsDown,
  MessageSquare
} from 'lucide-react';
import { Recommendation, recommendationsApi, DecisionRequest } from '../api/client';

interface Props {
  recommendation: Recommendation;
  onDecisionComplete: () => void;
}

const WORKFLOW_LABELS: Record<string, { label: string; icon: string; color: string }> = {
  'BID_ADJUSTMENT': { label: 'Bid Adjustment', icon: '💰', color: 'blue' },
  'CREATIVE_REFRESH': { label: 'Creative Refresh', icon: '🎨', color: 'purple' },
  'AUDIENCE_EXPANSION': { label: 'Audience Expansion', icon: '👥', color: 'green' },
  'PAUSE_CAMPAIGN': { label: 'Pause Campaign', icon: '⏸️', color: 'red' },
  'CONTINUE_MONITORING': { label: 'Continue Monitoring', icon: '👁️', color: 'gray' },
};

const RISK_COLORS: Record<string, string> = {
  'LOW': 'green',
  'MEDIUM': 'yellow',
  'HIGH': 'red',
};

export default function RecommendationView({ recommendation, onDecisionComplete }: Props) {
  const [submitting, setSubmitting] = useState(false);
  const [showFeedback, setShowFeedback] = useState(false);
  const [feedback, setFeedback] = useState('');
  const [decision, setDecision] = useState<'approved' | 'rejected' | null>(null);

  const workflow = WORKFLOW_LABELS[recommendation.workflow_type] || { 
    label: recommendation.workflow_type, 
    icon: '⚡', 
    color: 'blue' 
  };

  const handleDecision = async (dec: 'approved' | 'rejected') => {
    setDecision(dec);
    setShowFeedback(true);
  };

  const handleSubmit = async () => {
    if (!decision) return;
    
    setSubmitting(true);
    try {
      const decisionRequest: DecisionRequest = {
        decision,
        feedback: feedback.trim() || undefined,
        decided_by: 'Demo User'
      };
      
      await recommendationsApi.recordDecision(recommendation.id, decisionRequest);
      onDecisionComplete();
    } catch (err) {
      console.error('Failed to record decision:', err);
    } finally {
      setSubmitting(false);
    }
  };

  const formatMetric = (value: number, decimals: number = 2): string => {
    return value.toFixed(decimals);
  };

  const formatCurrency = (value: number): string => {
    return new Intl.NumberFormat('en-US', { 
      style: 'currency', 
      currency: 'USD',
      minimumFractionDigits: 2 
    }).format(value);
  };

  return (
    <div className="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
      {/* Header */}
      <div className={`bg-gradient-to-r from-${workflow.color}-500 to-${workflow.color}-600 px-6 py-4`}>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="text-3xl">{workflow.icon}</div>
            <div>
              <h2 className="text-2xl font-bold text-white">{workflow.label}</h2>
              <p className="text-white/80 text-sm">Campaign: {recommendation.campaign_id}</p>
            </div>
          </div>
          <div className="flex items-center gap-4">
            <div className="text-right">
              <p className="text-white/80 text-xs font-medium">Confidence</p>
              <p className="text-2xl font-bold text-white">
                {(recommendation.confidence_score * 100).toFixed(0)}%
              </p>
            </div>
            <div className={`px-4 py-2 bg-${RISK_COLORS[recommendation.risk_level]}-100 border border-${RISK_COLORS[recommendation.risk_level]}-300 rounded-lg`}>
              <p className="text-xs font-medium text-slate-600">Risk Level</p>
              <p className={`text-lg font-bold text-${RISK_COLORS[recommendation.risk_level]}-700`}>
                {recommendation.risk_level}
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="p-6 space-y-6">
        {/* AI Reasoning Section */}
        <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-lg p-5 border border-blue-100">
          <div className="flex items-start gap-3 mb-3">
            <div className="w-8 h-8 bg-blue-500 rounded-lg flex items-center justify-center flex-shrink-0">
              <Brain className="w-5 h-5 text-white" />
            </div>
            <div className="flex-1">
              <h3 className="text-lg font-bold text-slate-900 mb-2">AI Reasoning</h3>
              <p className="text-slate-700 leading-relaxed whitespace-pre-wrap">
                {recommendation.reasoning}
              </p>
            </div>
          </div>
        </div>

        {/* Signal Analysis */}
        <div className="border border-slate-200 rounded-lg p-5">
          <div className="flex items-center gap-2 mb-4">
            <Zap className="w-5 h-5 text-yellow-500" />
            <h3 className="text-lg font-bold text-slate-900">Signal Analysis</h3>
          </div>
          
          {/* Root Cause */}
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-4">
            <p className="text-sm font-semibold text-yellow-900 mb-1">Root Cause Identified:</p>
            <p className="text-yellow-800">{recommendation.signal_analysis.root_cause}</p>
          </div>

          {/* Primary Signals */}
          <div className="mb-4">
            <h4 className="text-sm font-semibold text-slate-900 mb-2">Primary Signals</h4>
            <div className="grid grid-cols-2 gap-3">
              {Object.entries(recommendation.signal_analysis.primary_signals).map(([key, value]) => (
                <div key={key} className="bg-slate-50 rounded-lg p-3">
                  <p className="text-xs text-slate-500 font-medium">{key.replace(/_/g, ' ').toUpperCase()}</p>
                  <p className="text-lg font-bold text-slate-900">{String(value)}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Secondary Signals */}
          {Object.keys(recommendation.signal_analysis.secondary_signals).length > 0 && (
            <div>
              <h4 className="text-sm font-semibold text-slate-900 mb-2">Secondary Signals</h4>
              <div className="grid grid-cols-2 gap-3">
                {Object.entries(recommendation.signal_analysis.secondary_signals).map(([key, value]) => (
                  <div key={key} className="bg-slate-50 rounded-lg p-3">
                    <p className="text-xs text-slate-500 font-medium">{key.replace(/_/g, ' ').toUpperCase()}</p>
                    <p className="text-sm font-semibold text-slate-700">{String(value)}</p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Campaign Context */}
        <div className="border border-slate-200 rounded-lg p-5">
          <div className="flex items-center gap-2 mb-4">
            <Target className="w-5 h-5 text-blue-500" />
            <h3 className="text-lg font-bold text-slate-900">Campaign Context</h3>
          </div>

          <div className="grid grid-cols-3 gap-4 mb-4">
            {/* Campaign Metrics */}
            <div className="space-y-2">
              <h4 className="text-sm font-semibold text-slate-700 mb-2">Campaign Metrics</h4>
              <div className="space-y-1.5">
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">Impressions:</span>
                  <span className="font-semibold">{recommendation.context.campaign_metrics.impressions.toLocaleString()}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">Clicks:</span>
                  <span className="font-semibold">{recommendation.context.campaign_metrics.clicks.toLocaleString()}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">CPA:</span>
                  <span className="font-semibold">{formatCurrency(recommendation.context.campaign_metrics.cpa)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">CTR:</span>
                  <span className="font-semibold">{formatMetric(recommendation.context.campaign_metrics.ctr, 3)}%</span>
                </div>
              </div>
            </div>

            {/* Creative Metrics */}
            <div className="space-y-2">
              <h4 className="text-sm font-semibold text-slate-700 mb-2">Creative Health</h4>
              <div className="space-y-1.5">
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">Age:</span>
                  <span className="font-semibold">{recommendation.context.creative_metrics.age_days} days</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">Frequency:</span>
                  <span className="font-semibold">{formatMetric(recommendation.context.creative_metrics.frequency, 1)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">Fatigue Score:</span>
                  <span className="font-semibold">{formatMetric(recommendation.context.creative_metrics.fatigue_score, 1)}%</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">Last Refresh:</span>
                  <span className="font-semibold">{recommendation.context.creative_metrics.last_refresh_days_ago} days ago</span>
                </div>
              </div>
            </div>

            {/* Competitor Signals */}
            <div className="space-y-2">
              <h4 className="text-sm font-semibold text-slate-700 mb-2">Market Context</h4>
              <div className="space-y-1.5">
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">New Competitors:</span>
                  <span className="font-semibold">{recommendation.context.competitor_signals.new_competitors_count}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">Auction Overlap:</span>
                  <span className="font-semibold">{formatMetric(recommendation.context.competitor_signals.auction_overlap_increase, 1)}%</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">Impression Share Lost:</span>
                  <span className="font-semibold">{formatMetric(recommendation.context.competitor_signals.impression_share_lost, 1)}%</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">Avg CPC Change:</span>
                  <span className="font-semibold">{formatMetric(recommendation.context.competitor_signals.avg_cpc_change, 1)}%</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Alternative Actions */}
        {recommendation.alternative_actions?.length > 0 && (
          <div className="border border-slate-200 rounded-lg p-5">
            <h3 className="text-lg font-bold text-slate-900 mb-3">Alternative Actions Considered</h3>
            <div className="space-y-2">
              {recommendation.alternative_actions.map((alt, idx) => (
                <div key={idx} className="flex items-start gap-3 p-3 bg-slate-50 rounded-lg">
                  <div className="flex-1">
                    <p className="font-semibold text-slate-900">
                      {WORKFLOW_LABELS[alt.workflow_type]?.label || alt.workflow_type}
                    </p>
                    <p className="text-sm text-slate-600">{alt.reason}</p>
                  </div>
                  <div className="text-sm font-semibold text-slate-500">
                    {(alt.confidence * 100).toFixed(0)}%
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Human-in-the-Loop Decision */}
        <div className="border-2 border-blue-200 rounded-lg p-5 bg-gradient-to-br from-blue-50 to-white">
          <div className="flex items-center gap-2 mb-4">
            <MessageSquare className="w-5 h-5 text-blue-600" />
            <h3 className="text-lg font-bold text-slate-900">Human Review Required</h3>
          </div>
          
          {!showFeedback ? (
            <>
              <p className="text-slate-600 mb-4">
                Review the AI's reasoning and decide whether to approve or reject this recommendation. 
                Your decisions help the agent learn and improve over time.
              </p>
              <div className="flex gap-3">
                <button
                  onClick={() => handleDecision('approved')}
                  className="flex-1 flex items-center justify-center gap-2 px-6 py-3 bg-green-500 hover:bg-green-600 text-white rounded-lg font-semibold transition-colors"
                >
                  <ThumbsUp className="w-5 h-5" />
                  Approve Recommendation
                </button>
                <button
                  onClick={() => handleDecision('rejected')}
                  className="flex-1 flex items-center justify-center gap-2 px-6 py-3 bg-red-500 hover:bg-red-600 text-white rounded-lg font-semibold transition-colors"
                >
                  <ThumbsDown className="w-5 h-5" />
                  Reject Recommendation
                </button>
              </div>
            </>
          ) : (
            <div className="space-y-4">
              <div className={`flex items-center gap-2 p-3 rounded-lg ${
                decision === 'approved' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
              }`}>
                {decision === 'approved' ? (
                  <CheckCircle2 className="w-5 h-5" />
                ) : (
                  <XCircle className="w-5 h-5" />
                )}
                <span className="font-semibold">
                  Decision: {decision === 'approved' ? 'Approved' : 'Rejected'}
                </span>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-2">
                  Feedback (Optional)
                </label>
                <textarea
                  value={feedback}
                  onChange={(e) => setFeedback(e.target.value)}
                  placeholder="Add any comments about your decision..."
                  className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  rows={3}
                />
              </div>

              <div className="flex gap-3">
                <button
                  onClick={handleSubmit}
                  disabled={submitting}
                  className="flex-1 flex items-center justify-center gap-2 px-6 py-3 bg-blue-500 hover:bg-blue-600 disabled:bg-blue-300 text-white rounded-lg font-semibold transition-colors"
                >
                  {submitting ? (
                    <>
                      <Clock className="w-5 h-5 animate-spin" />
                      Submitting...
                    </>
                  ) : (
                    'Submit Decision'
                  )}
                </button>
                <button
                  onClick={() => {
                    setShowFeedback(false);
                    setDecision(null);
                    setFeedback('');
                  }}
                  disabled={submitting}
                  className="px-6 py-3 border border-slate-300 hover:bg-slate-50 text-slate-700 rounded-lg font-semibold transition-colors"
                >
                  Change Decision
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
