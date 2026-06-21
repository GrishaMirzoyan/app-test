import Foundation

/// Who controls the gate, and under what rules.
///
/// This is the seam that lets v1's individual self-control mode and a future
/// parent-controlled kids' mode coexist without a rewrite. The unlock loop and
/// UI ask the controller for the active `policy` and whether the *current user*
/// is allowed to change it. In self mode the user can; in a parent-controlled
/// mode `canCurrentUserEditPolicy` returns false and `updatePolicy` throws
/// unless an authorised controller (e.g. one holding a parent passcode) is used.
public protocol GateController: AnyObject {
    /// The currently active rules.
    var policy: GatePolicy { get }

    /// Whether the person using the device right now may edit the policy.
    var canCurrentUserEditPolicy: Bool { get }

    /// Update the policy. Throws `GateControlError.notAuthorized` when the
    /// current user isn't allowed to change it.
    func updatePolicy(_ newPolicy: GatePolicy) throws
}

public enum GateControlError: Error, Equatable {
    case notAuthorized
}
