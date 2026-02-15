# Marketing Agent Frontend

Modern React frontend for the Marketing Agent POC, showcasing AI reasoning capabilities with a clean human-in-the-loop approval interface.

## Features

- **🎯 Demo Scenarios**: 5 predefined campaign scenarios demonstrating different reasoning patterns
- **🧠 AI Reasoning Visualization**: Clear display of how the agent analyzes context and reaches conclusions
- **✅ Human-in-the-Loop**: Approve/reject recommendations with optional feedback
- **📊 Context Display**: Campaign metrics, creative health, and competitor signals
- **📝 Decision History**: Track all recommendations and human decisions
- **⚡ Real-time Updates**: Instant feedback and state management

## Tech Stack

- **React 18** - Modern UI library with hooks
- **TypeScript** - Type-safe development
- **Vite** - Lightning-fast dev server and build tool
- **TailwindCSS** - Utility-first styling
- **Axios** - HTTP client for API communication
- **Lucide React** - Beautiful icon library

## Quick Start

### Prerequisites

- Node.js 18+ installed
- Backend API running at `http://localhost:8000`

### Installation

```bash
# Install dependencies
npm install

# Start dev server
npm run dev
```

The frontend will be available at `http://localhost:3000`

### Using the Launcher Scripts

**Windows:**
```powershell
.\start_frontend.ps1
```

**Mac/Linux:**
```bash
./start_frontend.sh
```

## Project Structure

```
frontend/
├── src/
│   ├── api/
│   │   └── client.ts          # API client and type definitions
│   ├── components/
│   │   ├── ScenarioSelector.tsx       # Demo scenario selection
│   │   ├── RecommendationView.tsx     # Main recommendation display
│   │   └── RecommendationHistory.tsx  # Decision tracking
│   ├── App.tsx                # Main application component
│   ├── main.tsx               # Application entry point
│   └── index.css              # Global styles
├── index.html                 # HTML template
├── package.json              # Dependencies
├── vite.config.ts            # Vite configuration
├── tailwind.config.js        # Tailwind configuration
└── tsconfig.json             # TypeScript configuration
```

## Demo Scenarios

The frontend includes 5 predefined scenarios that showcase different reasoning patterns:

1. **🎯 Competitive Pressure** - External market forces causing CPA increase
2. **🎨 Creative Fatigue** - Old creatives losing effectiveness
3. **👥 Audience Saturation** - Audience exhaustion from high frequency
4. **✨ Winning Campaign** - Everything working well (test restraint)
5. **🔍 Multi-Signal Problem** - Complex situation requiring prioritization

## API Integration

The frontend communicates with the FastAPI backend through these endpoints:

- `POST /api/recommendations/analyze` - Trigger agent analysis
- `GET /api/recommendations/{id}` - Get recommendation details
- `POST /api/recommendations/{id}/decision` - Record human decision
- `GET /api/recommendations/` - List all recommendations

API configuration is in `src/api/client.ts` with full TypeScript types matching the backend schemas.

## Components Overview

### ScenarioSelector
- Displays 5 demo scenarios with descriptions
- Triggers agent analysis when "Analyze Campaign" is clicked
- Shows loading state during analysis
- Error handling with helpful messages

### RecommendationView
- **Header**: Workflow type, confidence score, risk level
- **AI Reasoning**: Full explanation of the agent's logic
- **Signal Analysis**: Primary/secondary signals and root cause
- **Campaign Context**: Detailed metrics across all dimensions
- **Alternative Actions**: Other options the agent considered
- **Human Review**: Approve/reject buttons with optional feedback

### RecommendationHistory
- Chronological list of all recommendations
- Shows decision status (approved/rejected/pending)
- Displays confidence scores and timestamps
- Includes human feedback if provided

## Building for Production

```bash
# Create production build
npm run build

# Preview production build
npm run preview
```

The build output will be in the `dist/` directory.

## Development Tips

### Hot Reload
Vite provides instant hot module replacement (HMR). Save any file and see changes immediately without losing application state.

### Type Safety
All API responses are typed. If the backend schema changes, TypeScript will catch mismatches at compile time.

### Styling
This project uses Tailwind CSS utility classes. See [tailwind.config.js](tailwind.config.js) for custom theme extensions.

### API Proxy
Vite proxies `/api` requests to `http://localhost:8000` (configured in [vite.config.ts](vite.config.ts)). This avoids CORS issues during development.

## Customization

### Adding New Scenarios
Edit `src/components/ScenarioSelector.tsx`:

```typescript
const DEMO_SCENARIOS: Scenario[] = [
  {
    id: 'my_scenario',
    name: '🎯 My Scenario',
    description: 'What this scenario demonstrates',
    expectedOutcome: 'What the agent should recommend',
    campaign_id: 'demo-my-scenario'
  }
];
```

### Changing Colors
Edit `tailwind.config.js` to customize the color scheme:

```javascript
theme: {
  extend: {
    colors: {
      primary: { /* your colors */ },
      success: { /* your colors */ },
    }
  }
}
```

### Adding Metrics
To display additional metrics, update:
1. Types in `src/api/client.ts`
2. Display logic in `src/components/RecommendationView.tsx`

## Troubleshooting

**Frontend won't start:**
- Check Node.js version: `node --version` (need 18+)
- Delete `node_modules` and reinstall: `rm -rf node_modules && npm install`

**Can't connect to backend:**
- Verify backend is running: `http://localhost:8000/health`
- Check proxy configuration in `vite.config.ts`
- Look for CORS errors in browser console

**TypeScript errors:**
- Ensure types match backend schemas
- Run `npm run lint` to check for issues

**Build fails:**
- Clear Vite cache: `rm -rf node_modules/.vite`
- Check for missing dependencies: `npm install`

## License

This is a POC (Proof of Concept) project for demonstrating AI agent capabilities.
