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

    /// Paste timing tuning
    private let pasteActivationTimeout: TimeInterval = 1.0
    private let pasteActivationPollInterval: TimeInterval = 0.05

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

        // Capture the currently active app on launch (if it's not iClippy)
        updatePreviousAppIfNeeded(NSWorkspace.shared.frontmostApplication)

        // Enable launch at login (default true)
        LoginItemManager.configureOnLaunch()

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

        // Track when other apps deactivate (useful when iClippy becomes active)
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidDeactivate),
            name: NSWorkspace.didDeactivateApplicationNotification,
            object: nil
        )
    }

    // MARK: - Launch at Login handled by LoginItemManager

    private func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options)

        if trusted {
            print("✅ Accessibility permissions granted")
        } else {
            print("⚠️ Accessibility permissions not yet granted - user will be prompted")

            // Show a friendly reminder after the system prompt
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.showAccessibilityPermissionReminder()
            }
        }
    }

    private func showAccessibilityPermissionReminder() {
        // Check again to see if permission was granted
        let trusted = AXIsProcessTrusted()
        if trusted {
            return // Permission was granted, no need to show reminder
        }

        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Needed"
        alert.informativeText = """
        iClippy needs Accessibility permission for automatic pasting.

        To grant permission:
        1. Open System Settings → Privacy & Security → Accessibility
        2. Enable iClippy in the list
        3. You may need to restart iClippy

        Without this permission, you'll need to paste manually with ⌘V after selecting an item.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Remind Me Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Settings to Accessibility
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    // MARK: - Workspace Tracking

    @objc private func applicationDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }

        updatePreviousAppIfNeeded(app)
    }

    @objc private func applicationDidDeactivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }

        updatePreviousAppIfNeeded(app)
    }

    private func updatePreviousAppIfNeeded(_ app: NSRunningApplication?) {
        guard let app = app else { return }
        guard app.bundleIdentifier != Bundle.main.bundleIdentifier else { return }
        previousApp = app
    }

    // MARK: - Popover Management

    @objc func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            popover.close()
        } else {
            // Track the current frontmost app before showing popover
            updatePreviousAppIfNeeded(NSWorkspace.shared.frontmostApplication)

            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

            // Activate the popover window
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Paste Orchestration

    /// Handles pasting a clipboard entry into the previously active application
    func pasteEntry(_ entry: ClipboardEntry) {
        print("🔵 pasteEntry called for: \(entry.preview)")

        // Copy the entry to the system clipboard
        clipboardManager?.copyToClipboard(entry)

        // Close the popover
        popover?.close()

        // Activate the previous app
        guard let targetApp = previousApp else {
            print("⚠️ No previous app to paste into")
            // Still copy to clipboard even if no target app
            return
        }

        print("🔵 Activating target app: \(targetApp.localizedName ?? "Unknown")")
        activateAndPaste(targetApp)
    }

    private func activateAndPaste(_ app: NSRunningApplication) {
        app.activate(options: [.activateIgnoringOtherApps])

        waitForActivation(of: app, timeout: pasteActivationTimeout) { [weak self] in
            self?.simulatePaste()
        }
    }

    private func waitForActivation(of app: NSRunningApplication, timeout: TimeInterval, completion: @escaping () -> Void) {
        let deadline = Date().addingTimeInterval(timeout)

        func check() {
            if app.isActive || NSWorkspace.shared.frontmostApplication?.bundleIdentifier == app.bundleIdentifier {
                completion()
                return
            }

            if Date() >= deadline {
                completion()
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + pasteActivationPollInterval) {
                check()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + pasteActivationPollInterval) {
            check()
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
                let errorCode = error["NSAppleScriptErrorNumber"] as? Int ?? 0

                if errorCode == -1743 {
                    // Automation permission denied
                    print("⚠️ AppleScript paste failed: Automation permission not granted")
                    showAutomationPermissionAlert()
                } else {
                    print("⚠️ AppleScript paste failed: \(error)")
                }
                return false
            }

            print("✅ Paste via AppleScript succeeded")
            return true
        }

        return false
    }

    private func showAutomationPermissionAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Automation Permission Required"
            alert.informativeText = """
            iClippy needs permission to control System Events for automatic pasting.

            Please grant permission in:
            System Settings → Privacy & Security → Automation → iClippy → System Events

            Without this permission, content will be copied to clipboard but you'll need to paste manually with ⌘V.
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "OK")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Open System Settings to Privacy & Security
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    private func simulatePasteWithCGEvent() {
        // Check if we have Accessibility permission
        let trusted = AXIsProcessTrusted()

        if !trusted {
            print("⚠️ CGEvent paste failed: Accessibility permission not granted")
            print("ℹ️ Content copied to clipboard - use ⌘V to paste manually")
            return
        }

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
