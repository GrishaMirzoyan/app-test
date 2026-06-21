import Foundation
import LearningGateCore

/// `PolicyStore` (from LearningGateCore) backed by the App Group's shared
/// `UserDefaults`, so the active N (cards) / X (minutes) policy is visible to
/// the extensions as well as the app.
final class UserDefaultsPolicyStore: PolicyStore {
    private let defaults: UserDefaults
    init(defaults: UserDefaults = AppGroup.defaults) { self.defaults = defaults }

    func loadPolicy() -> GatePolicy? {
        guard let data = defaults.data(forKey: SharedDefaultsKey.policy) else { return nil }
        return try? JSONDecoder().decode(GatePolicy.self, from: data)
    }

    func savePolicy(_ policy: GatePolicy) {
        guard let data = try? JSONEncoder().encode(policy) else { return }
        defaults.set(data, forKey: SharedDefaultsKey.policy)
    }
}
