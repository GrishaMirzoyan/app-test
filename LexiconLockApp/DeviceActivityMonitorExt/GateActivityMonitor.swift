import DeviceActivity
import Foundation

/// Re-applies the shield when a granted break window ends.
///
/// The main app, on a passed unlock, lifts the shield and schedules a one-shot
/// DeviceActivity window of length X (the break). When that window ends the
/// system wakes this extension's `intervalDidEnd`, where we re-apply the shield.
/// Kept deliberately tiny — no LearningGateCore link — to respect the extension
/// memory budget.
///
/// VERIFY (device-only): one-shot timing precision and that `intervalDidEnd`
/// fires reliably must be validated on a real device (see VERIFY.md).
final class GateActivityMonitor: DeviceActivityMonitor {
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity == .init(GateNames.breakSchedule) else { return }
        reapplyShield()
    }

    private func reapplyShield() {
        guard let selection = SelectionStore().load() else { return }
        ShieldApplier.apply(selection: selection, to: ShieldApplier.store())
    }
}
