import Foundation
import ZIPFoundation

/// Imports Anki `.apkg` packages: a zip containing a SQLite collection.
///
/// We extract `collection.anki21` (preferred) or `collection.anki2`, then read:
///   - `col.decks`  — JSON map of deck id → deck metadata (names)
///   - `cards.nid/did` — which deck each note's card belongs to
///   - `notes.flds/tags` — fields (0x1F-separated) and tags
///
/// Notes are grouped into one `Deck` per Anki deck name. Field HTML is lightly
/// stripped to plain text. The newest zstd-compressed `collection.anki21b`
/// format is not supported (see the thrown message).
///
/// NOTE: ZIPFoundation's `Archive(url:accessMode:)` is the 0.9.x failable
/// initializer; the package pins `<1.0` so this API holds. Recorded in VERIFY.md.
public struct ApkgDeckImporter: DeckImporter {
    /// Anki's field separator: ASCII Unit Separator (0x1F).
    private static let fieldSeparator = "\u{1f}"

    public let supportedExtensions = ["apkg"]

    public init() {}

    public func importDecks(from data: Data, defaultName: String, sourceID: DeckSourceID) throws -> [Deck] {
        let fileManager = FileManager.default
        let workDir = fileManager.temporaryDirectory
            .appendingPathComponent("apkg-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: workDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: workDir) }

        let apkgURL = workDir.appendingPathComponent("import.apkg")
        try data.write(to: apkgURL)

        guard let archive = Archive(url: apkgURL, accessMode: .read) else {
            throw LearningGateError.importFailed("Could not open .apkg (not a valid zip?)")
        }

        let dbURL = try extractCollection(from: archive, into: workDir)
        let database = try SQLiteDatabase(path: dbURL.path)

        let deckNames = readDeckNames(from: database)        // did(String) -> name
        let noteToDeck = readNoteDeckMap(from: database)     // nid(String) -> did(String)
        let noteRows = try database.query("SELECT id, flds, tags FROM notes")

        // Accumulate cards per resolved deck name, preserving a stable DeckID.
        var deckIDsByName: [String: DeckID] = [:]
        var cardsByDeckName: [String: [Card]] = [:]

        for row in noteRows {
            guard row.count >= 2, let noteID = row[0], let flds = row[1] else { continue }
            let fields = flds.components(separatedBy: Self.fieldSeparator)
            guard fields.count >= 2 else { continue } // need a front and a back
            let front = Self.plainText(fields[0])
            let back = Self.plainText(fields[1])
            guard !front.isEmpty, !back.isEmpty else { continue }

            let tags: [String] = (row.count >= 3 ? row[2] : nil)?
                .split(separator: " ").map(String.init) ?? []

            let deckName = noteToDeck[noteID].flatMap { deckNames[$0] } ?? defaultName
            let deckID = deckIDsByName[deckName] ?? {
                let id = DeckID.generate(); deckIDsByName[deckName] = id; return id
            }()

            cardsByDeckName[deckName, default: []].append(
                Card(deckID: deckID, front: front, back: back, tags: tags)
            )
        }

        let decks: [Deck] = cardsByDeckName.compactMap { name, cards in
            guard let id = deckIDsByName[name], !cards.isEmpty else { return nil }
            return Deck(id: id, name: name, kind: .vocabulary, sourceID: sourceID, cards: cards)
        }

        guard !decks.isEmpty else {
            throw LearningGateError.importFailed("No usable front/back notes found in .apkg")
        }
        return decks
    }

    // MARK: - Extraction

    private func extractCollection(from archive: Archive, into workDir: URL) throws -> URL {
        for name in ["collection.anki21", "collection.anki2"] {
            if let entry = archive[name] {
                let out = workDir.appendingPathComponent(name)
                _ = try archive.extract(entry, to: out)
                return out
            }
        }
        if archive["collection.anki21b"] != nil {
            throw LearningGateError.importFailed(
                "This .apkg uses the newer zstd-compressed format (collection.anki21b). "
                + "Re-export from Anki with “Support older Anki versions” enabled.")
        }
        throw LearningGateError.importFailed("No collection.anki2/anki21 found in .apkg")
    }

    // MARK: - Anki schema reads

    private func readDeckNames(from db: SQLiteDatabase) -> [String: String] {
        guard let rows = try? db.query("SELECT decks FROM col LIMIT 1"),
              let json = rows.first?.first ?? nil,
              let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        var names: [String: String] = [:]
        for (did, value) in object {
            if let dict = value as? [String: Any], let name = dict["name"] as? String {
                names[did] = name
            }
        }
        return names
    }

    private func readNoteDeckMap(from db: SQLiteDatabase) -> [String: String] {
        guard let rows = try? db.query("SELECT nid, did FROM cards") else { return [:] }
        var map: [String: String] = [:]
        for row in rows where row.count >= 2 {
            if let nid = row[0], let did = row[1] { map[nid] = did }
        }
        return map
    }

    // MARK: - HTML

    /// Lightweight HTML-to-text: drop tags and decode a handful of common
    /// entities. Good enough for vocabulary fields; we deliberately avoid a full
    /// HTML parser to keep the core dependency-free.
    static func plainText(_ html: String) -> String {
        var result = ""
        var insideTag = false
        for character in html {
            switch character {
            case "<": insideTag = true
            case ">": insideTag = false
            default: if !insideTag { result.append(character) }
            }
        }
        let entities = ["&nbsp;": " ", "&amp;": "&", "&lt;": "<",
                        "&gt;": ">", "&quot;": "\"", "&#39;": "'"]
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
