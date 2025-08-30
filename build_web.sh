#!/bin/bash

echo "🚀 Building AutoRamos Pro for GitHub Pages..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for web
echo "🔨 Building for web..."
flutter build web --base-href="/subir_imagenes/" --release

echo "✅ Build completed!"
echo "📂 Build files are in: build/web/"
echo "🌐 To test locally, serve the build/web directory"
echo ""
echo "Next steps:"
echo "1. Commit and push changes to trigger GitHub Actions"
echo "2. Enable GitHub Pages in repository settings"
echo "3. Visit: https://joseramos6.github.io/subir_imagenes/"
