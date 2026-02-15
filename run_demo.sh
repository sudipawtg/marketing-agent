#!/bin/bash
# Run Demo - Quick Launcher (Unix/Mac)
# Usage: ./run_demo.sh [scenario_name]

echo -e "\n🤖 Marketing Agent Demo Launcher\n"

# Check if virtual environment is activated
if [ -z "$VIRTUAL_ENV" ]; then
    echo "⚠ Virtual environment not activated. Activating..."
    source venv/bin/activate
fi

# Check if API key is set
if [ ! -f .env ]; then
    echo "❌ .env file not found. Creating from template..."
    cp .env.example .env
    echo "⚠ Please edit .env and add your OpenAI or Anthropic API key!"
    echo "   Then run this script again."
    exit 1
fi

if ! grep -q "^OPENAI_API_KEY=sk-\|^ANTHROPIC_API_KEY=sk-" .env; then
    echo "⚠ WARNING: No API key found in .env file"
    echo "  Demo will run with mock data only (no LLM reasoning)"
    echo "  Add OPENAI_API_KEY or ANTHROPIC_API_KEY to .env for full demo"
    sleep 2
fi

# Run the demo
echo "🚀 Starting demo..."
echo

if [ $# -gt 0 ]; then
    python -m src.demo.run_demo "$1"
else
    python -m src.demo.run_demo
fi

echo -e "\n✨ Demo complete!\n"
