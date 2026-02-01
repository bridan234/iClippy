# iClippy Project Structure

```
iClippy/
│
├── README.md                      # Full documentation
├── QUICKSTART.md                  # Quick installation guide
├── PROJECT_STRUCTURE.md           # This file
├── build.sh                       # Build and install script
├── .gitignore                     # Git ignore rules
├── Package.swift                  # Swift Package Manager config
│
├── iClippy.xcodeproj/             # Xcode project
│   └── project.pbxproj            # Project configuration
│
├── Sources/                       # Source code
│   ├── iClippyApp.swift          # 🚀 Main app entry point
│   ├── AppDelegate.swift         # 📋 App lifecycle, menu bar, hotkey
│   ├── Info.plist                # App metadata & permissions
│   │
│   ├── Models/                   # Data models
│   │   └── ClipboardEntry.swift  # 📝 Clipboard item data structure
│   │
│   ├── Services/                 # Business logic
│   │   ├── ClipboardManager.swift    # 👀 Monitors & manages clipboard
│   │   └── StorageManager.swift      # 💾 Saves/loads history to disk
│   │
│   └── Views/                    # SwiftUI interface
│       ├── ContentView.swift     # 🖼️ Main window view
│       └── Components/           # Reusable UI components
│           ├── SearchBarView.swift      # 🔍 Search input
│           ├── ClipboardItemView.swift  # 📄 Individual item row
│           ├── EmptyStateView.swift     # 🗂️ Empty state placeholder
│           └── FooterView.swift         # ⚙️ Bottom action bar
│
└── project/                      # Original UI mockup (React)
    ├── App.tsx
    ├── components/
    └── styles/
```

## Key Files Explained

### Entry Points
- **iClippyApp.swift**: Main entry, creates SwiftUI app
- **AppDelegate.swift**: Sets up menu bar icon, registers global hotkey (⌘⇧V), manages app lifecycle

### Core Logic
- **ClipboardManager.swift**:
  - Monitors `NSPasteboard` every 0.5s
  - Detects text/code/image/richtext
  - Handles copy/paste/delete operations
  - Triggers auto-paste via CGEvent

- **StorageManager.swift**:
  - Saves clipboard history to `~/Library/Application Support/iClippy/`
  - Loads history on app startup
  - Uses JSON encoding

### Data Model
- **ClipboardEntry.swift**:
  - Stores: id, content, type, timestamp, isPinned, imageData, rtfData
  - Auto-expires unpinned items after 48 hours
  - Formats relative timestamps ("5m ago", "2h ago")

### User Interface
- **ContentView.swift**: Main window with search, list, footer
- **SearchBarView.swift**: Search input with magnifying glass icon
- **ClipboardItemView.swift**: Item row with type badge, timestamp, pin/copy/delete buttons
- **EmptyStateView.swift**: Shows when no items in history
- **FooterView.swift**: Shows keyboard shortcuts and "Clear" button

## Data Flow

```
1. User copies text
   ↓
2. ClipboardManager detects change (NSPasteboard)
   ↓
3. Creates ClipboardEntry with content & type
   ↓
4. Adds to history array
   ↓
5. StorageManager saves to disk
   ↓
6. SwiftUI updates UI (@Published property)
```

## Build Process

```
1. Run: ./build.sh
   ↓
2. Xcode compiles Swift → binary
   ↓
3. Swift Package Manager downloads Magnet dependency
   ↓
4. Links frameworks & creates .app bundle
   ↓
5. Output: build/Build/Products/Release/iClippy.app
   ↓
6. Optional: Copy to /Applications/
```

## Dependencies

- **Magnet** (v3.4.0+): Global hotkey registration
  - URL: https://github.com/Clipy/Magnet
  - Managed via Swift Package Manager in Xcode

## Permissions Required

- **Accessibility**: To register global hotkey and simulate paste (⌘V)
  - Requested automatically on first launch
  - Set in System Settings > Privacy & Security > Accessibility

## Build Configuration

- **Minimum macOS**: 13.0 (Ventura)
- **Swift Version**: 5.0
- **Bundle ID**: com.iclippy.app
- **LSUIElement**: true (hides Dock icon)

## Storage Location

- **History file**: `~/Library/Application Support/iClippy/clipboard_history.json`
- **Format**: JSON array of ClipboardEntry objects
- **Max size**: Unlimited (cleaned up after 48 hours)
