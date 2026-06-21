import Foundation

/// Strongly-typed identifiers so a `DeckID` can never be passed where a
/// `CardID` is expected. All are backed by a plain `String` (a UUID string by
/// default, or a stable import key when we want dedup across re-imports).
public struct CardID: Hashable, Codable, RawRepresentable, Sendable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public static func generate() -> CardID { CardID(UUID().uuidString) }
    public var description: String { rawValue }
}

public struct DeckID: Hashable, Codable, RawRepresentable, Sendable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public static func generate() -> DeckID { DeckID(UUID().uuidString) }
    public var description: String { rawValue }
}

/// Identifies a *kind* of deck source (e.g. local file import, or a future
/// remote / parent-assigned source). Used so the app can list and route
/// between sources without knowing concrete types.
public struct DeckSourceID: Hashable, Codable, RawRepresentable, Sendable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public var description: String { rawValue }
}
