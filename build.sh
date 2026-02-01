#!/bin/bash

# iClippy Build Script
# Builds and runs the iClippy app

set -e  # Exit on error

echo "🧹 Cleaning previous builds..."
rm -rf ./build

echo "🔨 Building iClippy..."
xcodebuild \
    -project iClippy.xcodeproj \
    -scheme iClippy \
    -configuration Release \
    -derivedDataPath ./build \
    -destination 'generic/platform=macOS'

APP_PATH="./build/Build/Products/Release/iClippy.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Build succeeded but app bundle not found at $APP_PATH"
    exit 1
fi

echo "🛑 Stopping any running instances..."
pkill -x iClippy 2>/dev/null || true

echo "🚀 Launching iClippy..."
if ! open "$APP_PATH"; then
    echo "❌ Launch failed (LaunchServices error -600)."
    echo "🔎 Gatekeeper assessment:"
    spctl -a -vv "$APP_PATH" || true
    echo "💡 Try launching from Finder or check System Settings > Privacy & Security."
    exit 1
fi

echo "✅ Done! iClippy is now running in your menu bar."
