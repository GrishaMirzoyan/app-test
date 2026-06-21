import Foundation

/// The rules of the learning gate: how much work earns how much break.
///
/// `cardsToUnlock` is N and `breakDuration` is X from the spec (defaults 5 and
/// 10 minutes). `passThreshold` is the fraction of reviewed cards that must be
/// graded as a pass (≥ `.good`-ish, i.e. not `.again`) for the session to count
/// as cleared; 1.0 means every card must be recalled.
public struct GatePolicy: Codable, Equatable, Sendable {
    public var cardsToUnlock: Int
    public var breakDuration: TimeInterval
    public var passThreshold: Double

    public init(cardsToUnlock: Int, breakDuration: TimeInterval, passThreshold: Double) {
        self.cardsToUnlock = cardsToUnlock
        self.breakDuration = breakDuration
        self.passThreshold = passThreshold
    }

    public static let `default` = GatePolicy(
        cardsToUnlock: 5,
        breakDuration: 10 * 60,
        passThreshold: 1.0
    )
}
