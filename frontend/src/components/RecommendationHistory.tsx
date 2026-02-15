import { Clock, CheckCircle2, XCircle, AlertCircle } from 'lucide-react';
import { Recommendation } from '../api/client';

interface Props {
  recommendations: Recommendation[];
}

const WORKFLOW_LABELS: Record<string, { label: string; icon: string }> = {
  'BID_ADJUSTMENT': { label: 'Bid Adjustment', icon: '💰' },
  'CREATIVE_REFRESH': { label: 'Creative Refresh', icon: '🎨' },
  'AUDIENCE_EXPANSION': { label: 'Audience Expansion', icon: '👥' },
  'PAUSE_CAMPAIGN': { label: 'Pause Campaign', icon: '⏸️' },
  'CONTINUE_MONITORING': { label: 'Continue Monitoring', icon: '👁️' },
};

export default function RecommendationHistory({ recommendations }: Props) {
  const formatDate = (dateString: string): string => {
    return new Date(dateString).toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const getDecisionIcon = (decision?: string) => {
    switch (decision) {
      case 'APPROVED':
        return <CheckCircle2 className="w-5 h-5 text-green-600" />;
      case 'REJECTED':
        return <XCircle className="w-5 h-5 text-red-600" />;
      case 'NEEDS_REVISION':
        return <AlertCircle className="w-5 h-5 text-yellow-600" />;
      default:
        return <Clock className="w-5 h-5 text-slate-400" />;
    }
  };

  const getDecisionBadge = (decision?: string) => {
    switch (decision) {
      case 'APPROVED':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'REJECTED':
        return 'bg-red-100 text-red-800 border-red-200';
      case 'NEEDS_REVISION':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      default:
        return 'bg-slate-100 text-slate-600 border-slate-200';
    }
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <h2 className="text-xl font-bold text-slate-900 mb-4">Decision History</h2>
      <div className="space-y-3">
        {recommendations.map((rec) => {
          const workflow = WORKFLOW_LABELS[rec.workflow_type] || { 
            label: rec.workflow_type, 
            icon: '⚡' 
          };
          
          return (
            <div
              key={rec.id}
              className="border border-slate-200 rounded-lg p-4 hover:border-blue-200 hover:shadow-sm transition-all"
            >
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-3">
                  <span className="text-2xl">{workflow.icon}</span>
                  <div>
                    <p className="font-semibold text-slate-900">{workflow.label}</p>
                    <p className="text-xs text-slate-500">{rec.campaign_id}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <div className={`px-3 py-1 rounded-full border text-xs font-semibold ${getDecisionBadge(rec.human_decision)}`}>
                    {rec.human_decision || 'PENDING'}
                  </div>
                  {getDecisionIcon(rec.human_decision)}
                </div>
              </div>
              
              <p className="text-sm text-slate-600 mb-2 line-clamp-2">
                {rec.reasoning.split('\n')[0]}
              </p>
              
              <div className="flex items-center justify-between text-xs text-slate-500">
                <span>Confidence: {(rec.confidence_score * 100).toFixed(0)}%</span>
                <span>{formatDate(rec.created_at)}</span>
              </div>
              
              {rec.decision_feedback && (
                <div className="mt-2 p-2 bg-slate-50 rounded text-xs text-slate-700">
                  <span className="font-semibold">Feedback: </span>
                  {rec.decision_feedback}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
