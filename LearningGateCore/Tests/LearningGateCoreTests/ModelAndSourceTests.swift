import XCTest
@testable import LearningGateCore

final class ModelAndSourceTests: XCTestCase {
    private let deck = DeckID(rawValue: "d")
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testCardCodableRoundTrip() throws {
        let card = Card(deckID: deck, front: "f", back: "b", tags: ["t1", "t2"])
        let data = try JSONEncoder().encode(card)
        let decoded = try JSONDecoder().decode(Card.self, from: data)
        XCTAssertEqual(card, decoded)
    }

    func testDeckKindCodableIsBareString() throws {
        // RawRepresentable(String) gets the stdlib single-value Codable, so a
        // DeckKind encodes as a plain JSON string — and any unknown raw value
        // (e.g. a future "testPrep") decodes without throwing.
        let encoded = try JSONEncoder().encode(DeckKind.testPrep)
        XCTAssertEqual(String(decoding: encoded, as: UTF8.self), "\"testPrep\"")

        let decoded = try JSONDecoder().decode(DeckKind.self, from: Data("\"future\"".utf8))
        XCTAssertEqual(decoded.rawValue, "future")
    }

    func testCardIsDue() {
        var due = Card(deckID: deck, front: "f", back: "b")
        due.scheduling.dueDate = now.addingTimeInterval(-1)
        XCTAssertTrue(due.isDue(at: now))
        due.scheduling.dueDate = now.addingTimeInterval(1)
        XCTAssertFalse(due.isDue(at: now))
    }

    func testLocalDeckSourceImportsAndPersists() async throws {
        let store = InMemoryCardStore()
        let source = LocalDeckSource(store: store)

        let csv = Data("front,back\nuno,one\ndos,two\n".utf8)
        let imported = try source.importFile(named: "spanish.csv", data: csv)
        XCTAssertEqual(imported.first?.name, "spanish")
        XCTAssertEqual(imported.first?.cards.count, 2)

        let loaded = try await source.loadDecks()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(try store.allCards().count, 2)
        XCTAssertEqual(source.id, LocalDeckSource.sourceID)
    }

    func testLocalDeckSourceRejectsUnknownExtension() {
        let source = LocalDeckSource(store: InMemoryCardStore())
        XCTAssertThrowsError(try source.importFile(named: "deck.pdf", data: Data()))
    }
}
