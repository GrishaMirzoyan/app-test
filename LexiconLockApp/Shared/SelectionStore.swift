import Foundation
import FamilyControls

/// Persists the user's chosen apps/categories (a `FamilyActivitySelection`) in
/// the shared App Group so both the main app and the DeviceActivity monitor can
/// read it to (re)apply the shield.
///
/// The tokens inside the selection are OPAQUE — we only ever store and pass them
/// to ManagedSettings; we never try to read app names from them.
struct SelectionStore {
    private let defaults: UserDefaults
    init(defaults: UserDefaults = AppGroup.defaults) { self.defaults = defaults }

    func save(_ selection: FamilyActivitySelection) {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        defaults.set(data, forKey: SharedDefaultsKey.selection)
    }

    func load() -> FamilyActivitySelection? {
        guard let data = defaults.data(forKey: SharedDefaultsKey.selection) else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    var hasSelection: Bool {
        let selection = load()
        guard let selection else { return false }
        return !selection.applicationTokens.isEmpty
            || !selection.categoryTokens.isEmpty
            || !selection.webDomainTokens.isEmpty
    }
}
