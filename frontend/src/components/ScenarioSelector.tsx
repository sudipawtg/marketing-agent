import { useState } from 'react';
import { Play, Loader2, Sparkles } from 'lucide-react';
import { recommendationsApi, AnalyzeRequest, Recommendation } from '../api/client';

interface Scenario {
  id: string;
  name: string;
  description: string;
  expectedOutcome: string;
  campaign_id: string;
}

const DEMO_SCENARIOS: Scenario[] = [
  {
    id: 'competitive_pressure',
    name: '🎯 Competitive Pressure',
    description: 'CPA increased 32% but creative performing well. Market competition intensified.',
    expectedOutcome: 'Agent should recommend BID_ADJUSTMENT, not creative changes',
    campaign_id: 'demo-competitive-pressure'
  },
  {
    id: 'creative_fatigue',
    name: '🎨 Creative Fatigue',
    description: 'CTR dropped 38%, creatives 42 days old, high ad frequency',
    expectedOutcome: 'Agent should recommend CREATIVE_REFRESH',
    campaign_id: 'demo-creative-fatigue'
  },
  {
    id: 'audience_saturation',
    name: '👥 Audience Saturation',
    description: 'High frequency (8.5), declining performance, audience exhaustion',
    expectedOutcome: 'Agent should recommend AUDIENCE_EXPANSION',
    campaign_id: 'demo-audience-saturation'
  },
  {
    id: 'winning_campaign',
    name: '✨ Winning Campaign',
    description: 'All metrics improving, CPA down 15%, CTR up 12%',
    expectedOutcome: 'Agent should recommend CONTINUE_MONITORING (don\'t break what works)',
    campaign_id: 'demo-winning-campaign'
  },
  {
    id: 'multi_signal_problem',
    name: '🔍 Multi-Signal Problem',
    description: 'Both creative fatigue AND competitive pressure. Requires prioritization.',
    expectedOutcome: 'Agent must analyze which issue is primary and explain reasoning',
    campaign_id: 'demo-multi-signal'
  }
];

interface Props {
  onAnalysisComplete: (recommendation: Recommendation) => void;
  setLoading: (loading: boolean) => void;
  loading: boolean;
}

export default function ScenarioSelector({ onAnalysisComplete, setLoading, loading }: Props) {
  const [selectedScenario, setSelectedScenario] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleAnalyze = async (scenario: Scenario) => {
    setLoading(true);
    setError(null);
    setSelectedScenario(scenario.id);

    try {
      const request: AnalyzeRequest = {
        campaign_id: scenario.campaign_id,
        lookback_days: 7,
        scenario_name: scenario.id
      };
      
      const recommendation = await recommendationsApi.analyze(request);
      onAnalysisComplete(recommendation);
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Failed to analyze campaign. Make sure the backend is running.');
      console.error('Analysis error:', err);
    } finally {
      setLoading(false);
      setSelectedScenario(null);
    }
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <div className="flex items-center gap-3 mb-6">
        <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-pink-500 rounded-lg flex items-center justify-center">
          <Sparkles className="w-5 h-5 text-white" />
        </div>
        <div>
          <h2 className="text-xl font-bold text-slate-900">Demo Scenarios</h2>
          <p className="text-sm text-slate-500">Select a campaign scenario to see AI reasoning in action</p>
        </div>
      </div>

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg">
          <p className="text-sm text-red-800">{error}</p>
          <p className="text-xs text-red-600 mt-1">
            Tip: Run <code className="bg-red-100 px-1 rounded">uvicorn src.api.main:app --reload</code> in the backend
          </p>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {DEMO_SCENARIOS.map((scenario) => (
          <div
            key={scenario.id}
            className="border border-slate-200 rounded-lg p-4 hover:border-blue-300 hover:shadow-md transition-all duration-200"
          >
            <h3 className="text-lg font-semibold text-slate-900 mb-2">
              {scenario.name}
            </h3>
            <p className="text-sm text-slate-600 mb-3 min-h-[40px]">
              {scenario.description}
            </p>
            <div className="bg-slate-50 rounded p-3 mb-4">
              <p className="text-xs text-slate-500 font-medium mb-1">Expected Reasoning:</p>
              <p className="text-xs text-slate-700">{scenario.expectedOutcome}</p>
            </div>
            <button
              onClick={() => handleAnalyze(scenario)}
              disabled={loading}
              className="w-full flex items-center justify-center gap-2 px-4 py-2 bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-lg font-medium hover:from-blue-600 hover:to-purple-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200"
            >
              {loading && selectedScenario === scenario.id ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Analyzing...
                </>
              ) : (
                <>
                  <Play className="w-4 h-4" />
                  Analyze Campaign
                </>
              )}
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}
