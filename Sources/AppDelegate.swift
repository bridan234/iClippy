import Cocoa
import SwiftUI
import Magnet

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var clipboardManager: ClipboardManager?

    /// Tracks the previously active application for paste operations
    private var previousApp: NSRunningApplication?

    /// Global hotkey for toggling the popover
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set app activation policy to accessory (no dock icon)
        NSApp.setActivationPolicy(.accessory)

        // Create clipboard manager
        clipboardManager = ClipboardManager()

        // Create status bar item
        setupStatusBarItem()

        // Create popover
        setupPopover()

        // Register global hotkey (Command+Shift+V)
        setupGlobalHotkey()

        // Set up workspace notifications to track previous app
        setupWorkspaceNotifications()

        // Request accessibility permissions
        requestAccessibilityPermissions()
    }

    // MARK: - Setup

    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "✂️"
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 326, height: 510)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(clipboardManager!)
                .environment(\.pasteHandler, pasteEntry)
        )
    }

    private func setupGlobalHotkey() {
        // Register Command+Shift+V as the global hotkey
        if let keyCombo = KeyCombo(key: .v, cocoaModifiers: [.command, .shift]) {
            hotKey = HotKey(identifier: "TogglePopover", keyCombo: keyCombo, target: self, action: #selector(togglePopover))
            hotKey?.register()
            print("✅ Registered global hotkey: Command+Shift+V")
        } else {
            print("❌ Failed to create key combo for global hotkey")
        }
    }

    private func setupWorkspaceNotifications() {
        // Track when other apps become active
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidActivate),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    private func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options)

        if trusted {
            print("✅ Accessibility permissions granted")
        } else {
            print("⚠️ Accessibility permissions not yet granted - user will be prompted")
        }
    }

    // MARK: - Workspace Tracking

    @objc private func applicationDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }

        // Don't track iClippy itself
        if app.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousApp = app
        }
    }

    // MARK: - Popover Management

    @objc func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            popover.close()
        } else {
            // Track the current frontmost app before showing popover
            if let frontmost = NSWorkspace.shared.frontmostApplication,
               frontmost.bundleIdentifier != Bundle.main.bundleIdentifier {
                previousApp = frontmost
            }

            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

            // Activate the popover window
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Paste Orchestration

    /// Handles pasting a clipboard entry into the previously active application
    func pasteEntry(_ entry: ClipboardEntry) {
        // Copy the entry to the system clipboard
        clipboardManager?.copyToClipboard(entry)

        // Close the popover
        popover?.close()

        // Activate the previous app
        guard let targetApp = previousApp else {
            print("⚠️ No previous app to paste into")
            return
        }

        targetApp.activate(options: [.activateIgnoringOtherApps])

        // Wait for the app to activate, then simulate paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.simulatePaste()
        }
    }

    private func simulatePaste() {
        // Method 1: Try AppleScript (requires Automation permission)
        let success = simulatePasteWithAppleScript()

        if !success {
            // Method 2: Fallback to CGEvent (requires Accessibility permission)
            simulatePasteWithCGEvent()
        }
    }

    private func simulatePasteWithAppleScript() -> Bool {
        let script = """
        tell application "System Events"
            keystroke "v" using command down
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)

            if let error = error {
                print("⚠️ AppleScript paste failed: \(error)")
                return false
            }

            print("✅ Paste via AppleScript succeeded")
            return true
        }

        return false
    }

    private func simulatePasteWithCGEvent() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Command+V keydown
        let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // v key
        keyVDown?.flags = .maskCommand

        // Command+V keyup
        let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyVUp?.flags = .maskCommand

        // Post events
        let location = CGEventTapLocation.cghidEventTap
        keyVDown?.post(tap: location)
        keyVUp?.post(tap: location)

        print("✅ Paste via CGEvent succeeded")
    }

    // MARK: - Cleanup

    deinit {
        hotKey?.unregister()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}

// MARK: - Environment Key for Paste Handler

private struct PasteHandlerKey: EnvironmentKey {
    static let defaultValue: (ClipboardEntry) -> Void = { _ in }
}

extension EnvironmentValues {
    var pasteHandler: (ClipboardEntry) -> Void {
        get { self[PasteHandlerKey.self] }
        set { self[PasteHandlerKey.self] = newValue }
    }
}
