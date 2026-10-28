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
    private var settingsWindow: NSWindow?
    private var pasteGeneration = UUID()

    /// Paste timing tuning
    private let pasteActivationTimeout: TimeInterval = 1.0
    private let pasteActivationPollInterval: TimeInterval = 0.05

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The launch agent and a manual launch can both start iClippy, so make
        // sure only one instance ever owns the menu bar. Exiting cleanly (status 0)
        // matters: the agent's KeepAlive only respawns unclean exits, so this
        // cannot turn into a respawn loop.
        if anotherInstanceIsRunning() {
            NSLog("iClippy: another instance is already running — exiting")
            exit(EXIT_SUCCESS)
        }

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

        NotificationCenter.default.addObserver(self, selector: #selector(showSettings), name: .iClippySettings, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeShortcut(_:)), name: .iClippyShortcut, object: nil)

        // Request accessibility permissions
        requestAccessibilityPermissions()
    }

    // MARK: - Single Instance

    private func anotherInstanceIsRunning() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }

        let ourPID = ProcessInfo.processInfo.processIdentifier
        let ourLaunchDate = NSRunningApplication.current.launchDate ?? Date()

        return NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != ourPID }
            .contains { other in
                // Yield to the instance that started first. If launch dates are
                // unavailable or identical, fall back to the lower PID so two
                // simultaneous launches can't both decide to quit.
                guard let otherLaunchDate = other.launchDate else {
                    return other.processIdentifier < ourPID
                }
                if otherLaunchDate == ourLaunchDate {
                    return other.processIdentifier < ourPID
                }
                return otherLaunchDate < ourLaunchDate
            }
    }

    // MARK: - Setup

    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "✂️"
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 570)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(clipboardManager!)
                .environment(\.pasteHandler, pasteEntry)
        )
    }

    private func setupGlobalHotkey() {
        let settings = AppSettings.shared
        if !registerShortcut(code: settings.shortcutCode, modifiers: settings.shortcutModifiers) {
            settings.shortcutError = "The saved shortcut is unavailable. Choose another in Settings."
        }
    }

    private func registerShortcut(code: Int, modifiers: UInt) -> Bool {
        guard let combo = KeyCombo(QWERTYKeyCode: code, cocoaModifiers: NSEvent.ModifierFlags(rawValue: modifiers)) else { return false }
        hotKey?.unregister()
        let candidate = HotKey(identifier: "TogglePopover", keyCombo: combo, target: self, action: #selector(togglePopover))
        if candidate.register() { hotKey = candidate; return true }
        _ = hotKey?.register()
        return false
    }

    @objc private func changeShortcut(_ notification: Notification) {
        guard let info = notification.userInfo, let code = info["code"] as? Int,
              let flags = info["modifiers"] as? UInt, let label = info["label"] as? String else { return }
        let settings = AppSettings.shared
        guard registerShortcut(code: code, modifiers: flags) else {
            settings.shortcutError = "That shortcut could not be registered. The previous shortcut is still active."
            return
        }
        settings.shortcutCode = code; settings.shortcutModifiers = flags; settings.shortcutLabel = label
        settings.shortcutError = ""
    }

    @objc private func showSettings() {
        popover?.close()
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 600),
                styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "iClippy Settings"
            window.contentViewController = NSHostingController(rootView: SettingsView())
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func togglePrivateMode() { AppSettings.shared.privateMode.toggle() }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardManager?.stopMonitoring()
        StorageManager.shared.flush()
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

    // MARK: - Status Item Menu

    /// Left click toggles the clipboard popover; right click (or Control-click)
    /// opens the settings menu.
    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent

        if let event = event, event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func showContextMenu() {
        popover?.close()

        let menu = NSMenu()

        let startAtLogin = NSMenuItem(
            title: "Start at Login",
            action: #selector(toggleStartAtLogin),
            keyEquivalent: ""
        )
        startAtLogin.target = self
        startAtLogin.state = LoginItemManager.isStartAtLoginEnabled() ? .on : .off
        menu.addItem(startAtLogin)

        let privacy = NSMenuItem(title: "Private Mode", action: #selector(togglePrivateMode), keyEquivalent: "")
        privacy.target = self
        privacy.state = AppSettings.shared.privateMode ? .on : .off
        menu.addItem(privacy)
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit iClippy", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        // Attaching the menu makes the next click open it; detaching afterwards
        // restores plain left-click-to-toggle behaviour.
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func toggleStartAtLogin() {
        LoginItemManager.setStartAtLogin(!LoginItemManager.isStartAtLoginEnabled())
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
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

            popover.contentViewController?.view.window?.identifier = NSUserInterfaceItemIdentifier("iClippyPopover")

            // Activate the popover window
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Paste Orchestration

    /// Handles pasting a clipboard entry into the previously active application
    func pasteEntry(_ entry: ClipboardEntry, plainText: Bool = false) {
        guard !plainText || entry.type != .image || !(entry.recognizedText ?? "").isEmpty else {
            clipboardManager?.statusMessage = "No recognized text is available for this image yet."
            return
        }

        // Copy the entry to the system clipboard
        clipboardManager?.copyToClipboard(entry, plainText: plainText)

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
        let generation = UUID()
        pasteGeneration = generation
        let changeCount = NSPasteboard.general.changeCount
        app.activate(options: [.activateIgnoringOtherApps])
        waitForActivation(of: app, timeout: pasteActivationTimeout) { [weak self] activated in
            guard let self, self.pasteGeneration == generation else { return }
            guard activated, !app.isTerminated,
                  NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier,
                  NSPasteboard.general.changeCount == changeCount else {
                self.clipboardManager?.statusMessage = "Automatic paste cancelled because the destination or clipboard changed. Use ⌘V to paste manually."
                return
            }
            self.simulatePaste()
        }
    }

    private func waitForActivation(of app: NSRunningApplication, timeout: TimeInterval, completion: @escaping (Bool) -> Void) {
        let deadline = Date().addingTimeInterval(timeout)
        func check() {
            if !app.isTerminated && NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier {
                completion(true); return
            }
            if app.isTerminated || Date() >= deadline { completion(false); return }
            DispatchQueue.main.asyncAfter(deadline: .now() + pasteActivationPollInterval) { check() }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + pasteActivationPollInterval) { check() }
    }

    private func simulatePaste() { simulatePasteWithCGEvent() }

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
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Environment Key for Paste Handler

private struct PasteHandlerKey: EnvironmentKey {
    static let defaultValue: (ClipboardEntry, Bool) -> Void = { _, _ in }
}

extension EnvironmentValues {
    var pasteHandler: (ClipboardEntry, Bool) -> Void {
        get { self[PasteHandlerKey.self] }
        set { self[PasteHandlerKey.self] = newValue }
    }
}
