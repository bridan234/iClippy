#!/bin/bash

# iClippy Build Script
# Builds and runs iClippy from source. Requires only the Xcode Command Line Tools.

set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="$ROOT_DIR/dist/iClippy.app"

"$ROOT_DIR/make-app.sh" "$ROOT_DIR/dist"

echo "🛑 Stopping any running instances..."
pkill -x iClippy 2>/dev/null || true
sleep 1

echo "🚀 Launching iClippy..."
if ! open "$APP_PATH"; then
    echo "❌ Launch failed (LaunchServices error -600)."
    echo "🔎 Gatekeeper assessment:"
    spctl -a -vv "$APP_PATH" || true
    echo "💡 Try launching from Finder or check System Settings > Privacy & Security."
    exit 1
fi

echo "✅ Done! iClippy is now running in your menu bar."
echo "ℹ️  Running from $APP_PATH — install with ./package.sh or drag it to /Applications"
echo "   for a permanent setup, since the launch agent points at wherever it is run from."
