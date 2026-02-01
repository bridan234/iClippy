# 🎉 Welcome to iClippy!

Your native macOS clipboard manager is ready to build and install.

## 🚀 Quick Start (3 Steps)

### 1️⃣ Build the App
```bash
cd /Users/bridan/Documents/iClippy
./build.sh
```

Press `y` when asked to install to Applications.

### 2️⃣ Launch & Grant Permissions
1. Open **iClippy** from Applications folder
2. Click **Open System Settings** when prompted
3. Toggle **iClippy** ON in Accessibility settings

### 3️⃣ Start Using!
Press `⌘⇧V` (Command + Shift + V) anywhere to open iClippy.

---

## 📖 Documentation

| Document | What's Inside |
|----------|---------------|
| [**QUICKSTART.md**](QUICKSTART.md) | Fast 3-step installation guide |
| [**README.md**](README.md) | Complete documentation (features, usage, customization) |
| [**BUILD_SUMMARY.md**](BUILD_SUMMARY.md) | What was built and technical overview |
| [**PROJECT_STRUCTURE.md**](PROJECT_STRUCTURE.md) | Code architecture and file organization |
| [**TROUBLESHOOTING.md**](TROUBLESHOOTING.md) | Debug guide and solutions |

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘⇧V` | Open iClippy |
| `↑` `↓` | Navigate items |
| `⏎` | Copy & auto-paste |
| `⌫` | Delete item |
| `⌘W` or `Esc` | Close window |

## ✨ Features

✅ **Menu Bar App** - Always running, accessible via status bar
✅ **Global Hotkey** - Press ⌘⇧V to open from anywhere
✅ **Smart History** - Captures text, code, images, rich text
✅ **Auto-Paste** - Automatically pastes selected items
✅ **Search** - Real-time filtering of clipboard history
✅ **Pin Favorites** - Keep important items forever
✅ **Auto-Cleanup** - Removes items older than 48 hours
✅ **Native macOS** - Built with Swift & SwiftUI

## 🏗️ Project Structure

```
iClippy/
├── START_HERE.md              ← You are here!
├── QUICKSTART.md              Quick installation
├── README.md                  Full documentation
├── BUILD_SUMMARY.md           Technical overview
├── PROJECT_STRUCTURE.md       Architecture
├── TROUBLESHOOTING.md         Debug guide
│
├── build.sh                   Build & install script
├── Package.swift              Dependencies
├── iClippy.xcodeproj/         Xcode project
│
└── Sources/                   Swift source code
    ├── iClippyApp.swift       App entry point
    ├── AppDelegate.swift      Menu bar & hotkeys
    ├── Models/                Data structures
    ├── Services/              Business logic
    └── Views/                 UI components
```

## 🎯 What You Asked For

✅ Native macOS app (Swift, not Electron)
✅ Menu bar icon, no Dock icon
✅ Global keyboard shortcut (⌘⇧V)
✅ Scrollable clipboard history
✅ Select with keyboard/mouse
✅ Auto-paste into active window
✅ Closes after selection
✅ Persistent history (survives restart)
✅ Support for text, code, images, rich text
✅ Pin favorite items
✅ Auto-delete after 48 hours
✅ Matches your UI mockup design
✅ Complete documentation

## 🛠️ Build Requirements

- macOS 13.0+ (Ventura or later)
- Xcode 15.0+ (for building)

## 📝 Next Steps

1. **Build**: Run `./build.sh`
2. **Install**: Say yes when prompted
3. **Launch**: Open from Applications
4. **Grant**: Allow accessibility permissions
5. **Use**: Press ⌘⇧V to open!

## 🎨 UI Preview

Your app will look like this:

```
┌────────────────────────────────────────────┐
│  🔍 Search clipboard history...            │
├────────────────────────────────────────────┤
│  [code]  5m ago                        ⋮   │
│  import { useState } from 'react';         │
│                                            │
│  [text]  30m ago                       ⋮   │
│  https://www.figma.com/design/...          │
│                                            │
│  [text]  2h ago                        ⋮   │
│  Meeting notes:                            │
│  - Discussed Q4 roadmap...                 │
├────────────────────────────────────────────┤
│  ↑↓ Navigate • ⏎ Copy • ⌫ Delete    Clear │
└────────────────────────────────────────────┘
```

## ❓ Need Help?

- **Quick issues**: Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **How to use**: See [README.md](README.md)
- **Architecture**: Read [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)

## 🎊 Ready to Build!

Everything is configured and ready. Just run:

```bash
./build.sh
```

---

**Happy Clipping!** 📋✨
