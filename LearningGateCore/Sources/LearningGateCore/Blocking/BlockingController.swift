import Foundation

/// Applies and lifts the shield over the user's chosen apps.
///
/// Declared here as a protocol only. The concrete implementation lives in the
/// app target and wraps `ManagedSettingsStore` / `DeviceActivityCenter`, because
/// `LearningGateCore` must stay free of FamilyControls/ManagedSettings so it can
/// be reused (and unit-tested on plain Swift). The unlock loop talks to this
/// interface; tests inject a spy.
public protocol BlockingController: AnyObject {
    /// Whether the shield is currently applied.
    var isShielded: Bool { get }

    /// Apply the shield to the configured app tokens immediately.
    func applyShield()

    /// Lift the shield for `duration`. The implementation also schedules a
    /// DeviceActivity window so the monitor re-applies the shield when the
    /// break expires (the core does not own timers).
    func grantBreak(for duration: TimeInterval)
}
