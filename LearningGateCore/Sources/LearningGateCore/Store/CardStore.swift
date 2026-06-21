import Foundation

/// Errors surfaced by the persistence and import layers.
public enum LearningGateError: Error, Equatable {
    case deckNotFound(DeckID)
    case cardNotFound(CardID)
    case importFailed(String)
    case storageFailed(String)
}

/// Abstraction over card/deck persistence so the scheduler and unlock loop can
/// be tested against an in-memory double, and so the storage backend (JSON
/// file now, SQLite later) can change without touching callers.
///
/// Implementations must be safe to use from the main app and the extensions,
/// which share one App Group container — but note extensions should only read
/// here; heavy writes belong in the main app (see project gotchas).
public protocol CardStore: AnyObject {
    func allCards() throws -> [Card]
    func card(_ id: CardID) throws -> Card?
    /// Cards whose `dueDate <= now`, soonest-due first, capped at `limit`.
    func dueCards(limit: Int, now: Date) throws -> [Card]
    func dueCount(now: Date) throws -> Int

    /// Insert new cards or replace existing ones (matched by `id`).
    func upsert(_ cards: [Card]) throws
    func update(_ card: Card) throws

    func allDecks() throws -> [Deck]
    func deck(_ id: DeckID) throws -> Deck?
    func saveDeck(_ deck: Deck) throws
    func deleteDeck(_ id: DeckID) throws
}
