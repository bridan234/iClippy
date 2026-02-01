import Cocoa
import SwiftUI
import Magnet

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var clipboardManager: ClipboardManager?
    var hotKeyCenter: HotKeyCenter?
    private var lastActiveApp: NSRunningApplication?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "iClippy")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Initialize clipboard manager
        clipboardManager = ClipboardManager.shared
        clipboardManager?.startMonitoring()

        // Setup popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 326, height: 510)
        popover.behavior = .transient
        popover.animates = true

        let contentView = ContentView()
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.window?.isOpaque = false
        popover.contentViewController = hostingController

        self.popover = popover

        // Register global hotkey (Command + Shift + V)
        registerHotKey()

        // Request accessibility permissions
        requestAccessibilityPermissions()
    }

    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                let frontmost = NSWorkspace.shared.frontmostApplication
                if frontmost?.bundleIdentifier != Bundle.main.bundleIdentifier {
                    lastActiveApp = frontmost
                } else {
                    lastActiveApp = nil
                }
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    func restorePreviousApp() {
        guard let app = lastActiveApp else { return }
        app.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
        lastActiveApp = nil
    }

    func registerHotKey() {
        hotKeyCenter = HotKeyCenter.shared

        // Register Command + Shift + V
        if let keyCombo = KeyCombo(key: .v, cocoaModifiers: [.command, .shift]) {
            let hotKey = HotKey(identifier: "ToggleClipboard", keyCombo: keyCombo) { [weak self] _ in
                self?.togglePopover()
            }
            hotKey.register()
        }
    }

    func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        AXIsProcessTrustedWithOptions(options)
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardManager?.stopMonitoring()
    }
}
