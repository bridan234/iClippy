# iClippy

A lightweight macOS clipboard manager that lives in your menu bar. iClippy captures supported clipboard content, respecting private mode and privacy exclusions, lets you search through your clipboard history, and enables quick paste back into any application.

![macOS](https://img.shields.io/badge/macOS-12.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Features

### 🎯 Core Features
- **Instant Access**: Press `⌘⇧V` or click the menu bar icon to view your clipboard history
- **Quick Paste**: Click any item to automatically paste it into your previous application
- **Persistent History**: Your clipboard history is saved between app restarts
- **Smart Content Detection**: Automatically categorizes items as Text, Code, Rich Text, or Images
- **No Dock Icon**: Runs quietly in the menu bar without cluttering your dock

### 🔍 Search & Organization
- **Real-time Search**: Filter your clipboard history instantly as you type
- **Pin Important Items**: Keep frequently used items at the top and prevent them from expiring
- **Keyboard Navigation**: Use arrow keys to navigate, Enter to paste, Escape to close

### 📋 Content Support
- **Plain Text**: Copy and paste regular text
- **Code Snippets**: Automatically detects code with syntax highlighting badge
- **Rich Text**: Preserves formatting from documents and web pages
- **Images**: Captures PNG and TIFF images with thumbnail previews

### Privacy, search, and productivity
- **Private Mode**: Pause recording from the menu bar context menu or Settings.
- **Excluded Apps**: Configure bundle IDs; common password managers are excluded by default. Concealed, transient, and auto-generated pasteboard markers are ignored.
- **Encrypted History**: AES-GCM encryption for history and image assets, using a local Keychain key. Clipboard content is never included in new logs.
- **Filtered Search**: Combine text search with type, source app, pinned, and snippet filters. Existing entries without source metadata remain searchable under All apps.
- **Image Text Recognition**: Apple Vision indexes screenshots on this Mac, without cloud requests. Toggle recognition in Settings; existing recognized text remains searchable when disabled.
- **Named Snippets**: Use + for a new snippet, or right-click a text entry to save it as a snippet. Right-click a snippet to edit it. Snippets survive Clear unpinned and automatic cleanup.
- **Paste as Plain Text**: Right-click an entry, or press Shift+Enter. For images with recognized text, this pastes the recognized text.
- **Custom Shortcut**: Settings → Keyboard shortcut → Change. Unavailable shortcuts show an error and keep the previous working shortcut.

### ⚡ Advanced Features
- **Smart Expiration**: Configurable retention, default 7 days, cleaned up every minute (pins and named snippets never expire)
- **Duplicate Filtering**: Won't clutter your history with consecutive duplicates
- **Hover Actions**: Pin, copy, or delete individual entries
- **Clear All**: Bulk delete unpinned entries

## Installation

### Install from the DMG (recommended)

1. Download the latest `iClippy-*.dmg` from [Releases](https://github.com/bridan234/iClippy/releases).

2. Open it and drag **iClippy.app** onto the **Applications** folder.

3. Clear the download quarantine flag:
   ```bash
   xattr -dr com.apple.quarantine /Applications/iClippy.app
   ```

   iClippy is signed ad-hoc rather than with a paid Apple Developer ID, so macOS
   quarantines it after download. Without this step the first launch is blocked
   with *"Apple could not verify iClippy is free of malware"* — you can also
   allow it from **System Settings → Privacy & Security → Open Anyway**.

4. Open iClippy from Applications, once. It installs its own login agent, so from
   then on it starts automatically at login — see
   [Always-on background agent](#always-on-background-agent).

5. Grant Accessibility permission when prompted, so automatic pasting works.

### Building from Source

Only the Xcode Command Line Tools are required — no full Xcode install.

1. **Clone the repository**
   ```bash
   git clone https://github.com/bridan234/iClippy.git
   cd iClippy
   ```

2. **Build and run**
   ```bash
   ./build.sh
   ```

   The app is built in Release mode into `./dist` and launched.

### Packaging (DMG/ZIP)

To create installable artifacts:
```bash
./package.sh
```

The script produces `.dmg` and `.zip` files in `./dist`. The DMG is a
drag-to-install volume containing the app, an Applications shortcut, and setup
instructions.

Both scripts delegate the actual bundling to `make-app.sh`, which builds with
Swift Package Manager, assembles `iClippy.app`, and code-signs it (ad-hoc by
default; set `SIGN_IDENTITY` to use a real identity). A universal
arm64 + x86_64 binary needs full Xcode; with only the Command Line Tools it
falls back to a host-only build and says so.

### Releasing via GitHub Actions

Pushing a tag builds a universal app on a macOS runner and attaches the DMG and
ZIP to a GitHub release — see [.github/workflows/release.yml](.github/workflows/release.yml):

```bash
git tag v1.0.0 && git push origin v1.0.0
```

### Manual Build with Xcode

1. Open `iClippy.xcodeproj` in Xcode
2. Select the iClippy scheme
3. Build and run (`⌘R`)

## Setup

### Required Permissions

iClippy needs two permissions for automatic pasting to work:

#### 1. Accessibility Permission
- **Why**: Enables automatic paste simulation via keyboard events
- **How to grant**:
  1. Open **System Settings** → **Privacy & Security** → **Accessibility**
  2. Enable **iClippy** in the list
  3. You may need to restart iClippy

Automatic paste uses keyboard events and only requires Accessibility permission. If the target app does not become active, or the clipboard changes while activation is pending, automatic paste is cancelled.

### Always-on background agent

**Start at Login is on by default.** On its first launch iClippy installs a
per-user LaunchAgent at `~/Library/LaunchAgents/com.iclippy.app.plist`, which:

- starts iClippy at every login (`RunAtLoad`), and
- restarts it if it crashes or is force-quit (`KeepAlive` / `SuccessfulExit=false`).

A clean quit is honoured, so **Quit iClippy** really does quit — it stays gone
until the next login. Right-click the ✂️ menu bar icon to toggle **Start at
Login** or to quit.

Only one instance ever owns the menu bar; a duplicate launch exits immediately.
The agent records an absolute path to the app, and iClippy rewrites the plist if
it notices the app has moved (e.g. run from `~/Downloads`, later moved to
`/Applications`), so install it where you intend to keep it.

Note that the launch agent takes over at the *next* login. During the first
session, the instance you opened manually is the one running.

Check on it at any time:
```bash
launchctl print gui/$(id -u)/com.iclippy.app | grep -E 'state|pid|runs'
```

Turning **Start at Login** off removes the plist so iClippy won't return after
logout; it deliberately does not tear down the loaded job, which would quit the
app out from under you.

### Uninstalling

Right-click the menu bar icon → **Quit iClippy**, then:
```bash
rm -f ~/Library/LaunchAgents/com.iclippy.app.plist
launchctl bootout gui/$(id -u)/com.iclippy.app 2>/dev/null
rm -rf /Applications/iClippy.app
rm -rf ~/Library/Application\ Support/iClippy
```

## Release & Notarization

To build, sign, notarize, and package:
```bash
./release.sh
```

The script reads credentials from environment variables or a keychain profile (see `release.sh` for details).
Example:
```bash
export DEVELOPER_ID_APP="Developer ID Application: Your Name (TEAMID)"
export DEVELOPMENT_TEAM="TEAMID"
export NOTARY_PROFILE="notarytool-profile"
./release.sh
```

## Usage

### Basic Usage

1. **Open the clipboard history**
   - Click the ✂️ icon in the menu bar, or
   - Press `⌘⇧V` (Command + Shift + V)

2. **Paste an item**
   - Click on any item, or
   - Use arrow keys to select and press Enter

3. **Search your history**
   - Type in the search bar at the top
   - Results filter in real-time

4. **Close the popover**
   - Press Escape, or
   - Click outside the window

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘⇧V` | Toggle clipboard history popover |
| `↑` `↓` | Navigate through entries |
| `Enter` | Paste selected entry |
| `Shift+Enter` | Paste selected entry as plain text |
| `Escape` | Close popover |

### Managing Entries

**Pin an entry**
- Hover over an entry and click the pin icon
- Pinned entries stay at the top and never expire

**Delete an entry**
- Hover over an entry and click the trash icon

**Copy without pasting**
- Hover over an entry and click the copy icon
- Content is copied to clipboard without automatic paste

**Clear all unpinned entries**
- Click "Clear unpinned" in the footer (named snippets are also preserved)

## Architecture

iClippy is built with:
- **SwiftUI** for the user interface
- **AppKit** for menu bar integration and system clipboard access
- **Magnet** for global hotkey registration
- **Swift Package Manager** for dependency management

### Key Components

- **ClipboardManager**: Monitors the system clipboard every 500ms
- **StorageManager**: Serial background saves to encrypted history and separate encrypted image assets in Application Support
- **AppDelegate**: Manages the menu bar item, popover, and paste orchestration
- **ContentView**: Main SwiftUI interface with search and list display

## Storage

Clipboard history is stored at:
```
~/Library/Application Support/iClippy/clipboard_history.encrypted
~/Library/Application Support/iClippy/Images/<entry-id>.encrypted
```

The encryption key is in your login Keychain under service `com.iclippy.history`.
Legacy `clipboard_history.json` is migrated automatically, then removed only after encrypted persistence succeeds. Keep the Keychain key with any history backups. If history cannot be decrypted or decoded, iClippy preserves existing files and disables writes until the problem is resolved.

Settings default to 500 entries and 100 MB of payload data. Automatic limits remove oldest unpinned entries; pins and snippets are exempt. Items larger than 10 MB are skipped. OCR is asynchronous and may take time to index existing images. Source attribution uses the frontmost app when clipboard changes are observed.

## Performance

- **Startup time**: < 500ms
- **Memory usage**: < 50MB typical
- **Clipboard polling**: Every 500ms
- **Paste delay**: ~200ms after selection

## Troubleshooting

### Automatic paste isn't working
- Check that Accessibility permission is granted
- Try restarting iClippy after granting permissions
- Check Console.app for error messages from iClippy

### Clipboard history isn't saving
- Ensure iClippy has permission to write to Application Support
- Check `~/Library/Application Support/iClippy/` exists and is writable

### Images aren't showing
- Only PNG and TIFF formats are supported
- Captured items over 10 MB are skipped

## Development

### Project Structure
```
iClippy/
├── Sources/
│   ├── iClippyApp.swift          # SwiftUI app entry point
│   ├── AppDelegate.swift         # AppKit lifecycle & menu bar
│   ├── Info.plist               # App metadata & permissions
│   ├── Models/
│   │   └── ClipboardEntry.swift # Data model
│   ├── Services/
│   │   ├── ClipboardManager.swift # Clipboard monitoring
│   │   ├── LoginItemManager.swift # Launch agent (start at login, keep alive)
│   │   └── StorageManager.swift   # JSON persistence
│   └── Views/
│       ├── ContentView.swift     # Main UI
│       └── Components/           # Reusable UI components
├── iClippy.xcodeproj/
├── Package.swift                 # SPM dependencies
├── make-app.sh                   # Builds iClippy.app (SPM, no Xcode needed)
├── build.sh                      # Build + launch
├── package.sh                    # Build + DMG/ZIP installers
└── release.sh                    # Signed + notarized release (needs Developer ID)
```

### Building

The build script creates a Release build:
```bash
./build.sh
```

Or use Xcode for development with debugging:
```bash
xcodebuild -project iClippy.xcodeproj -scheme iClippy -configuration Debug
```

## Tests

Run `./run-tests.sh` (Command Line Tools are sufficient; XCTest is not required) for legacy decoding, encrypted migration and asset cleanup, failed-key preservation, clipboard format round-trips, privacy exclusions, retention, sorting, search metadata, and on-device image text recognition.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

## Acknowledgments

- [Magnet](https://github.com/Clipy/Magnet) - Global hotkey registration
- Built with ❤️ and [Claude Code](https://claude.com/claude-code)

---

**Note**: iClippy is designed for personal productivity and does not sync clipboard data to the cloud or share it with any third parties. All data stays local on your Mac.
