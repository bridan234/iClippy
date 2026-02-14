#!/bin/bash

# iClippy Packaging Script
# Builds a Release app bundle and creates zip + dmg artifacts in ./dist

set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$BUILD_DIR/Build/Products/Release/iClippy.app"

echo "Cleaning previous build artifacts..."
rm -rf "$BUILD_DIR"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "Building iClippy..."
xcodebuild \
    -project iClippy.xcodeproj \
    -scheme iClippy \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    -destination 'generic/platform=macOS'

if [ ! -d "$APP_PATH" ]; then
    echo "Build succeeded but app bundle not found at $APP_PATH"
    exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "0.0.0")
BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "0")
ARCHIVE_NAME="iClippy-$VERSION-$BUILD"

echo "Creating zip..."
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$DIST_DIR/$ARCHIVE_NAME.zip"

echo "Creating dmg..."
hdiutil create -volname "iClippy" -srcfolder "$APP_PATH" -ov -format UDZO "$DIST_DIR/$ARCHIVE_NAME.dmg"

echo "Package ready in $DIST_DIR"
