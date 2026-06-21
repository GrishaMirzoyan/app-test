import Foundation

/// Shared identifiers used by the app and all three extensions. They must match
/// the App Group and ManagedSettings/DeviceActivity names configured in the
/// Xcode capabilities (see README). Change `appGroupID` to your own group.
enum AppGroup {
    /// ⚠️ Replace with your real App Group ID (Signing & Capabilities → App Groups).
    static let id = "group.com.example.lexiconlock"

    /// Shared container URL for the App Group. Falls back to a per-process temp
    /// directory only so debug builds don't crash before the capability is set;
    /// in that case data is not actually shared with the extensions.
    static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("lexiconlock-fallback", isDirectory: true)
    }

    /// Shared defaults for small values (selection blob, active policy).
    static var defaults: UserDefaults {
        UserDefaults(suiteName: id) ?? .standard
    }
}

/// Stable names for the ManagedSettings store and DeviceActivity schedule.
enum GateNames {
    /// Name of the ManagedSettingsStore that holds the shield.
    static let store = "lexiconLockGate"
    /// DeviceActivity schedule that fires when a granted break expires.
    static let breakSchedule = "lexiconLockBreak"
}

/// Keys for values kept in the shared `UserDefaults`.
enum SharedDefaultsKey {
    static let selection = "familyActivitySelection"
    static let policy = "gatePolicy"
    /// Set by the Shield Action extension to signal the app to start a review.
    static let pendingUnlock = "pendingUnlockRequested"
}
