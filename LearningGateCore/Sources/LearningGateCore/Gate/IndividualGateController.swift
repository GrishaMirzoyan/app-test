import Foundation

/// v1 gate controller: the individual learner controls their own gate.
///
/// The user may freely edit the policy. A future `ParentControlledGateController`
/// can conform to the same `GateController` protocol but return
/// `canCurrentUserEditPolicy == false` for the child and gate `updatePolicy`
/// behind a parent passcode — no changes needed in the unlock loop or UI.
public final class IndividualGateController: GateController {
    private let store: PolicyStore
    private var cached: GatePolicy

    public init(store: PolicyStore, defaultPolicy: GatePolicy = .default) {
        self.store = store
        self.cached = store.loadPolicy() ?? defaultPolicy
        if store.loadPolicy() == nil { store.savePolicy(cached) }
    }

    public var policy: GatePolicy { cached }

    public var canCurrentUserEditPolicy: Bool { true }

    public func updatePolicy(_ newPolicy: GatePolicy) throws {
        cached = newPolicy
        store.savePolicy(newPolicy)
    }
}
