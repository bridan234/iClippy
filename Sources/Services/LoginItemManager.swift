import Foundation
import ServiceManagement

enum LoginItemManager {
    static let startAtLoginKey = "startAtLogin"

    /// Returns the user's preference, defaulting to true on first launch.
    static func isStartAtLoginEnabled() -> Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: startAtLoginKey) == nil {
            defaults.set(true, forKey: startAtLoginKey)
        }
        return defaults.bool(forKey: startAtLoginKey)
    }

    /// Applies the stored preference on app launch.
    static func configureOnLaunch() {
        let enabled = isStartAtLoginEnabled()
        applySetting(enabled)
    }

    /// Persists and applies the setting.
    static func setStartAtLogin(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: startAtLoginKey)
        applySetting(enabled)
    }

    private static func applySetting(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp

            switch service.status {
            case .enabled:
                if !enabled {
                    do {
                        try service.unregister()
                        print("✅ Launch at login disabled")
                    } catch {
                        print("⚠️ Failed to disable launch at login: \(error)")
                    }
                }
            case .notRegistered:
                if enabled {
                    do {
                        try service.register()
                        print("✅ Launch at login enabled")
                    } catch {
                        print("⚠️ Failed to enable launch at login: \(error)")
                    }
                }
            case .requiresApproval:
                if enabled {
                    print("⚠️ Launch at login requires user approval in System Settings")
                }
            @unknown default:
                print("⚠️ Launch at login in unknown state")
            }
        } else {
            if enabled {
                print("ℹ️ Launch at login requires manual setup on macOS 12")
            } else {
                print("ℹ️ Launch at login disabled (macOS 12 requires manual removal)")
            }
        }
    }
}
