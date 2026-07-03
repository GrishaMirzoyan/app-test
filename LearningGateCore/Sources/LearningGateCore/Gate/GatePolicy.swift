import Foundation

/// The rules of the learning gate: how much work earns how much break.
///
/// `cardsToUnlock` is N and `breakDuration` is X from the spec (defaults 5 and
/// 10 minutes). `passThreshold` is the fraction of reviewed cards that must be
/// graded as a pass (≥ `.good`-ish, i.e. not `.again`) for the session to count
/// as cleared; 1.0 means every card must be recalled.
///
/// `timePerLesson` is the lesson economy: seconds of app time credited to the
/// `TimeBank` per completed course lesson (default 1 minute — "each lesson is
/// a minute of time"). Decoding tolerates stored policies written before this
/// field existed.
public struct GatePolicy: Codable, Equatable, Sendable {
    public var cardsToUnlock: Int
    public var breakDuration: TimeInterval
    public var passThreshold: Double
    public var timePerLesson: TimeInterval

    public init(
        cardsToUnlock: Int,
        breakDuration: TimeInterval,
        passThreshold: Double,
        timePerLesson: TimeInterval = 60
    ) {
        self.cardsToUnlock = cardsToUnlock
        self.breakDuration = breakDuration
        self.passThreshold = passThreshold
        self.timePerLesson = timePerLesson
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cardsToUnlock = try container.decode(Int.self, forKey: .cardsToUnlock)
        self.breakDuration = try container.decode(TimeInterval.self, forKey: .breakDuration)
        self.passThreshold = try container.decode(Double.self, forKey: .passThreshold)
        self.timePerLesson = try container.decodeIfPresent(TimeInterval.self, forKey: .timePerLesson) ?? 60
    }

    public static let `default` = GatePolicy(
        cardsToUnlock: 5,
        breakDuration: 10 * 60,
        passThreshold: 1.0,
        timePerLesson: 60
    )
}
