import Foundation
import ManagedSettings
import FamilyControls

/// Core-free shield apply/clear logic shared by the main app's
/// `ScreenTimeBlockingController` and the lightweight DeviceActivity monitor
/// extension (which must avoid linking LearningGateCore to stay within the
/// extension memory budget).
enum ShieldApplier {
    static func store() -> ManagedSettingsStore {
        ManagedSettingsStore(named: .init(GateNames.store))
    }

    static func apply(selection: FamilyActivitySelection, to store: ManagedSettingsStore) {
        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil : selection.applicationTokens
        store.shield.webDomains = selection.webDomainTokens.isEmpty
            ? nil : selection.webDomainTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil : .specific(selection.categoryTokens)
    }

    static func clear(_ store: ManagedSettingsStore) {
        store.shield.applications = nil
        store.shield.webDomains = nil
        store.shield.applicationCategories = nil
    }
}
