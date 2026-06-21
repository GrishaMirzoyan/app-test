import Foundation

/// Reward-framed snapshot shown on the stats screen.
public struct Stats: Equatable, Sendable {
    /// Total review attempts ever logged.
    public var cardsReviewed: Int
    /// Consecutive days (ending today) with at least one review.
    public var currentStreakDays: Int
    /// Number of breaks the learner has earned.
    public var breaksEarned: Int

    public init(cardsReviewed: Int, currentStreakDays: Int, breaksEarned: Int) {
        self.cardsReviewed = cardsReviewed
        self.currentStreakDays = currentStreakDays
        self.breaksEarned = breaksEarned
    }

    public static let empty = Stats(cardsReviewed: 0, currentStreakDays: 0, breaksEarned: 0)
}

/// Sink for review and break events. The unlock loop writes here; the stats
/// service reads back aggregates. Split from `CardStore` so the log can grow
/// (or be truncated) independently of the card data.
public protocol ReviewRecorder: AnyObject {
    func record(_ log: ReviewLog)
    func recordBreakEarned(_ event: BreakEarnedLog)
}

/// Read side: computes the reward-framed `Stats` snapshot.
public protocol StatsService {
    func current(now: Date) -> Stats
}
