import Foundation

/// Strategy for advancing a card's `SchedulingState` after a review.
///
/// Abstracted so a deck (or a future deck *kind*, like test-prep) can choose
/// SM-2 or the simpler Leitner system without callers changing. Implementations
/// must be pure and deterministic given `now` so they are unit-testable.
public protocol SpacedRepetitionScheduler {
    /// Compute the next scheduling state for a card reviewed with `grade` at `now`.
    func nextState(for state: SchedulingState, grade: ReviewGrade, now: Date) -> SchedulingState

    /// Whether a card in `state` is due at `now`.
    func isDue(_ state: SchedulingState, now: Date) -> Bool
}

public extension SpacedRepetitionScheduler {
    func isDue(_ state: SchedulingState, now: Date) -> Bool {
        state.dueDate <= now
    }
}
