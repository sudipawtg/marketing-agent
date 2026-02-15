#!/bin/bash

echo "🚀 Marketing Agent Frontend - Starting Dev Server"
echo "================================================="
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "✗ Node.js not found. Please install Node.js 18+ from https://nodejs.org"
    exit 1
fi

NODE_VERSION=$(node --version)
echo "✓ Node.js detected: $NODE_VERSION"

# Navigate to frontend directory
cd "$(dirname "$0")/frontend" || exit

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo ""
    echo "📦 Installing dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        echo "✗ Failed to install dependencies"
        exit 1
    fi
    echo "✓ Dependencies installed"
fi

echo ""
echo "🎨 Starting Vite dev server..."
echo ""
echo "Frontend will be available at: http://localhost:3000"
echo "Make sure the backend is running at: http://localhost:8000"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

npm run dev
