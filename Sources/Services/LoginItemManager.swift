import Foundation

/// Keeps iClippy running as a background agent: started at login and restarted
/// automatically if it ever dies unexpectedly.
///
/// This is implemented with a per-user LaunchAgent in `~/Library/LaunchAgents`
/// rather than `SMAppService`, because a LaunchAgent can express `KeepAlive` —
/// `SMAppService.mainApp` only starts the app at login and gives up after that.
///
/// `KeepAlive` is deliberately `{ SuccessfulExit = false }` instead of `true`:
/// launchd then restarts iClippy after a crash or a force-quit, but honours a
/// clean exit. That is what makes the "Quit iClippy" menu item work, and it also
/// stops a duplicate instance (see `AppDelegate`'s single-instance check) from
/// being respawned in a loop.
enum LoginItemManager {
    static let startAtLoginKey = "startAtLogin"

    static let agentLabel = "com.iclippy.app"

    private static var launchAgentsDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
    }

    private static var agentPlistURL: URL {
        launchAgentsDirectory.appendingPathComponent("\(agentLabel).plist")
    }

    private static var logDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs", isDirectory: true)
    }

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
        applySetting(isStartAtLoginEnabled())
    }

    /// Persists and applies the setting.
    static func setStartAtLogin(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: startAtLoginKey)
        applySetting(enabled)
    }

    private static func applySetting(_ enabled: Bool) {
        if enabled {
            installAgent()
        } else {
            removeAgent()
        }
    }

    // MARK: - Agent installation

    /// Writes (or refreshes) the LaunchAgent and loads it if it isn't loaded yet.
    ///
    /// Refreshing matters when the app has been moved — for example run once from
    /// `~/Downloads` and later dragged to `/Applications` — because the agent
    /// records an absolute path to the executable.
    private static func installAgent() {
        guard let executablePath = Bundle.main.executableURL?.resolvingSymlinksInPath().path else {
            NSLog("iClippy: cannot determine executable path; skipping launch-at-login setup")
            return
        }

        let desired = agentPlist(executablePath: executablePath)

        if desired != existingAgentPlist() {
            do {
                try FileManager.default.createDirectory(
                    at: launchAgentsDirectory,
                    withIntermediateDirectories: true
                )
                let data = try PropertyListSerialization.data(
                    fromPropertyList: desired,
                    format: .xml,
                    options: 0
                )
                try data.write(to: agentPlistURL, options: .atomic)
                NSLog("iClippy: wrote launch agent to \(agentPlistURL.path)")
            } catch {
                NSLog("iClippy: failed to write launch agent: \(error)")
                return
            }
        }

        // Loading an already-loaded job fails harmlessly, but skipping the call
        // keeps the noise down. Note that we never *unload* the job here: booting
        // out the agent would kill this very process.
        guard !isAgentLoaded() else { return }

        let status = runLaunchctl(["bootstrap", "gui/\(getuid())", agentPlistURL.path])
        if status == 0 {
            NSLog("iClippy: launch agent loaded")
        } else {
            NSLog("iClippy: launchctl bootstrap exited with status \(status)")
        }
    }

    /// Removes the agent definition so it is not started at the next login.
    ///
    /// The currently loaded job is intentionally left alone — booting it out
    /// would terminate the running app the moment the user turned the setting
    /// off. Without the plist, it simply won't come back after logout.
    private static func removeAgent() {
        guard FileManager.default.fileExists(atPath: agentPlistURL.path) else { return }
        do {
            try FileManager.default.removeItem(at: agentPlistURL)
            NSLog("iClippy: launch agent removed; iClippy will not start at next login")
        } catch {
            NSLog("iClippy: failed to remove launch agent: \(error)")
        }
    }

    // MARK: - Plist

    private static func agentPlist(executablePath: String) -> NSDictionary {
        [
            "Label": agentLabel,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            // Restart on crash or force-quit, but not after a clean exit.
            "KeepAlive": ["SuccessfulExit": false],
            "ThrottleInterval": 10,
            // Only run in a graphical login session; this is a menu bar app.
            "LimitLoadToSessionType": "Aqua",
            "ProcessType": "Interactive",
            "StandardOutPath": logDirectory.appendingPathComponent("iClippy.log").path,
            "StandardErrorPath": logDirectory.appendingPathComponent("iClippy.error.log").path,
        ] as NSDictionary
    }

    private static func existingAgentPlist() -> NSDictionary? {
        guard let data = try? Data(contentsOf: agentPlistURL) else { return nil }
        let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        return plist as? NSDictionary
    }

    // MARK: - launchctl

    static func isAgentLoaded() -> Bool {
        runLaunchctl(["print", "gui/\(getuid())/\(agentLabel)"]) == 0
    }

    @discardableResult
    private static func runLaunchctl(_ arguments: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            NSLog("iClippy: failed to run launchctl \(arguments.joined(separator: " ")): \(error)")
            return -1
        }

        process.waitUntilExit()
        return process.terminationStatus
    }
}
