import Foundation

/// Outcome of an in-progress or finished unlock session.
public enum UnlockResult: Equatable, Sendable {
    /// More cards must be passed before the break is earned.
    case inProgress(remaining: Int)
    /// Enough cards passed — grant a break of this length, then re-shield.
    case passed(grantDuration: TimeInterval)
}
