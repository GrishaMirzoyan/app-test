import XCTest
@testable import LearningGateCore

final class ApkgImporterTests: XCTestCase {
    private let importer = ApkgDeckImporter()
    private let source = DeckSourceID(rawValue: "test")

    func testImportsDecksNotesTagsAndStripsHTML() throws {
        let data = try Fixture.data("sample", "apkg")
        let decks = try importer.importDecks(from: data, defaultName: "Fallback", sourceID: source)

        // Fixture has 4 notes: 2 in "Spanish::Verbs", 1 in "Default", 1 single-field (skipped).
        let byName = Dictionary(uniqueKeysWithValues: decks.map { ($0.name, $0) })
        XCTAssertEqual(Set(byName.keys), ["Spanish::Verbs", "Default"])

        let spanish = try XCTUnwrap(byName["Spanish::Verbs"])
        XCTAssertEqual(spanish.cards.count, 2)
        XCTAssertEqual(spanish.sourceID, source)

        let byFront = Dictionary(uniqueKeysWithValues: spanish.cards.map { ($0.front, $0) })
        XCTAssertEqual(byFront["hola"]?.back, "hello")
        XCTAssertEqual(byFront["hola"]?.tags, ["greeting", "common"])
        // <b>gato</b> -> gato ; cat &amp; pet -> cat & pet
        XCTAssertNotNil(byFront["gato"])
        XCTAssertEqual(byFront["gato"]?.back, "cat & pet")

        XCTAssertEqual(byName["Default"]?.cards.count, 1)
        XCTAssertEqual(byName["Default"]?.cards.first?.front, "perro")
    }

    func testSingleFieldNoteIsSkipped() throws {
        let data = try Fixture.data("sample", "apkg")
        let decks = try importer.importDecks(from: data, defaultName: "Fallback", sourceID: source)
        let totalCards = decks.reduce(0) { $0 + $1.cards.count }
        XCTAssertEqual(totalCards, 3) // 4 notes minus the 1 single-field note
    }

    func testNonZipThrows() {
        let garbage = Data("not a zip".utf8)
        XCTAssertThrowsError(try importer.importDecks(from: garbage, defaultName: "X", sourceID: source))
    }

    func testPlainTextHelper() {
        XCTAssertEqual(ApkgDeckImporter.plainText("<div>hi <b>there</b></div>"), "hi there")
        XCTAssertEqual(ApkgDeckImporter.plainText("a &amp; b &lt;c&gt;"), "a & b <c>")
    }
}
