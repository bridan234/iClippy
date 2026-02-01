# iClippy Troubleshooting Guide

## Build Issues

### Error: "No such module 'Magnet'"

**Solution:**
1. Open the project in Xcode
2. Go to **File > Packages > Resolve Package Versions**
3. Wait for Swift Package Manager to download dependencies
4. Clean build: **Product > Clean Build Folder** (⌘⇧K)
5. Rebuild: **Product > Build** (⌘B)

### Error: "Command line tools not found"

**Solution:**
```bash
xcode-select --install
```

### Error: "xcrun: error: unable to find utility 'xcodebuild'"

**Solution:**
1. Install Xcode from Mac App Store
2. Open Xcode and accept license agreement
3. Set command line tools:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   ```

## Runtime Issues

### iClippy doesn't appear in menu bar

**Check if app is running:**
```bash
ps aux | grep iClippy
```

**Solutions:**
1. Quit and relaunch the app
2. Check Console.app for crash logs
3. Grant accessibility permissions (see below)
4. Restart your Mac

### Global hotkey (⌘⇧V) doesn't work

**Solution 1: Grant Accessibility Permissions**
1. Go to **System Settings > Privacy & Security > Accessibility**
2. Find **iClippy** in the list
3. Toggle it ON
4. If not in list, click **+** and add `/Applications/iClippy.app`

**Solution 2: Check for conflicts**
1. Open **System Settings > Keyboard > Keyboard Shortcuts**
2. Search for any conflicting shortcuts using ⌘⇧V
3. Disable or change the conflicting shortcut

**Solution 3: Change the hotkey**
Edit `Sources/AppDelegate.swift` and change the key combo:
```swift
// Try Option + V instead
if let keyCombo = KeyCombo(key: .v, cocoaModifiers: [.option]) {
```

### Window doesn't open when pressing hotkey

**Check accessibility permissions:**
```bash
# This command checks if accessibility is enabled
osascript -e 'tell application "System Events" to get value of attribute "AXTrusted" of application process "iClippy"'
```

**Solutions:**
1. Restart iClippy after granting permissions
2. Try clicking menu bar icon instead
3. Check Console.app for error messages

### Auto-paste doesn't work

**Symptoms:** Window closes but content doesn't paste

**Solutions:**

1. **Grant Accessibility Permissions** (required for CGEvent)
   - System Settings > Privacy & Security > Accessibility
   - Toggle iClippy ON

2. **Check if target app is blocking paste**
   - Some secure apps (password managers, banking apps) block simulated keypresses
   - Try pasting into TextEdit or Notes first

3. **Use manual paste instead**
   - Click the copy icon instead of Enter
   - Manually paste with ⌘V

4. **Check for security software**
   - Some antivirus/security apps block CGEvent
   - Add iClippy to allow list

### Clipboard history is empty

**Check if monitoring is working:**
1. Copy some text
2. Wait 1 second
3. Press ⌘⇧V to open iClippy
4. Check if item appears

**Solutions:**

1. **Restart the app**
   - Right-click menu bar icon > Quit
   - Relaunch from Applications

2. **Check for errors in Console.app**
   - Open Console.app
   - Filter for "iClippy"
   - Look for error messages

3. **Check storage permissions**
   ```bash
   ls -la ~/Library/Application\ Support/iClippy/
   ```
   Should show `clipboard_history.json`

4. **Reset history file**
   ```bash
   rm ~/Library/Application\ Support/iClippy/clipboard_history.json
   # Restart iClippy
   ```

### Items not cleaning up after 48 hours

**Note:** Cleanup only runs when new items are added

**Solutions:**
1. Copy something new to trigger cleanup
2. Use "Clear All" button to manually remove items
3. Pinned items are never auto-deleted (this is intentional)

### App crashes on launch

**Check crash logs:**
```bash
log show --predicate 'process == "iClippy"' --last 5m
```

**Solutions:**

1. **Reset app data**
   ```bash
   rm -rf ~/Library/Application\ Support/iClippy/
   # Relaunch app
   ```

2. **Rebuild from source**
   ```bash
   cd /Users/bridan/Documents/iClippy
   ./build.sh
   ```

3. **Check macOS version**
   - Requires macOS 13.0 (Ventura) or later
   ```bash
   sw_vers
   ```

## Performance Issues

### UI is slow/laggy

**Solutions:**

1. **Clear old items**
   - Click "Clear All" in iClippy
   - Or delete history:
     ```bash
     rm ~/Library/Application\ Support/iClippy/clipboard_history.json
     ```

2. **Reduce check interval** (requires rebuild)
   Edit `Sources/Services/ClipboardManager.swift`:
   ```swift
   // Change from 0.5 to 1.0 seconds
   timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true)
   ```

3. **Limit history size** (requires custom modification)
   Add to `ClipboardManager.swift` in `addEntry()`:
   ```swift
   // Keep only last 100 items
   if self.clipboardHistory.count > 100 {
       self.clipboardHistory.removeLast()
   }
   ```

### High CPU usage

**Check if stuck in loop:**
```bash
top -pid $(pgrep iClippy)
```

**Solutions:**
1. Quit and relaunch
2. Check for infinite clipboard loop (copy triggering copy)
3. Increase timer interval (see above)

## Permission Issues

### "iClippy can't be opened because it is from an unidentified developer"

**Solution:**
1. Right-click iClippy.app
2. Select **Open**
3. Click **Open** in the dialog
4. Or run:
   ```bash
   xattr -cr /Applications/iClippy.app
   open /Applications/iClippy.app
   ```

### Can't grant accessibility permissions

**Solution:**
1. Unlock System Settings: Click lock icon, enter password
2. Try removing and re-adding iClippy
3. Restart Mac
4. Boot into Safe Mode, grant permission, restart normally

## Data Issues

### Lost clipboard history

**Check if file exists:**
```bash
cat ~/Library/Application\ Support/iClippy/clipboard_history.json
```

**Recovery:**
- History is stored in JSON format
- Look for Time Machine backups of `~/Library/Application Support/iClippy/`

### Can't delete items

**Solutions:**
1. Use Delete key (not Backspace while in search field)
2. Click trash icon on item
3. Use "Clear All" button
4. Manually delete history file and restart

### Pinned items disappeared

**Check if file corrupted:**
```bash
# Validate JSON
python3 -m json.tool ~/Library/Application\ Support/iClippy/clipboard_history.json
```

**Recovery:**
- Check Time Machine backups
- Pinned items have `"isPinned": true` in JSON

## Build from Source Issues

### Xcode project won't open

**Solutions:**
1. Check Xcode version (need 15.0+)
2. Update Xcode from Mac App Store
3. Clear derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/
   ```

### Code signing errors

**Solutions:**
1. **For personal use:** Leave signing blank or use automatic signing
2. **For distribution:** Add Apple Developer account in Xcode preferences
3. Disable code signing for debug builds:
   - Xcode > Target > Signing & Capabilities
   - Uncheck "Automatically manage signing"

### Package resolution fails

**Solution:**
```bash
# Clear Swift package cache
rm -rf ~/Library/Caches/org.swift.swiftpm/
rm -rf ~/Library/Developer/Xcode/DerivedData/

# Reopen project
open iClippy.xcodeproj
```

## Still Having Issues?

### Collect diagnostic information:

```bash
# System info
sw_vers
xcodebuild -version

# Check if app is running
ps aux | grep iClippy

# Check recent logs
log show --predicate 'process == "iClippy"' --last 10m

# Check accessibility
osascript -e 'tell application "System Events" to get name of every process whose name is "iClippy"'

# Check file permissions
ls -la ~/Library/Application\ Support/iClippy/
```

### Reset everything:

```bash
# Quit app
killall iClippy

# Remove app data
rm -rf ~/Library/Application\ Support/iClippy/

# Remove preferences
defaults delete com.iclippy.app

# Rebuild
cd /Users/bridan/Documents/iClippy
./build.sh
```

### Get help:

1. Check Console.app for error messages (filter: "iClippy")
2. Create issue on project repository with:
   - macOS version
   - Error messages from Console.app
   - Steps to reproduce
   - Diagnostic output (see above)
