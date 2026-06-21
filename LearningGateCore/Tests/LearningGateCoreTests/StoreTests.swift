import XCTest
@testable import LearningGateCore

final class StoreTests: XCTestCase {
    private let deck = DeckID(rawValue: "d")
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testFileStoreRoundTripsAcrossInstances() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let cardA = Card.due("a", deck: deck, secondsAgo: 100, now: now)
        let cardB = Card.due("b", deck: deck, secondsAgo: 50, now: now)
        do {
            let store = try FileCardStore(containerURL: dir)
            try store.saveDeck(Deck(id: deck, name: "D", sourceID: .init(rawValue: "local"),
                                    cards: [cardA, cardB]))
        }
        // New instance reads from disk.
        let reopened = try FileCardStore(containerURL: dir)
        XCTAssertEqual(try reopened.allCards().count, 2)
        let loadedDeck = try XCTUnwrap(reopened.deck(deck))
        XCTAssertEqual(loadedDeck.name, "D")
        XCTAssertEqual(loadedDeck.cards.count, 2)
    }

    func testDueCardsAreSortedAndLimited() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try FileCardStore(containerURL: dir)

        let older = Card.due("older", deck: deck, secondsAgo: 1000, now: now)
        let newer = Card.due("newer", deck: deck, secondsAgo: 10, now: now)
        var future = Card(deckID: deck, front: "future", back: "f")
        future.scheduling.dueDate = now.addingTimeInterval(10_000)
        try store.upsert([newer, future, older])

        let due = try store.dueCards(limit: 5, now: now)
        XCTAssertEqual(due.map { $0.front }, ["older", "newer"]) // soonest-due first, future excluded
        XCTAssertEqual(try store.dueCount(now: now), 2)
        XCTAssertEqual(try store.dueCards(limit: 1, now: now).count, 1)
    }

    func testUpdateMissingCardThrows() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try FileCardStore(containerURL: dir)
        let ghost = Card(deckID: deck, front: "ghost", back: "x")
        XCTAssertThrowsError(try store.update(ghost)) { error in
            XCTAssertEqual(error as? LearningGateError, .cardNotFound(ghost.id))
        }
    }

    func testDeleteDeckRemovesItsCards() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = try FileCardStore(containerURL: dir)
        try store.saveDeck(Deck(id: deck, name: "D", sourceID: .init(rawValue: "local"),
                                cards: [Card.due("a", deck: deck, now: now)]))
        try store.deleteDeck(deck)
        XCTAssertEqual(try store.allCards().count, 0)
        XCTAssertNil(try store.deck(deck))
    }
}
