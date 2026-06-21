import Foundation

/// Classic SuperMemo SM-2 scheduler.
///
/// Reference: P.A. Wozniak, "Optimization of repetition spacing in the practice
/// of learning" (1990). We map our four review grades onto SM-2's 0–5 response
/// quality `q`:
///
///   again → 2  (failed recall: q < 3 triggers a lapse)
///   hard  → 3
///   good  → 4
///   easy  → 5
///
/// On a passing grade the interval grows 1 day → 6 days → previous × easeFactor.
/// On `again` the card lapses: repetitions reset and it becomes due immediately
/// (the unlock loop re-queues it within the session). The ease factor is nudged
/// by `q` every review and floored at 1.3, exactly as in SM-2.
public struct SM2Scheduler: SpacedRepetitionScheduler {
    /// Lower bound on the ease factor, per the original algorithm.
    public static let minimumEaseFactor = 1.3
    /// Calendar used to advance the due date by whole days.
    private let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    private func quality(for grade: ReviewGrade) -> Int {
        switch grade {
        case .again: return 2
        case .hard:  return 3
        case .good:  return 4
        case .easy:  return 5
        }
    }

    public func nextState(for state: SchedulingState, grade: ReviewGrade, now: Date) -> SchedulingState {
        var next = state
        let q = quality(for: grade)

        // SM-2 ease-factor update: EF' = EF + (0.1 - (5-q)(0.08 + (5-q)0.02))
        let delta = 0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02)
        next.easeFactor = max(Self.minimumEaseFactor, state.easeFactor + delta)

        if grade.isPass {
            switch state.repetitions {
            case 0:
                next.intervalDays = 1
            case 1:
                next.intervalDays = 6
            default:
                next.intervalDays = (state.intervalDays * next.easeFactor).rounded()
            }
            next.repetitions = state.repetitions + 1
            next.dueDate = addDays(next.intervalDays, to: now)
        } else {
            // Lapse: relearn from scratch, due again right away.
            next.repetitions = 0
            next.intervalDays = 0
            next.lapses = state.lapses + 1
            next.dueDate = now
        }
        return next
    }

    private func addDays(_ days: Double, to date: Date) -> Date {
        // Whole-day component via the calendar, plus any fractional remainder as
        // seconds, so non-integer intervals (rare here) still advance correctly.
        let whole = Int(days)
        let base = calendar.date(byAdding: .day, value: whole, to: date) ?? date
        let fractional = days - Double(whole)
        return fractional > 0 ? base.addingTimeInterval(fractional * 86_400) : base
    }
}
