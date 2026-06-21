import Foundation

/// v1 deck source: decks the user has imported into the local `CardStore`.
///
/// Importing is done via `importFile`, which routes by file extension to a
/// registered `DeckImporter`, then persists the result. A future
/// `RemoteDeckSource` / `ParentAssignedDeckSource` can conform to `DeckSource`
/// without changing callers.
public final class LocalDeckSource: DeckSource {
    public static let sourceID = DeckSourceID(rawValue: "local")

    public let id = LocalDeckSource.sourceID
    private let store: CardStore
    private let importers: [DeckImporter]

    public init(
        store: CardStore,
        importers: [DeckImporter] = [CSVDeckImporter(), ApkgDeckImporter()]
    ) {
        self.store = store
        self.importers = importers
    }

    public func loadDecks() async throws -> [Deck] {
        try store.allDecks()
    }

    /// Import a file's bytes, choosing an importer by `fileName`'s extension,
    /// persist the resulting decks, and return them.
    @discardableResult
    public func importFile(named fileName: String, data: Data) throws -> [Deck] {
        let ext = (fileName as NSString).pathExtension.lowercased()
        guard let importer = importers.first(where: { $0.supportedExtensions.contains(ext) }) else {
            throw LearningGateError.importFailed("No importer for “.\(ext)” files")
        }
        let baseName = (fileName as NSString).deletingPathExtension
        let defaultName = baseName.isEmpty ? "Imported Deck" : baseName
        let decks = try importer.importDecks(from: data, defaultName: defaultName, sourceID: id)
        for deck in decks { try store.saveDeck(deck) }
        return decks
    }
}
