import { useState, useEffect, useRef } from 'react';
import { 
  Send, 
  Brain, 
  TrendingUp, 
  AlertTriangle,
  CheckCircle2,
  XCircle,
  Loader2,
  BarChart3,
  Target,
  Users,
  Zap
} from 'lucide-react';
import { recommendationsApi, AnalyzeRequest, DecisionRequest, Recommendation } from '../api/client';

interface Message {
  id: string;
  type: 'user' | 'agent' | 'system';
  content: string;
  recommendation?: Recommendation;
  timestamp: Date;
}

const DEMO_SCENARIOS = [
  { id: 'demo-competitive-pressure', label: 'Competitive Pressure' },
  { id: 'demo-creative-fatigue', label: 'Creative Fatigue' },
  { id: 'demo-audience-saturation', label: 'Audience Saturation' },
  { id: 'demo-winning-campaign', label: 'Winning Campaign' },
  { id: 'demo-multi-signal-problem', label: 'Multi-Signal Problem' }
];

export default function ChatInterface() {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: '1',
      type: 'system',
      content: '👋 Hi! I\'m your Marketing AI **Reasoning Agent**.\n\nI don\'t just recommend actions—I **show you my thinking**. Watch as I:\n\n• 📊 **Analyze** campaign metrics, creative health & competitive signals\n• 🔍 **Identify** root causes and patterns in real-time\n• 💡 **Reason through** alternative workflows\n• ✅ **Recommend** the optimal action with confidence scores\n\n**Try asking:**\n• "Analyze campaign demo-competitive-pressure"\n• "What\'s wrong with demo-creative-fatigue?"',
      timestamp: new Date()
    }
  ]);
  const [input, setInput] = useState('');
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [pendingRecommendation, setPendingRecommendation] = useState<{ messageId: string, rec: Recommendation } | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const addMessage = (message: Omit<Message, 'id' | 'timestamp'>) => {
    const newMessage: Message = {
      ...message,
      id: Date.now().toString(),
      timestamp: new Date()
    };
    setMessages(prev => [...prev, newMessage]);
    return newMessage.id;
  };

  const handleAnalyze = async (campaignId: string) => {
    // User message
    addMessage({
      type: 'user',
      content: `Analyze campaign: ${campaignId}`
    });

    // Thinking message that will be updated
    const thinkingId = addMessage({
      type: 'agent',
      content: '🤔 Initializing analysis...'
    });

    setIsAnalyzing(true);

    try {
      const scenarioName = campaignId.replace('demo-', '');
      const url = `http://localhost:8000/api/stream/analyze?campaign_id=${encodeURIComponent(campaignId)}&scenario_name=${encodeURIComponent(scenarioName)}`;
      
      const response = await fetch(url);
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const reader = response.body?.getReader();
      const decoder = new TextDecoder();

      if (!reader) {
        throw new Error('No response body');
      }

      let buffer = '';
      let currentReasoningId: string | null = null;
      let reasoningContent = '';
      let finalRecommendation: Recommendation | null = null;

      while (true) {
        const { done, value } = await reader.read();
        
        if (done) break;
        
        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          if (!line.trim()) continue;

          try {
            const event = JSON.parse(line);

            switch (event.type) {
              case 'init':
                setMessages(prev => prev.map(m => 
                  m.id === thinkingId 
                    ? { ...m, content: `🚀 ${event.message}` }
                    : m
                ));
                break;

              case 'step':
                // Update thinking message with animated dots and step info
                const dots = ['⚡', '⚡⚡', '⚡⚡⚡'];
                const dotIndex = Math.floor(Date.now() / 500) % dots.length;
                setMessages(prev => prev.map(m => 
                  m.id === thinkingId 
                    ? { ...m, content: `${event.message} ${dots[dotIndex]}\n\n${event.detail || ''}` }
                    : m
                ));
                break;

              case 'step_complete':
                // Remove thinking message and add step completion as clean success message
                setMessages(prev => prev.filter(m => m.id !== thinkingId));
                addMessage({
                  type: 'agent',
                  content: `✅ ${event.message}${event.data ? `\n\n📊 **Data Snapshot:**\n${Object.entries(event.data).map(([k, v]) => `• **${k.replace(/_/g, ' ')}**: ${typeof v === 'number' ? v.toLocaleString() : v}`).join('\n')}` : ''}`
                });
                break;

              case 'reasoning':
                if (!currentReasoningId) {
                  // Create a new reasoning message with special styling
                  currentReasoningId = addMessage({
                    type: 'agent',
                    content: `🧠 **Agent Reasoning:**\n\n${event.content}`
                  });
                  reasoningContent = `🧠 **Agent Reasoning:**\n\n${event.content}`;
                } else {
                  reasoningContent += '\n\n' + event.content;
                  setMessages(prev => prev.map(m => 
                    m.id === currentReasoningId 
                      ? { ...m, content: reasoningContent }
                      : m
                  ));
                }
                break;

              case 'complete':
                // Remove thinking message
                setMessages(prev => prev.filter(m => m.id !== thinkingId));
                
                // Reset reasoning accumulator
                currentReasoningId = null;
                reasoningContent = '';

                // Build final recommendation message and recommendation object
                const recData = event.recommendation;
                const ctx = event.context;
                
                const recommendation: Recommendation = {
                  id: event.recommendation_id,
                  campaign_id: event.campaign_id,
                  workflow_type: recData.workflow_type,
                  confidence_score: recData.confidence,
                  reasoning: recData.reasoning,
                  risk_level: recData.risk_level,
                  alternative_actions: recData.alternatives || [],
                  signal_analysis: {
                    primary_signals: {},
                    secondary_signals: {},
                    root_cause: event.signal_analysis || '',
                    confidence: recData.confidence
                  },
                  context: {
                    campaign_metrics: {
                      impressions: ctx?.campaign_metrics?.impressions || 0,
                      clicks: ctx?.campaign_metrics?.clicks || 0,
                      conversions: ctx?.campaign_metrics?.conversions || 0,
                      spend: ctx?.campaign_metrics?.spend || 0,
                      cpa: ctx?.campaign_metrics?.cpa || 0,
                      ctr: ctx?.campaign_metrics?.ctr || 0,
                      conversion_rate: ctx?.campaign_metrics?.conversion_rate || 0,
                      frequency: ctx?.campaign_metrics?.frequency || 0
                    },
                    creative_metrics: {
                      age_days: ctx?.creative_metrics?.avg_creative_age_days || 0,
                      frequency: ctx?.creative_metrics?.frequency || 0,
                      ctr: ctx?.creative_metrics?.avg_ctr || 0,
                      fatigue_score: ctx?.creative_metrics?.engagement_rate || 0,
                      last_refresh_days_ago: 0
                    },
                    competitor_signals: {
                      total_competitors: ctx?.competitor_signals?.total_competitors || 0,
                      new_entrants_last_week: ctx?.competitor_signals?.new_entrants_last_week || 0,
                      market_activity_change_pct: ctx?.competitor_signals?.market_activity_change_pct || 0,
                      auction_competition_score: ctx?.competitor_signals?.auction_competition_score || 0,
                      avg_competitor_bid_change_pct: ctx?.competitor_signals?.avg_competitor_bid_change_pct || 0,
                      impression_share_lost_to_competitors_pct: ctx?.competitor_signals?.impression_share_lost_to_competitors_pct || 0,
                      competitive_pressure: ctx?.competitor_signals?.competitive_pressure || 'unknown',
                      pressure_reasoning: ctx?.competitor_signals?.pressure_reasoning || ''
                    },
                    lookback_days: ctx?.lookback_days || 30
                  },
                  human_decision: 'NEEDS_REVISION',
                  created_at: event.timestamp
                };

                finalRecommendation = recommendation;

                const finalMessage = buildAnalysisMessage(recommendation);
                const messageId = addMessage({
                  type: 'agent',
                  content: finalMessage,
                  recommendation
                });

                setPendingRecommendation({ messageId, rec: recommendation });
                break;

              case 'error':
                setMessages(prev => prev.filter(m => m.id !== thinkingId));
                addMessage({
                  type: 'system',
                  content: `❌ ${event.message}`
                });
                break;
            }
          } catch (e) {
            console.error('Failed to parse event:', line, e);
          }
        }
      }

    } catch (err: any) {
      setMessages(prev => prev.filter(m => m.id === thinkingId));
      addMessage({
        type: 'system',
        content: `❌ Analysis failed: ${err.message || 'Unknown error'}\n\nMake sure the backend is running: \`uvicorn src.api.main:app --reload\``
      });
    } finally {
      setIsAnalyzing(false);
    }
  };

  const buildAnalysisMessage = (rec: Recommendation): string => {
    const ctx = rec.context;
    
    return `## 📊 Campaign Analysis Complete

### Signal Detection
I've analyzed **${ctx.campaign_metrics.impressions.toLocaleString()} impressions** over the lookback period. Here's what I found:

**Campaign Metrics:**
• CPA: $${ctx.campaign_metrics.cpa.toFixed(2)} (${ctx.campaign_metrics.conversions} conversions from ${ctx.campaign_metrics.clicks.toLocaleString()} clicks)
• CTR: ${(ctx.campaign_metrics.ctr * 100).toFixed(2)}%
• Conversion Rate: ${(ctx.campaign_metrics.conversion_rate * 100).toFixed(2)}%
• Frequency: ${ctx.campaign_metrics.frequency.toFixed(1)} impressions/user

**Creative Health:**
• Age: ${ctx.creative_metrics.age_days} days old
• Fatigue Score: ${(ctx.creative_metrics.fatigue_score * 100).toFixed(0)}%
• Last Refresh: ${ctx.creative_metrics.last_refresh_days_ago} days ago

**Competitive Landscape:**
• New Entrants (7d): ${ctx.competitor_signals.new_entrants_last_week}
• Total Competitors: ${ctx.competitor_signals.total_competitors}
• Auction Competition: ${ctx.competitor_signals.auction_competition_score.toFixed(0)}/100
• Impression Share Lost: ${ctx.competitor_signals.impression_share_lost_to_competitors_pct.toFixed(1)}%
• Competitive Pressure: **${ctx.competitor_signals.competitive_pressure.toUpperCase()}**

---

### 💡 My Recommendation: **${rec.workflow_type}**
**Confidence: ${(rec.confidence_score * 100).toFixed(0)}%** | **Risk: ${rec.risk_level.toUpperCase()}**

${rec.reasoning}

---

### Alternative Considerations
${rec.alternative_actions.length > 0 
  ? rec.alternative_actions.map((alt, i) => 
      `${i + 1}. **${alt.workflow_type}** (${(alt.confidence * 100).toFixed(0)}% confidence)\n   ${alt.reason}`
    ).join('\n\n')
  : 'No significant alternatives at this time.'}

---

**What would you like to do?**`;
  };

  const handleDecision = async (decision: 'approved' | 'rejected') => {
    if (!pendingRecommendation) return;

    const { rec } = pendingRecommendation;

    addMessage({
      type: 'user',
      content: decision === 'approved' 
        ? `✅ Approve ${rec.workflow_type}` 
        : `❌ Reject ${rec.workflow_type}`
    });

    try {
      const decisionRequest: DecisionRequest = {
        decision,
        feedback: undefined,
        decided_by: 'Investor Demo User'
      };

      await recommendationsApi.recordDecision(rec.id, decisionRequest);

      addMessage({
        type: 'agent',
        content: decision === 'approved'
          ? `✅ **Decision Recorded**: ${rec.workflow_type} approved\n\nThe workflow would now execute in production. The system will monitor results and learn from this decision.\n\n**Next Steps:**\n• Workflow execution triggered\n• Monitoring alerts configured\n• Results will be analyzed in 24-48 hours\n\nWant to analyze another campaign?`
          : `📝 **Decision Recorded**: ${rec.workflow_type} rejected\n\nThe system has logged this decision for learning. Over time, the agent learns which patterns lead to rejections and adjusts its recommendations.\n\n**Why rejections matter:**\n• Agent learns your risk tolerance\n• Improves future recommendations\n• Builds trust through transparency\n\nWant to analyze another campaign?`
      });

      setPendingRecommendation(null);

    } catch (err: any) {
      addMessage({
        type: 'system',
        content: `❌ Failed to record decision: ${err.response?.data?.detail || err.message}`
      });
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || isAnalyzing) return;

    const normalizedInput = input.toLowerCase().trim();

    // Check for campaign analysis patterns
    const campaignMatch = normalizedInput.match(/(?:analyze|check|review|what'?s wrong with)\s+(?:campaign\s+)?(demo-[\w-]+)/);
    
    if (campaignMatch) {
      const campaignId = campaignMatch[1];
      setInput('');
      handleAnalyze(campaignId);
      return;
    }

    // Simple fallback
    addMessage({
      type: 'user',
      content: input
    });

    addMessage({
      type: 'agent',
      content: `I can analyze campaigns for you. Try:\n• "Analyze demo-competitive-pressure"\n• "What's wrong with demo-creative-fatigue?"\n\nOr select a scenario below.`
    });

    setInput('');
  };

  const handleScenarioClick = (scenarioId: string) => {
    handleAnalyze(scenarioId);
  };

  return (
    <div className="flex flex-col h-[calc(100vh-180px)] bg-white rounded-xl shadow-lg border border-slate-200">
      {/* Chat Header */}
      <div className="bg-gradient-to-r from-purple-600 to-blue-600 px-6 py-4 border-b border-slate-200">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center">
            <Brain className="w-6 h-6 text-purple-600" />
          </div>
          <div>
            <h2 className="text-lg font-bold text-white">Marketing AI Agent</h2>
            <p className="text-xs text-purple-100">Watch the Agent Reason in Real-Time</p>
          </div>
        </div>
      </div>

      {/* Messages Area */}
      <div className="flex-1 overflow-y-auto p-6 space-y-4">
        {messages.map((message) => (
          <div
            key={message.id}
            className={`flex items-start gap-3 ${
              message.type === 'user' ? 'flex-row-reverse' : ''
            }`}
          >
            {/* Avatar */}
            <div
              className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 ${
                message.type === 'user'
                  ? 'bg-blue-500'
                  : message.type === 'agent'
                  ? 'bg-gradient-to-br from-purple-500 to-pink-500'
                  : 'bg-slate-400'
              }`}
            >
              {message.type === 'user' ? (
                <span className="text-white text-sm font-semibold">U</span>
              ) : message.type === 'agent' ? (
                <Brain className="w-4 h-4 text-white" />
              ) : (
                <AlertTriangle className="w-4 h-4 text-white" />
              )}
            </div>

            {/* Message Content */}
            <div
              className={`flex-1 ${
                message.type === 'user' ? 'text-right' : ''
              }`}
            >
              <div
                className={`inline-block max-w-[85%] rounded-lg px-4 py-3 ${
                  message.type === 'user'
                    ? 'bg-blue-500 text-white'
                    : message.type === 'agent'
                    ? message.content.includes('🧠 **Agent Reasoning:**')
                      ? 'bg-gradient-to-br from-purple-50 to-blue-50 border-2 border-purple-300 shadow-md'
                      : 'bg-slate-50 border border-slate-200'
                    : 'bg-yellow-50 border border-yellow-200'
                }`}
              >
                <div className="text-sm whitespace-pre-wrap markdown-content">
                  {/* Special animated indicator for messages with lightning bolts (analyzing steps) */}
                  {message.content.includes('⚡') && (
                    <div className="flex items-center gap-2 mb-2 animate-pulse">
                      <Loader2 className="w-4 h-4 animate-spin text-blue-600" />
                      <span className="text-blue-700 font-medium">Analyzing...</span>
                    </div>
                  )}
                  
                  {message.content.split('\n').map((line, i) => {
                    // Special highlighting for reasoning header
                    if (line.includes('🧠 **Agent Reasoning:**')) {
                      return (
                        <div key={i} className="flex items-center gap-2 mb-3 pb-2 border-b-2 border-purple-300">
                          <Brain className="w-5 h-5 text-purple-600" />
                          <span className="text-base font-bold text-purple-900">Agent Reasoning</span>
                        </div>
                      );
                    }
                    
                    // Parse markdown-style formatting
                    if (line.startsWith('## ')) {
                      return <h2 key={i} className="text-lg font-bold mt-4 mb-2 text-slate-900">{line.replace('## ', '')}</h2>;
                    }
                    if (line.startsWith('### ')) {
                      return <h3 key={i} className="text-base font-semibold mt-3 mb-2 text-purple-800">{line.replace('### ', '')}</h3>;
                    }
                    if (line.startsWith('#### ')) {
                      return <h4 key={i} className="text-sm font-semibold mt-2 mb-1 text-slate-700">{line.replace('#### ', '')}</h4>;
                    }
                    if (line.startsWith('• ') || line.startsWith('- ')) {
                      return <div key={i} className="ml-3 mb-1 text-slate-700 flex items-start gap-2">
                        <span className="text-purple-500 font-bold">•</span>
                        <span>{line.replace(/^[•-]\s*/, '')}</span>
                      </div>;
                    }
                    if (line.startsWith('**') && line.endsWith('**')) {
                      return <div key={i} className="font-bold text-purple-900 mb-2 mt-2">{line.replace(/\*\*/g, '')}</div>;
                    }
                    if (line.trim() === '---') {
                      return <hr key={i} className="my-3 border-purple-200" />;
                    }
                    if (line.trim() === '') {
                      return <div key={i} className="h-2" />;
                    }
                    
                    // Bold inline text with purple color for reasoning
                    const isReasoningMessage = message.content.includes('🧠 **Agent Reasoning:**');
                    const formatted = line.replace(/\*\*(.+?)\*\*/g, isReasoningMessage 
                      ? '<strong class="text-purple-900">$1</strong>' 
                      : '<strong>$1</strong>');
                    return <div key={i} className={`mb-1 ${isReasoningMessage ? 'text-slate-800' : 'text-slate-700'}`} dangerouslySetInnerHTML={{ __html: formatted }} />;
                  })}
                </div>
              </div>

              {/* Action Buttons for Recommendations */}
              {message.recommendation && pendingRecommendation?.messageId === message.id && (
                <div className="mt-3 flex gap-2 justify-start">
                  <button
                    onClick={() => handleDecision('approved')}
                    className="flex items-center gap-2 px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded-lg font-semibold text-sm transition-colors"
                  >
                    <CheckCircle2 className="w-4 h-4" />
                    Approve
                  </button>
                  <button
                    onClick={() => handleDecision('rejected')}
                    className="flex items-center gap-2 px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-lg font-semibold text-sm transition-colors"
                  >
                    <XCircle className="w-4 h-4" />
                    Reject
                  </button>
                </div>
              )}

              <div className="text-xs text-slate-400 mt-1">
                {message.timestamp.toLocaleTimeString()}
              </div>
            </div>
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      {/* Quick Actions */}
      {!isAnalyzing && !pendingRecommendation && (
        <div className="px-6 py-3 border-t border-slate-200 bg-slate-50">
          <p className="text-xs font-medium text-slate-600 mb-2">Quick Analysis:</p>
          <div className="flex flex-wrap gap-2">
            {DEMO_SCENARIOS.map(scenario => (
              <button
                key={scenario.id}
                onClick={() => handleScenarioClick(scenario.id)}
                className="px-3 py-1.5 bg-white hover:bg-purple-50 border border-slate-200 hover:border-purple-300 rounded-lg text-xs font-medium text-slate-700 hover:text-purple-700 transition-colors"
              >
                {scenario.label}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Input Area */}
      <form onSubmit={handleSubmit} className="border-t border-slate-200 p-4">
        <div className="flex gap-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Try: Analyze demo-competitive-pressure or What's wrong with demo-creative-fatigue?"
            disabled={isAnalyzing}
            className="flex-1 px-4 py-3 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent disabled:bg-slate-100 disabled:text-slate-400"
          />
          <button
            type="submit"
            disabled={isAnalyzing || !input.trim()}
            className="px-6 py-3 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white rounded-lg font-semibold transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
          >
            {isAnalyzing ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                Analyzing
              </>
            ) : (
              <>
                <Send className="w-4 h-4" />
                Send
              </>
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
