import Foundation
import ManagedSettings
import FamilyControls
import DeviceActivity
import LearningGateCore

/// Concrete `BlockingController` (from LearningGateCore) backed by Screen Time.
///
/// Lives in the app/extension layer — never in the core — because it depends on
/// ManagedSettings / DeviceActivity. Used by the main app (apply shield after
/// onboarding, grant break after a passed unlock) and by the DeviceActivity
/// monitor (re-apply when a break window ends).
///
/// VERIFY (device-only, see VERIFY.md): the exact one-shot "re-shield after X
/// minutes" behaviour relies on a DeviceActivitySchedule from now → now+X and
/// the monitor's `intervalDidEnd`. Schedule granularity is to the minute; this
/// cannot be validated in the simulator.
final class ScreenTimeBlockingController: BlockingController {
    private let store: ManagedSettingsStore
    private let center = DeviceActivityCenter()
    private let selectionStore: SelectionStore

    init(selectionStore: SelectionStore = SelectionStore()) {
        self.store = ManagedSettingsStore(named: .init(GateNames.store))
        self.selectionStore = selectionStore
    }

    var isShielded: Bool {
        // Non-nil shield.applications means the shield is currently applied.
        (store.shield.applications?.isEmpty == false)
            || (store.shield.webDomains?.isEmpty == false)
            || store.shield.applicationCategories != nil
    }

    func applyShield() {
        guard let selection = selectionStore.load() else { return }
        ShieldApplier.apply(selection: selection, to: store)

        // A break may have been scheduled; cancel it now that we're shielded.
        center.stopMonitoring([.init(GateNames.breakSchedule)])
    }

    func grantBreak(for duration: TimeInterval) {
        // Lift the shield immediately…
        ShieldApplier.clear(store)

        // …and schedule a window so the monitor re-applies it when time's up.
        let now = Date()
        let calendar = Calendar.current
        let start = calendar.dateComponents([.hour, .minute, .second], from: now)
        let end = calendar.dateComponents(
            [.hour, .minute, .second], from: now.addingTimeInterval(duration)
        )
        let schedule = DeviceActivitySchedule(
            intervalStart: start, intervalEnd: end, repeats: false
        )
        do {
            try center.startMonitoring(.init(GateNames.breakSchedule), during: schedule)
        } catch {
            // If scheduling fails we fail safe by re-applying the shield now.
            applyShield()
        }
    }
}
