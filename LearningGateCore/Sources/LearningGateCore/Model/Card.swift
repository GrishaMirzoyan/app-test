import Foundation

/// A single flashcard: a front/back pair plus its scheduling state.
///
/// Cards are intentionally free of any presentation or Screen Time concern so
/// the model can be reused by kids-mode and test-prep deck types later.
public struct Card: Identifiable, Codable, Equatable, Sendable {
    public let id: CardID
    public var deckID: DeckID
    public var front: String
    public var back: String
    public var tags: [String]
    public var scheduling: SchedulingState

    public init(
        id: CardID = .generate(),
        deckID: DeckID,
        front: String,
        back: String,
        tags: [String] = [],
        scheduling: SchedulingState = .new()
    ) {
        self.id = id
        self.deckID = deckID
        self.front = front
        self.back = back
        self.tags = tags
        self.scheduling = scheduling
    }

    /// Whether this card is due for review at `now`.
    public func isDue(at now: Date = Date()) -> Bool {
        scheduling.dueDate <= now
    }
}
