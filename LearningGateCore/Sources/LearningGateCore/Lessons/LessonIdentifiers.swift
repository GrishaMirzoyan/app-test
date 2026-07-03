import Foundation

/// Strongly-typed identifiers for the lesson/course domain, mirroring the
/// card/deck identifiers. Built-in course content uses stable string IDs
/// (e.g. "en.u1.l2.e3") so progress survives content updates and reinstalls.
public struct ExerciseID: Hashable, Codable, RawRepresentable, Sendable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public var description: String { rawValue }
}

public struct LessonID: Hashable, Codable, RawRepresentable, Sendable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public var description: String { rawValue }
}

public struct CourseUnitID: Hashable, Codable, RawRepresentable, Sendable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public var description: String { rawValue }
}

public struct CourseID: Hashable, Codable, RawRepresentable, Sendable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public var description: String { rawValue }
}
