#!/bin/bash

# iClippy Release Script
# Builds, signs, notarizes, packages, and creates a GitHub release.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$BUILD_DIR/Build/Products/Release/iClippy.app"

DEVELOPER_ID_APP="${DEVELOPER_ID_APP:-}"
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
APPLE_ID="${APPLE_ID:-}"
APPLE_ID_PASSWORD="${APPLE_ID_PASSWORD:-}"
TEAM_ID="${TEAM_ID:-$DEVELOPMENT_TEAM}"

if [ -z "$DEVELOPER_ID_APP" ]; then
    echo "DEVELOPER_ID_APP is required (e.g., \"Developer ID Application: Your Name (TEAMID)\")."
    exit 1
fi

if [ -z "$DEVELOPMENT_TEAM" ]; then
    echo "DEVELOPMENT_TEAM is required (your 10-character Team ID)."
    exit 1
fi

if [ -z "$NOTARY_PROFILE" ]; then
    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_ID_PASSWORD" ] || [ -z "$TEAM_ID" ]; then
        echo "Notarization requires NOTARY_PROFILE or APPLE_ID + APPLE_ID_PASSWORD + TEAM_ID."
        exit 1
    fi
fi

echo "Cleaning previous build artifacts..."
rm -rf "$BUILD_DIR"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "Building (Release, signed)..."
xcodebuild \
    -project iClippy.xcodeproj \
    -scheme iClippy \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    -destination 'generic/platform=macOS' \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="$DEVELOPER_ID_APP" \
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"

if [ ! -d "$APP_PATH" ]; then
    echo "Build succeeded but app bundle not found at $APP_PATH"
    exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$APP_PATH/Contents/Info.plist")
ARCHIVE_NAME="iClippy-$VERSION-$BUILD"
ZIP_PATH="$DIST_DIR/$ARCHIVE_NAME.zip"
DMG_PATH="$DIST_DIR/$ARCHIVE_NAME.dmg"

echo "Verifying code signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "Creating zip..."
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Creating dmg..."
hdiutil create -volname "iClippy" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH"

echo "Notarizing dmg..."
if [ -n "$NOTARY_PROFILE" ]; then
    xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
else
    xcrun notarytool submit "$DMG_PATH" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$TEAM_ID" --wait
fi

echo "Stapling dmg..."
xcrun stapler staple "$DMG_PATH"

echo "Creating GitHub release..."
TAG="v$VERSION"
if git rev-parse "$TAG" >/dev/null 2>&1; then
    TAG="v$VERSION-$BUILD"
fi

gh release create "$TAG" "$DMG_PATH" "$ZIP_PATH" \
    --title "iClippy $VERSION" \
    --notes "Release $VERSION ($BUILD)" \
    --target main

echo "Release complete: $TAG"
