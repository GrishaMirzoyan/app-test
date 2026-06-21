import Foundation

/// A named collection of cards.
///
/// `kind` lets future deck types (e.g. test-prep) carry behavioural hints
/// without subclassing. `sourceID` records where the deck came from so the app
/// can group decks by origin (local import now; remote/parent later).
public struct Deck: Identifiable, Codable, Equatable, Sendable {
    public let id: DeckID
    public var name: String
    public var kind: DeckKind
    public var sourceID: DeckSourceID
    public var cards: [Card]

    public init(
        id: DeckID = .generate(),
        name: String,
        kind: DeckKind = .vocabulary,
        sourceID: DeckSourceID,
        cards: [Card] = []
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.sourceID = sourceID
        self.cards = cards
    }
}

/// Open-ended deck classification. Backed by a string so adding a new kind
/// (e.g. `.testPrep`) is a non-breaking change and unknown values decode
/// gracefully rather than throwing.
public struct DeckKind: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }

    public static let vocabulary = DeckKind("vocabulary")
    public static let language   = DeckKind("language")
    public static let general    = DeckKind("general")
    /// Reserved for the future test-prep deck type.
    public static let testPrep   = DeckKind("testPrep")
}
