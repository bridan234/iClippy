#!/bin/bash

# iClippy Packaging Script
# Builds the app and creates a drag-to-install .dmg plus a .zip in ./dist
#
# Env: SIGN_IDENTITY  passed through to make-app.sh (defaults to ad-hoc "-")

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$DIST_DIR/iClippy.app"

echo "Cleaning previous build artifacts..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

"$ROOT_DIR/make-app.sh" "$DIST_DIR"

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$APP_PATH/Contents/Info.plist")
ARCHIVE_NAME="iClippy-$VERSION-$BUILD"

echo "Creating zip..."
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$DIST_DIR/$ARCHIVE_NAME.zip"

echo "Staging dmg contents..."
STAGE_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGE_DIR"' EXIT
ditto "$APP_PATH" "$STAGE_DIR/iClippy.app"
ln -s /Applications "$STAGE_DIR/Applications"

# iClippy is signed ad-hoc rather than with a Developer ID, so a download from
# GitHub arrives quarantined and Gatekeeper blocks the first open. Ship the fix
# next to the app instead of leaving people stuck on "unidentified developer".
cat > "$STAGE_DIR/READ ME FIRST.txt" <<'INSTRUCTIONS'
Installing iClippy
==================

1. Drag iClippy.app onto the Applications folder in this window.

2. Open Terminal and run this line (copy/paste it):

       xattr -dr com.apple.quarantine /Applications/iClippy.app

   iClippy is signed ad-hoc rather than with a paid Apple Developer ID, so
   macOS quarantines it after download. The command above clears that flag.

   If you skip step 2, the first launch is blocked with "Apple could not verify
   iClippy is free of malware". You can also allow it under
   System Settings -> Privacy & Security -> Open Anyway.

3. Open iClippy from Applications (once).

   On that first launch iClippy installs a login agent for the current user at
   ~/Library/LaunchAgents/com.iclippy.app.plist, so from then on it starts
   automatically at every login and is restarted if it ever crashes or is
   force-quit. Nothing else to configure.

4. For automatic pasting, grant Accessibility permission when prompted:
   System Settings -> Privacy & Security -> Accessibility -> enable iClippy.
   Without it, iClippy still copies items; you paste with Cmd-V yourself.

Using it
--------
  Left-click the scissors icon in the menu bar, or press Cmd-Shift-V.
  Right-click the icon for "Start at Login" and "Quit iClippy".

Uninstalling
------------
  Right-click the menu bar icon -> Quit iClippy, then:

      rm -f ~/Library/LaunchAgents/com.iclippy.app.plist
      launchctl bootout gui/$(id -u)/com.iclippy.app 2>/dev/null
      rm -rf /Applications/iClippy.app
INSTRUCTIONS

echo "Creating dmg..."
DMG_PATH="$DIST_DIR/$ARCHIVE_NAME.dmg"
hdiutil create \
    -volname "iClippy $VERSION" \
    -srcfolder "$STAGE_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

echo "Package ready in $DIST_DIR"
ls -lh "$DIST_DIR"/*.dmg "$DIST_DIR"/*.zip
