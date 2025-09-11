#!/bin/bash

# School Bus System - Deployment Script for Render
# This script builds the frontend and backend for production deployment

echo "🚀 Starting School Bus System deployment..."

# Install dependencies
echo "📦 Installing dependencies..."
npm run install:all

# Build frontend (outputs to backend/dist/public)
echo "🎨 Building frontend..."
cd frontend
npm run build
cd ..

# Build backend (TypeScript to JavaScript)
echo "⚙️ Building backend..."
cd backend
npm run build
cd ..

echo "✅ Build complete! Ready for deployment."
echo "Frontend assets: backend/dist/public/"
echo "Backend compiled: backend/dist/"

# List what was built
echo "📁 Built files:"
ls -la backend/dist/
echo "📁 Frontend assets:"
ls -la backend/dist/public/ 2>/dev/null || echo "No frontend assets found"

echo "🎉 Deployment preparation complete!"