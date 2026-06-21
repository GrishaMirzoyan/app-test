import Foundation

/// Where decks come from. v1 ships `LocalDeckSource` (file imports); later a
/// remote or parent-assigned source can conform to the same protocol and the
/// rest of the app won't care.
public protocol DeckSource {
    var id: DeckSourceID { get }
    /// Load all decks currently available from this source.
    func loadDecks() async throws -> [Deck]
}

/// Turns raw imported bytes (CSV, .apkg, …) into decks. Pure and synchronous so
/// it's trivially unit-testable; file/zip/SQLite I/O is done in-memory from the
/// provided `Data`.
public protocol DeckImporter {
    /// File extensions this importer accepts, lowercased, without the dot.
    var supportedExtensions: [String] { get }

    /// Parse `data` into one or more decks.
    /// - Parameters:
    ///   - defaultName: name to use when the format carries none (e.g. CSV).
    ///   - sourceID: tagged onto produced decks for grouping by origin.
    func importDecks(from data: Data, defaultName: String, sourceID: DeckSourceID) throws -> [Deck]
}
