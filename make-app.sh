#!/bin/bash

# iClippy App Bundle Builder
# Builds iClippy.app from source with Swift Package Manager.
#
# Unlike build.sh's original xcodebuild path, this only needs the Xcode Command
# Line Tools, so it works on a plain machine and on CI runners.
#
# Usage: ./make-app.sh [output-dir]      (default output dir: ./dist)
# Env:   SIGN_IDENTITY   codesign identity; defaults to "-" (ad-hoc)
#        SKIP_UNIVERSAL  set to 1 to build only for the host architecture

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="${1:-$ROOT_DIR/dist}"
APP_PATH="$OUT_DIR/iClippy.app"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"

cd "$ROOT_DIR"

BIN_DIR=""
if [ "${SKIP_UNIVERSAL:-0}" != "1" ]; then
    echo "🔨 Building iClippy (universal: arm64 + x86_64)..."
    if swift build -c release --arch arm64 --arch x86_64; then
        BIN_DIR="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"
    else
        echo "⚠️  Universal build failed — falling back to a host-only build."
    fi
fi

if [ -z "$BIN_DIR" ]; then
    echo "🔨 Building iClippy (host architecture only)..."
    swift build -c release
    BIN_DIR="$(swift build -c release --show-bin-path)"
fi

BIN_PATH="$BIN_DIR/iClippy"
if [ ! -f "$BIN_PATH" ]; then
    echo "❌ Build finished but no executable at $BIN_PATH"
    exit 1
fi

echo "📦 Assembling app bundle..."
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
cp "$ROOT_DIR/Sources/Info.plist" "$APP_PATH/Contents/Info.plist"
cp "$BIN_PATH" "$APP_PATH/Contents/MacOS/iClippy"
printf 'APPL????' > "$APP_PATH/Contents/PkgInfo"

echo "🔑 Signing with identity: $SIGN_IDENTITY"
codesign --force --sign "$SIGN_IDENTITY" --identifier com.iclippy.app --timestamp=none "$APP_PATH"
codesign --verify "$APP_PATH"

echo "✅ Built $APP_PATH ($(lipo -archs "$APP_PATH/Contents/MacOS/iClippy"))"
