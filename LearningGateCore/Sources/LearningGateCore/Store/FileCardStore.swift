import Foundation

/// JSON-file backed `CardStore` living inside an injected directory.
///
/// The app passes its App Group container URL; tests pass a temp directory.
/// Deck metadata and cards are persisted in two files so due-card queries don't
/// have to walk nested deck structures. Access is serialised with a lock; this
/// is adequate for v1 where extensions read and the main app writes. A future
/// SQLite-backed store can replace this behind the same protocol.
public final class FileCardStore: CardStore {
    private let directory: URL
    private let cardsURL: URL
    private let decksURL: URL
    private let lock = NSRecursiveLock()

    private var cardsByID: [CardID: Card]
    private var decksByID: [DeckID: DeckMetadata]

    /// Deck without its cards — cards are stored once, in the cards file.
    private struct DeckMetadata: Codable {
        let id: DeckID
        var name: String
        var kind: DeckKind
        var sourceID: DeckSourceID
    }

    public init(containerURL: URL) throws {
        self.directory = containerURL
        self.cardsURL = containerURL.appendingPathComponent("cards.json")
        self.decksURL = containerURL.appendingPathComponent("decks.json")

        try FileManager.default.createDirectory(
            at: containerURL, withIntermediateDirectories: true
        )

        let decoder = JSONDecoder()
        if let data = try? Data(contentsOf: cardsURL),
           let cards = try? decoder.decode([Card].self, from: data) {
            self.cardsByID = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })
        } else {
            self.cardsByID = [:]
        }
        if let data = try? Data(contentsOf: decksURL),
           let decks = try? decoder.decode([DeckMetadata].self, from: data) {
            self.decksByID = Dictionary(uniqueKeysWithValues: decks.map { ($0.id, $0) })
        } else {
            self.decksByID = [:]
        }
    }

    // MARK: - Cards

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
        try persistCards()
    }

    public func update(_ card: Card) throws {
        lock.lock(); defer { lock.unlock() }
        guard cardsByID[card.id] != nil else { throw LearningGateError.cardNotFound(card.id) }
        cardsByID[card.id] = card
        try persistCards()
    }

    // MARK: - Decks

    public func allDecks() throws -> [Deck] {
        lock.lock(); defer { lock.unlock() }
        return decksByID.values.map { hydrate($0) }
    }

    public func deck(_ id: DeckID) throws -> Deck? {
        lock.lock(); defer { lock.unlock() }
        return decksByID[id].map { hydrate($0) }
    }

    public func saveDeck(_ deck: Deck) throws {
        lock.lock(); defer { lock.unlock() }
        decksByID[deck.id] = DeckMetadata(
            id: deck.id, name: deck.name, kind: deck.kind, sourceID: deck.sourceID
        )
        for card in deck.cards { cardsByID[card.id] = card }
        try persistDecks()
        try persistCards()
    }

    public func deleteDeck(_ id: DeckID) throws {
        lock.lock(); defer { lock.unlock() }
        guard decksByID.removeValue(forKey: id) != nil else {
            throw LearningGateError.deckNotFound(id)
        }
        for (cardID, card) in cardsByID where card.deckID == id {
            cardsByID.removeValue(forKey: cardID)
        }
        try persistDecks()
        try persistCards()
    }

    // MARK: - Helpers

    private func hydrate(_ meta: DeckMetadata) -> Deck {
        let cards = cardsByID.values.filter { $0.deckID == meta.id }
        return Deck(id: meta.id, name: meta.name, kind: meta.kind,
                    sourceID: meta.sourceID, cards: cards)
    }

    private func persistCards() throws {
        do {
            let data = try JSONEncoder().encode(Array(cardsByID.values))
            try data.write(to: cardsURL, options: .atomic)
        } catch {
            throw LearningGateError.storageFailed("cards: \(error)")
        }
    }

    private func persistDecks() throws {
        do {
            let data = try JSONEncoder().encode(Array(decksByID.values))
            try data.write(to: decksURL, options: .atomic)
        } catch {
            throw LearningGateError.storageFailed("decks: \(error)")
        }
    }
}
