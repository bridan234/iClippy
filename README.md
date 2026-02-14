# iClippy

A lightweight macOS clipboard manager that lives in your menu bar. iClippy captures everything you copy, lets you search through your clipboard history, and enables quick paste back into any application.

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

### ⚡ Advanced Features
- **Smart Expiration**: Old entries automatically expire after 7 days (pinned items never expire)
- **Duplicate Filtering**: Won't clutter your history with consecutive duplicates
- **Hover Actions**: Pin, copy, or delete individual entries
- **Clear All**: Bulk delete unpinned entries

## Installation

### Building from Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/iClippy.git
   cd iClippy
   ```

2. **Build and run**
   ```bash
   ./build.sh
   ```

   The app will be built in Release mode and automatically launched.

### Packaging (DMG/ZIP)

To create installable artifacts:
```bash
./package.sh
```

The script produces `.dmg` and `.zip` files in `./dist`. Install by opening the DMG and dragging `iClippy.app` into `/Applications`.

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

#### 2. Automation Permission
- **Why**: Allows iClippy to send keystrokes to other applications
- **How to grant**:
  1. Open **System Settings** → **Privacy & Security** → **Automation**
  2. Find **iClippy** and enable **System Events**

**Note**: Without these permissions, iClippy will still capture and store your clipboard history. You'll just need to paste manually with `⌘V` after selecting an item.

### Launch at Login
- On macOS 13+, iClippy registers itself as a login item on first launch (default: on).
- You can toggle **Start at login** in the footer of the popover.
- Manage it in **System Settings → General → Login Items**.
- On macOS 12, add iClippy manually in Login Items.

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
- Click the "Clear All" button in the footer

## Architecture

iClippy is built with:
- **SwiftUI** for the user interface
- **AppKit** for menu bar integration and system clipboard access
- **Magnet** for global hotkey registration
- **Swift Package Manager** for dependency management

### Key Components

- **ClipboardManager**: Monitors the system clipboard every 500ms
- **StorageManager**: Persists clipboard history to JSON in Application Support
- **AppDelegate**: Manages the menu bar item, popover, and paste orchestration
- **ContentView**: Main SwiftUI interface with search and list display

## Storage

Clipboard history is stored at:
```
~/Library/Application Support/iClippy/clipboard_history.json
```

Images and rich text data are Base64-encoded within the JSON file.

## Performance

- **Startup time**: < 500ms
- **Memory usage**: < 50MB typical
- **Clipboard polling**: Every 500ms
- **Paste delay**: ~200ms after selection

## Troubleshooting

### Automatic paste isn't working
- Check that both Accessibility and Automation permissions are granted
- Try restarting iClippy after granting permissions
- Check Console.app for error messages from iClippy

### Clipboard history isn't saving
- Ensure iClippy has permission to write to Application Support
- Check `~/Library/Application Support/iClippy/` exists and is writable

### Images aren't showing
- Only PNG and TIFF formats are supported
- Very large images may be truncated

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
│   │   └── StorageManager.swift   # JSON persistence
│   └── Views/
│       ├── ContentView.swift     # Main UI
│       └── Components/           # Reusable UI components
├── iClippy.xcodeproj/
├── Package.swift                 # SPM dependencies
└── build.sh                      # Build script
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

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

## Acknowledgments

- [Magnet](https://github.com/Clipy/Magnet) - Global hotkey registration
- Built with ❤️ and [Claude Code](https://claude.com/claude-code)

---

**Note**: iClippy is designed for personal productivity and does not sync clipboard data to the cloud or share it with any third parties. All data stays local on your Mac.
