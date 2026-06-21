import Foundation

/// Persistence seam for the gate policy. The app implements this over the App
/// Group's shared `UserDefaults` (so extensions can read the active N/X); tests
/// use the in-memory default below.
public protocol PolicyStore: AnyObject {
    func loadPolicy() -> GatePolicy?
    func savePolicy(_ policy: GatePolicy)
}

/// Default in-memory implementation for tests and previews.
public final class InMemoryPolicyStore: PolicyStore {
    private var stored: GatePolicy?
    public init(initial: GatePolicy? = nil) { self.stored = initial }
    public func loadPolicy() -> GatePolicy? { stored }
    public func savePolicy(_ policy: GatePolicy) { stored = policy }
}
