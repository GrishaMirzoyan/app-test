import Foundation

/// Non-persistent `CardStore` for tests and SwiftUI previews.
public final class InMemoryCardStore: CardStore {
    private var cardsByID: [CardID: Card] = [:]
    private var decksByID: [DeckID: Deck] = [:]
    private let lock = NSRecursiveLock()

    public init(cards: [Card] = [], decks: [Deck] = []) {
        for c in cards { cardsByID[c.id] = c }
        for d in decks { decksByID[d.id] = d }
    }

    public func allCards() throws -> [Card] {
        lock.lock(); defer { lock.unlock() }
        return Array(cardsByID.values)
    }

    public func card(_ id: CardID) throws -> Card? {
        lock.lock(); defer { lock.unlock() }
        return cardsByID[id]
    }

    public func dueCards(limit: Int, now: Date) throws -> [Card] {
        lock.lock(); defer { lock.unlock() }
        let due = cardsByID.values
            .filter { $0.scheduling.dueDate <= now }
            .sorted { $0.scheduling.dueDate < $1.scheduling.dueDate }
        return Array(due.prefix(max(0, limit)))
    }

    public func dueCount(now: Date) throws -> Int {
        lock.lock(); defer { lock.unlock() }
        return cardsByID.values.lazy.filter { $0.scheduling.dueDate <= now }.count
    }

    public func upsert(_ cards: [Card]) throws {
        lock.lock(); defer { lock.unlock() }
        for card in cards { cardsByID[card.id] = card }
    }

    public func update(_ card: Card) throws {
        lock.lock(); defer { lock.unlock() }
        guard cardsByID[card.id] != nil else { throw LearningGateError.cardNotFound(card.id) }
        cardsByID[card.id] = card
    }

    public func allDecks() throws -> [Deck] {
        lock.lock(); defer { lock.unlock() }
        return Array(decksByID.values)
    }

    public func deck(_ id: DeckID) throws -> Deck? {
        lock.lock(); defer { lock.unlock() }
        return decksByID[id]
    }

    public func saveDeck(_ deck: Deck) throws {
        lock.lock(); defer { lock.unlock() }
        decksByID[deck.id] = deck
        for card in deck.cards { cardsByID[card.id] = card }
    }

    public func deleteDeck(_ id: DeckID) throws {
        lock.lock(); defer { lock.unlock() }
        guard decksByID.removeValue(forKey: id) != nil else {
            throw LearningGateError.deckNotFound(id)
        }
        for (cardID, card) in cardsByID where card.deckID == id {
            cardsByID.removeValue(forKey: cardID)
        }
    }
}
