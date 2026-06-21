import Foundation

/// Imports plain CSV into a single deck.
///
/// Expected columns: `front,back[,tags]`. Tags may be separated by spaces,
/// commas-within-the-cell aren't possible, so use spaces or semicolons inside
/// the tags cell. A leading `front,back` header row (case-insensitive) is
/// detected and skipped. Quoting follows RFC 4180: wrap a field in double
/// quotes to include commas or newlines, and double a quote (`""`) to escape it.
public struct CSVDeckImporter: DeckImporter {
    public let supportedExtensions = ["csv", "tsv", "txt"]
    private let delimiter: Character

    public init(delimiter: Character = ",") {
        self.delimiter = delimiter
    }

    public func importDecks(from data: Data, defaultName: String, sourceID: DeckSourceID) throws -> [Deck] {
        guard let text = String(data: data, encoding: .utf8) else {
            throw LearningGateError.importFailed("CSV is not valid UTF-8")
        }
        let rows = parseRows(text)
        guard !rows.isEmpty else {
            throw LearningGateError.importFailed("CSV contained no rows")
        }

        let deckID = DeckID.generate()
        var cards: [Card] = []
        for (index, row) in rows.enumerated() {
            guard row.count >= 2 else { continue } // need at least front + back
            // Skip an optional header row.
            if index == 0,
               row[0].lowercased() == "front", row[1].lowercased() == "back" {
                continue
            }
            let front = row[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let back = row[1].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !front.isEmpty, !back.isEmpty else { continue }
            let tags: [String] = row.count >= 3
                ? row[2].split(whereSeparator: { $0 == " " || $0 == ";" }).map(String.init)
                : []
            cards.append(Card(deckID: deckID, front: front, back: back, tags: tags))
        }

        guard !cards.isEmpty else {
            throw LearningGateError.importFailed("CSV contained no usable front/back rows")
        }
        let deck = Deck(id: deckID, name: defaultName, kind: .vocabulary,
                        sourceID: sourceID, cards: cards)
        return [deck]
    }

    /// Minimal RFC 4180 parser supporting quoted fields and escaped quotes.
    private func parseRows(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var field = ""
        var row: [String] = []
        var inQuotes = false
        var iterator = text.makeIterator()
        var pending: Character? = iterator.next()

        func advance() -> Character? { iterator.next() }

        while let ch = pending {
            if inQuotes {
                if ch == "\"" {
                    let next = advance()
                    if next == "\"" {
                        field.append("\"") // escaped quote
                        pending = advance()
                    } else {
                        inQuotes = false
                        pending = next
                    }
                } else {
                    field.append(ch)
                    pending = advance()
                }
            } else {
                switch ch {
                case "\"":
                    inQuotes = true
                    pending = advance()
                case delimiter:
                    row.append(field); field = ""
                    pending = advance()
                case "\r":
                    pending = advance() // swallow; handle on the \n
                case "\n":
                    row.append(field); field = ""
                    rows.append(row); row = []
                    pending = advance()
                default:
                    field.append(ch)
                    pending = advance()
                }
            }
        }
        // Flush trailing field/row if the file didn't end with a newline.
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        return rows
    }
}
