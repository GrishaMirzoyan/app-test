import Foundation

/// Simpler Leitner-box scheduler offered as a fallback to SM-2.
///
/// Cards live in numbered boxes; each box has a review interval. A passing grade
/// promotes the card one box (longer interval); `again` demotes it to box 0
/// (due immediately). `hard` holds the card in its current box rather than
/// promoting. Intervals default to a doubling schedule (1, 2, 4, 8, …) capped
/// at the last entry, but can be customised.
public struct LeitnerScheduler: SpacedRepetitionScheduler {
    /// Interval, in days, for each box index. Index 0 is "due immediately".
    public let boxIntervalsDays: [Double]
    private let calendar: Calendar

    public init(
        boxIntervalsDays: [Double] = [0, 1, 2, 4, 8, 16, 32],
        calendar: Calendar = .current
    ) {
        precondition(!boxIntervalsDays.isEmpty, "Leitner needs at least one box")
        self.boxIntervalsDays = boxIntervalsDays
        self.calendar = calendar
    }

    private var maxBox: Int { boxIntervalsDays.count - 1 }

    public func nextState(for state: SchedulingState, grade: ReviewGrade, now: Date) -> SchedulingState {
        var next = state
        switch grade {
        case .again:
            next.leitnerBox = 0
            next.lapses = state.lapses + 1
        case .hard:
            next.leitnerBox = state.leitnerBox            // hold position
        case .good:
            next.leitnerBox = min(state.leitnerBox + 1, maxBox)
        case .easy:
            next.leitnerBox = min(state.leitnerBox + 2, maxBox)
        }

        let interval = boxIntervalsDays[next.leitnerBox]
        next.intervalDays = interval
        next.repetitions = grade.isPass ? state.repetitions + 1 : 0
        next.dueDate = interval > 0
            ? (calendar.date(byAdding: .day, value: Int(interval), to: now) ?? now)
            : now
        return next
    }
}
