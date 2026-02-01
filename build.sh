#!/bin/bash

# iClippy Build Script
# This script builds the iClippy app and optionally installs it to /Applications

set -e
 
echo "🔨 Building iClippy..."

# Clean previous builds
rm -rf ./build

# Build the app
xcodebuild -project iClippy.xcodeproj \
  -scheme iClippy \
  -configuration Release \
  -derivedDataPath ./build \
  clean build

APP_PATH="./build/Build/Products/Release/iClippy.app"

if [ -d "$APP_PATH" ]; then
    echo "✅ Build successful!"
    echo "📦 App location: $APP_PATH"

    # Ask user if they want to install
    read -p "Install to /Applications? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📥 Installing to /Applications..."

        # Remove old version if it exists
        if [ -d "/Applications/iClippy.app" ]; then
            echo "🗑️  Removing old version..."
            rm -rf "/Applications/iClippy.app"
        fi

        # Copy new version
        cp -r "$APP_PATH" /Applications/
        echo "✅ Installation complete!"
        echo "🚀 Launch iClippy from /Applications or press ⌘⇧V"
    else
        echo "ℹ️  You can manually copy the app from:"
        echo "   $APP_PATH"
    fi
else
    echo "❌ Build failed!"
    exit 1
fi
