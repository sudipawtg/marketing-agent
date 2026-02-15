import { useState } from 'react';
import { Brain, TrendingUp, AlertCircle, CheckCircle, MessageSquare, LayoutGrid } from 'lucide-react';
import ScenarioSelector from './components/ScenarioSelector';
import RecommendationView from './components/RecommendationView';
import RecommendationHistory from './components/RecommendationHistory';
import ChatInterface from './components/ChatInterface';
import { Recommendation } from './api/client';

type ViewMode = 'chat' | 'structured';

function App() {
  const [viewMode, setViewMode] = useState<ViewMode>('chat');
  const [currentRecommendation, setCurrentRecommendation] = useState<Recommendation | null>(null);
  const [loading, setLoading] = useState(false);
  const [history, setHistory] = useState<Recommendation[]>([]);

  const handleAnalysisComplete = (recommendation: Recommendation) => {
    setCurrentRecommendation(recommendation);
    setHistory(prev => [recommendation, ...prev]);
  };

  const handleDecisionComplete = () => {
    setCurrentRecommendation(null);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-blue-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
                <Brain className="w-6 h-6 text-white" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-slate-900">Marketing Agent POC</h1>
                <p className="text-sm text-slate-500">AI-Powered Campaign Reasoning with Human Oversight</p>
              </div>
            </div>
            <div className="flex items-center gap-6">
              <div className="flex items-center gap-2 px-4 py-2 bg-green-50 rounded-lg">
                <CheckCircle className="w-5 h-5 text-green-600" />
                <span className="text-sm font-medium text-green-900">Ready</span>
              </div>
              
              {/* View Mode Toggle */}
              <div className="flex items-center gap-1 bg-slate-100 rounded-lg p-1">
                <button
                  onClick={() => setViewMode('chat')}
                  className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                    viewMode === 'chat'
                      ? 'bg-white text-purple-700 shadow-sm'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  <MessageSquare className="w-4 h-4" />
                  Chat View
                </button>
                <button
                  onClick={() => setViewMode('structured')}
                  className={`flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                    viewMode === 'structured'
                      ? 'bg-white text-purple-700 shadow-sm'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  <LayoutGrid className="w-4 h-4" />
                  Structured View
                </button>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-6 py-8">
        {viewMode === 'chat' ? (
          /* Chat Interface */
          <ChatInterface />
        ) : (
          /* Structured View */
          <>
            {/* Info Banner */}
            <div className="mb-6 bg-blue-50 border border-blue-200 rounded-lg p-4">
              <div className="flex items-start gap-3">
                <AlertCircle className="w-5 h-5 text-blue-600 mt-0.5" />
                <div className="flex-1">
                  <h3 className="text-sm font-semibold text-blue-900 mb-1">
                    How This Works
                  </h3>
                  <p className="text-sm text-blue-700">
                    Select a campaign scenario below. The agent will analyze campaign metrics, creative performance, 
                    and competitor activity using LangGraph workflows. It will show its <strong>reasoning process</strong> and 
                    recommend a specific workflow action. You'll see the full context and can <strong>approve or reject</strong> 
                    each recommendation.
                  </p>
                </div>
              </div>
            </div>

            {/* Scenario Selector */}
            <div className="mb-8">
              <ScenarioSelector 
                onAnalysisComplete={handleAnalysisComplete}
                setLoading={setLoading}
                loading={loading}
              />
            </div>

            {/* Recommendation View (if available) */}
            {currentRecommendation && (
              <div className="mb-8">
                <RecommendationView 
                  recommendation={currentRecommendation}
                  onDecisionComplete={handleDecisionComplete}
                />
              </div>
            )}

            {/* History */}
            {history.length > 0 && (
              <RecommendationHistory recommendations={history} />
            )}

            {/* Empty State */}
            {!currentRecommendation && history.length === 0 && (
              <div className="text-center py-16">
                <div className="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <TrendingUp className="w-8 h-8 text-slate-400" />
                </div>
                <h3 className="text-lg font-medium text-slate-900 mb-2">
                  Ready to Demonstrate AI Reasoning
                </h3>
                <p className="text-slate-500 max-w-md mx-auto">
                  Select a campaign scenario above to see how the agent analyzes context, 
                  identifies root causes, and recommends specific workflow actions.
                </p>
              </div>
            )}
          </>
        )}
      </main>
    </div>
  );
}

export default App;
