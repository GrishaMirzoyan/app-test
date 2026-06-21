import Foundation

/// The grade a learner gives a card during review.
///
/// Modelled on Anki's four-button scheme. Numeric raw values are stable and
/// safe to persist. `again` means "I didn't recall it" (a lapse); the rest are
/// passing grades of increasing confidence.
public enum ReviewGrade: Int, Codable, CaseIterable, Sendable {
    case again = 0
    case hard  = 1
    case good  = 2
    case easy  = 3

    /// Whether this grade counts as a successful recall (used by the unlock
    /// loop's pass threshold and by the schedulers' lapse handling).
    public var isPass: Bool { self != .again }
}

/// Per-card spaced-repetition state. Deliberately holds the union of fields
/// needed by *both* schedulers (SM-2 and Leitner) so a deck can switch
/// strategies without a data migration.
public struct SchedulingState: Codable, Equatable, Sendable {
    /// When the card next becomes due for review.
    public var dueDate: Date
    /// Current inter-repetition interval, in days. Fractional during learning.
    public var intervalDays: Double
    /// SM-2 ease factor (a.k.a. E-Factor); clamped to a floor of 1.3.
    public var easeFactor: Double
    /// Number of consecutive successful repetitions (SM-2 `n`).
    public var repetitions: Int
    /// How many times the card has lapsed (graded `again` after graduating).
    public var lapses: Int
    /// Current Leitner box index (used only by `LeitnerScheduler`).
    public var leitnerBox: Int

    public init(
        dueDate: Date,
        intervalDays: Double,
        easeFactor: Double,
        repetitions: Int,
        lapses: Int,
        leitnerBox: Int
    ) {
        self.dueDate = dueDate
        self.intervalDays = intervalDays
        self.easeFactor = easeFactor
        self.repetitions = repetitions
        self.lapses = lapses
        self.leitnerBox = leitnerBox
    }

    /// State for a brand-new card: due immediately, default ease, box 0.
    public static func new(due: Date = Date()) -> SchedulingState {
        SchedulingState(
            dueDate: due,
            intervalDays: 0,
            easeFactor: 2.5,
            repetitions: 0,
            lapses: 0,
            leitnerBox: 0
        )
    }
}
