# iClippy

A native macOS clipboard manager that keeps track of your clipboard history and lets you quickly access previous copies.

## Features

- **Clipboard History**: Automatically captures all clipboard content (text, code, images, rich text)
- **Smart Search**: Quickly filter clipboard history with real-time search
- **Keyboard Navigation**: Navigate with arrow keys, copy with Enter, delete with Backspace
- **Pin Favorites**: Pin important items to keep them at the top
- **Auto-Paste**: Automatically paste selected items into the active window
- **48-Hour History**: Items older than 48 hours are automatically cleaned up (pinned items are kept forever)
- **Menu Bar App**: Runs in the background with a menu bar icon, no Dock icon
- **Native Performance**: Built with Swift and SwiftUI for optimal macOS performance

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (for building from source)

## Installation

### Option 1: Build from Source

1. **Clone or download this repository**
   ```bash
   cd /Users/bridan/Documents/Github/iClippy
   ```

2. **Open the Xcode project**
   ```bash
   open iClippy.xcodeproj
   ```

3. **Build and Run**
   - In Xcode, select **Product > Build** (⌘B)
   - Once built, select **Product > Run** (⌘R)
   - The app will launch and appear in your menu bar

4. **Export the App** (Optional - for standalone installation)
   - In Xcode, select **Product > Archive**
   - Once archived, click **Distribute App**
   - Choose **Copy App**
   - Save the app to your Applications folder

### Option 2: Direct Build via Command Line

```bash
# Navigate to project directory
cd /Users/bridan/Documents/Github/iClippy

# Build the app
xcodebuild -project iClippy.xcodeproj \
   -scheme iClippy \
   -configuration Release \
   -derivedDataPath ./build

# The app will be located at:
# ./build/Build/Products/Release/iClippy.app

# Copy to Applications folder
cp -r ./build/Build/Products/Release/iClippy.app /Applications/
```

Or use the build script:

```bash
./build.sh
```

## First Time Setup

### Grant Accessibility Permissions

iClippy needs accessibility permissions to:
1. Register global keyboard shortcuts
2. Simulate paste commands (⌘V) when you select an item

**Steps:**
1. When you first launch iClippy, macOS will prompt you to grant accessibility permissions
2. Click **Open System Settings**
3. In **Privacy & Security > Accessibility**, toggle on **iClippy**
4. If the prompt doesn't appear:
   - Go to **System Settings > Privacy & Security > Accessibility**
   - Click the **+** button
   - Navigate to `/Applications/iClippy.app` and add it
   - Toggle it on

### Launch at Login (Optional)

To make iClippy start automatically when you log in:

1. Go to **System Settings > General > Login Items**
2. Click the **+** button under "Open at Login"
3. Select **iClippy** from your Applications folder
4. Click **Add**

## Usage

### Opening iClippy

- **Keyboard Shortcut**: Press `⌘⇧V` (Command + Shift + V)
- **Menu Bar**: Click the clipboard icon in the menu bar

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘⇧V` | Open/close iClippy window |
| `↑` / `↓` | Navigate through clipboard history |
| `⏎` (Enter) | Copy selected item and auto-paste |
| `⌫` (Backspace/Delete) | Delete selected item |
| `⌘W` or `Esc` | Close window |

### Using the Interface

1. **Search**: Type in the search bar to filter clipboard history
2. **Navigate**: Use arrow keys or mouse to select items
3. **Pin Items**: Click the pin icon to keep items permanently
4. **Copy**: Click an item or press Enter to copy and paste
5. **Delete**: Click the trash icon or press Backspace to remove items
6. **Clear All**: Click "Clear" button in the footer to remove all unpinned items

### Item Types

iClippy automatically detects and categorizes clipboard content:

- **Text**: Plain text content
- **Code**: Detected code snippets (contains keywords like `import`, `const`, `function`, etc.)
- **Image**: PNG, TIFF, and other image formats
- **Rich Text**: Formatted text with styling

### Pin Important Items

- Pinned items appear at the top of the list with an orange pin icon
- Pinned items are never auto-deleted (they persist beyond 48 hours)
- Click the pin icon on any item to pin/unpin it

## How It Works

### Clipboard Monitoring

iClippy monitors the system clipboard using `NSPasteboard` and checks for changes every 0.5 seconds. When new content is detected, it's automatically added to your history.

### Data Storage

- Clipboard history is stored in `~/Library/Application Support/iClippy/clipboard_history.json`
- History persists between app restarts
- Items older than 48 hours (except pinned items) are automatically removed

### Auto-Paste

When you select an item and press Enter:
1. The content is copied to the system clipboard
2. iClippy simulates a `⌘V` keypress using CGEvent
3. The content is pasted into the previously active application
4. The iClippy window closes automatically

### Privacy

- All clipboard data is stored locally on your Mac
- No data is sent to external servers
- You have full control over your clipboard history

## Customization

### Change Keyboard Shortcut

To change the global hotkey, edit `Sources/AppDelegate.swift`:

```swift
// Current: Command + Shift + V
if let keyCombo = KeyCombo(key: .v, cocoaModifiers: [.command, .shift]) {

// Example alternatives:
// Option + V
if let keyCombo = KeyCombo(key: .v, cocoaModifiers: [.option]) {

// Control + V
if let keyCombo = KeyCombo(key: .v, cocoaModifiers: [.control]) {

// Command + Option + V
if let keyCombo = KeyCombo(key: .v, cocoaModifiers: [.command, .option]) {
```

Available modifier keys: `.command`, `.option`, `.control`, `.shift`

### Adjust History Retention Period

To change the 48-hour retention period, edit `Sources/Models/ClipboardEntry.swift`:

```swift
func isExpired() -> Bool {
    if isPinned { return false }
    // Change 48 to desired number of hours
    let fortyEightHoursAgo = Date().addingTimeInterval(-48 * 60 * 60)
    return timestamp < fortyEightHoursAgo
}
```

### Modify Clipboard Check Interval

To change how often iClippy checks the clipboard, edit `Sources/Services/ClipboardManager.swift`:

```swift
func startMonitoring() {
    lastChangeCount = pasteboard.changeCount
    // Change 0.5 to desired interval in seconds
    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
        self?.checkClipboard()
    }
}
```

## Troubleshooting

### iClippy doesn't appear in the menu bar

1. Check that the app is running (look for it in Activity Monitor)
2. Make sure you granted accessibility permissions
3. Try restarting the app

### Global hotkey doesn't work

1. Go to **System Settings > Privacy & Security > Accessibility**
2. Ensure iClippy is in the list and toggled on
3. Try removing and re-adding iClippy to refresh permissions
4. Restart the app

### Auto-paste doesn't work

1. Verify accessibility permissions are granted
2. Check that no other app is intercepting the ⌘V shortcut
3. Try clicking the copy button instead of using Enter

### Clipboard history is empty

1. Copy some text to test if monitoring is working
2. Check if the app has accessibility permissions
3. Look at the Console app for any error messages from iClippy

### Items aren't being cleaned up after 48 hours

1. The cleanup runs when new items are added to the clipboard
2. Pinned items are never cleaned up automatically
3. You can manually delete items or use "Clear All"

## Building for Distribution

### Code Signing (Required for distribution)

1. Open the Xcode project
2. Select the iClippy target
3. Go to **Signing & Capabilities**
4. Select your development team
5. Xcode will automatically generate a signing certificate

### Creating a Notarized Build

For distribution outside the Mac App Store:

1. Archive the app: **Product > Archive**
2. Export for notarization: **Distribute App > Developer ID**
3. Submit for notarization to Apple
4. Create a DMG or ZIP for distribution

## Uninstallation

To remove iClippy from your Mac:

1. Quit the app (right-click menu bar icon > Quit)
2. Delete the app: `rm -rf /Applications/iClippy.app`
3. Remove app data: `rm -rf ~/Library/Application\ Support/iClippy`
4. Remove from Login Items in System Settings
5. Remove from Accessibility permissions in System Settings

## Development

### Project Structure

```
iClippy/
├── Sources/
│   ├── iClippyApp.swift          # Main app entry point
│   ├── AppDelegate.swift         # App lifecycle & menu bar setup
│   ├── Models/
│   │   └── ClipboardEntry.swift  # Data model for clipboard items
│   ├── Services/
│   │   ├── ClipboardManager.swift # Clipboard monitoring & management
│   │   └── StorageManager.swift   # Persistent storage
│   └── Views/
│       ├── ContentView.swift      # Main view
│       └── Components/
│           ├── SearchBarView.swift
│           ├── ClipboardItemView.swift
│           ├── EmptyStateView.swift
│           └── FooterView.swift
├── iClippy.xcodeproj/
└── README.md
```

### Dependencies

- **Magnet**: Global hotkey registration (v3.4.0+)
  - Repository: https://github.com/Clipy/Magnet
  - Managed via Swift Package Manager

### Testing

1. Build and run in Xcode
2. Copy various types of content (text, code, images)
3. Test keyboard shortcuts and navigation
4. Verify auto-paste functionality
5. Test persistence by restarting the app

## Known Issues

- **Image previews**: Currently images show as "Image" text. Future versions will include thumbnails.
- **Large clipboard items**: Very large items (>1MB) may slow down the UI.
- **Multiple monitors**: Window always appears at the menu bar icon location.

## Future Enhancements

Planned features for future versions:

- Image thumbnails in clipboard history
- Sync across devices via iCloud
- Custom categories and tags
- Clipboard history statistics
- Export clipboard history
- Snippet management
- Text transformations (uppercase, lowercase, etc.)
- OCR for images

## License

This project is available for personal and commercial use.

## Credits

- Built with Swift and SwiftUI
- Uses [Magnet](https://github.com/Clipy/Magnet) for global hotkey support
- UI design inspired by modern macOS design patterns

## Support

For issues, questions, or feature requests, please file an issue on the project repository.

---

**Version**: 1.0
**Last Updated**: 2026
