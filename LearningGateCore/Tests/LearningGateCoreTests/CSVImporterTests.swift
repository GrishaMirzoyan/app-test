import XCTest
@testable import LearningGateCore

final class CSVImporterTests: XCTestCase {
    private let importer = CSVDeckImporter()
    private let source = DeckSourceID(rawValue: "test")

    func testParsesFixtureWithQuotingAndMultiline() throws {
        let data = try Fixture.data("sample", "csv")
        let decks = try importer.importDecks(from: data, defaultName: "French", sourceID: source)

        XCTAssertEqual(decks.count, 1)
        let deck = try XCTUnwrap(decks.first)
        XCTAssertEqual(deck.name, "French")
        XCTAssertEqual(deck.cards.count, 4) // header skipped

        let byFront = Dictionary(uniqueKeysWithValues: deck.cards.map { ($0.front, $0) })
        XCTAssertEqual(byFront["bonjour"]?.back, "hello")
        XCTAssertEqual(byFront["bonjour"]?.tags, ["greeting", "french"])
        // Quoted field preserves the embedded comma.
        XCTAssertEqual(byFront["merci, beaucoup"]?.back, "thank you very much")
        // Quoted multiline field preserved.
        XCTAssertEqual(byFront["line one\nline two"]?.back, "multi\nline back")
        XCTAssertEqual(byFront["au revoir"]?.tags, [])
    }

    func testHeaderlessInlineCSV() throws {
        let csv = "perro,dog\ngato,cat\n"
        let data = Data(csv.utf8)
        let decks = try importer.importDecks(from: data, defaultName: "Spanish", sourceID: source)
        XCTAssertEqual(decks.first?.cards.count, 2)
    }

    func testTabDelimited() throws {
        let tsv = "front\tback\nuno\tone\n"
        let decks = try CSVDeckImporter(delimiter: "\t")
            .importDecks(from: Data(tsv.utf8), defaultName: "X", sourceID: source)
        XCTAssertEqual(decks.first?.cards.count, 1)
        XCTAssertEqual(decks.first?.cards.first?.front, "uno")
    }

    func testEmptyThrows() {
        XCTAssertThrowsError(try importer.importDecks(from: Data(), defaultName: "X", sourceID: source))
    }

    func testRowsWithoutBackAreSkipped() throws {
        let csv = "front,back\nlonely\ngood,ok\n"
        let decks = try importer.importDecks(from: Data(csv.utf8), defaultName: "X", sourceID: source)
        XCTAssertEqual(decks.first?.cards.count, 1)
        XCTAssertEqual(decks.first?.cards.first?.front, "good")
    }
}
