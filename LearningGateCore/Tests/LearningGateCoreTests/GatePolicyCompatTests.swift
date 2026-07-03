import XCTest
@testable import LearningGateCore

final class GatePolicyCompatTests: XCTestCase {
    /// Policies stored before `timePerLesson` existed must still decode,
    /// defaulting to 1 minute per lesson.
    func testDecodingLegacyPolicyDefaultsTimePerLesson() throws {
        let legacyJSON = Data("""
        {"cardsToUnlock": 7, "breakDuration": 300, "passThreshold": 0.8}
        """.utf8)
        let policy = try JSONDecoder().decode(GatePolicy.self, from: legacyJSON)
        XCTAssertEqual(policy.cardsToUnlock, 7)
        XCTAssertEqual(policy.breakDuration, 300)
        XCTAssertEqual(policy.passThreshold, 0.8, accuracy: 0.001)
        XCTAssertEqual(policy.timePerLesson, 60)
    }

    func testPolicyRoundTripsWithTimePerLesson() throws {
        let policy = GatePolicy(
            cardsToUnlock: 3, breakDuration: 600, passThreshold: 1.0, timePerLesson: 120
        )
        let data = try JSONEncoder().encode(policy)
        let decoded = try JSONDecoder().decode(GatePolicy.self, from: data)
        XCTAssertEqual(decoded, policy)
    }
}
