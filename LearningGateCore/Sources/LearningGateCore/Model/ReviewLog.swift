import Foundation

/// An append-only record of a single review event. Drives stats (cards
/// reviewed, streaks) and could later feed analytics or sync. Kept separate
/// from `Card` so the card store stays small and the log can be truncated.
public struct ReviewLog: Codable, Equatable, Sendable {
    public let cardID: CardID
    public let deckID: DeckID
    public let grade: ReviewGrade
    public let reviewedAt: Date
    /// Interval (days) assigned *after* this review — useful for retention math.
    public let resultingIntervalDays: Double

    public init(
        cardID: CardID,
        deckID: DeckID,
        grade: ReviewGrade,
        reviewedAt: Date,
        resultingIntervalDays: Double
    ) {
        self.cardID = cardID
        self.deckID = deckID
        self.grade = grade
        self.reviewedAt = reviewedAt
        self.resultingIntervalDays = resultingIntervalDays
    }
}

/// Records that the learner earned a break by passing an unlock session.
/// Counted by the stats service as "breaks earned" (reward-framed copy).
public struct BreakEarnedLog: Codable, Equatable, Sendable {
    public let earnedAt: Date
    public let cardsReviewed: Int
    public let breakDuration: TimeInterval

    public init(earnedAt: Date, cardsReviewed: Int, breakDuration: TimeInterval) {
        self.earnedAt = earnedAt
        self.cardsReviewed = cardsReviewed
        self.breakDuration = breakDuration
    }
}
