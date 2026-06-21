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

    func testDeckKindDecodesUnknownValueGracefully() throws {
        let json = Data(#"{"rawValue":"testPrep"}"#.utf8)
        let kind = try JSONDecoder().decode(DeckKind.self, from: json)
        XCTAssertEqual(kind.rawValue, "testPrep") // forward-compatible for future deck types
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
