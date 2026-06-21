import XCTest
@testable import LearningGateCore

final class StatsAndGateTests: XCTestCase {
    private let deck = DeckID(rawValue: "d")
    private let card = CardID(rawValue: "c")

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private func day(_ offset: Int, from base: Date) -> Date {
        calendar.date(byAdding: .day, value: offset, to: base)!
    }

    func testStreakCountsConsecutiveDaysIncludingToday() {
        let store = InMemoryReviewStore(calendar: calendar)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        for offset in [0, -1, -2] {
            store.record(ReviewLog(cardID: card, deckID: deck, grade: .good,
                                   reviewedAt: day(offset, from: now), resultingIntervalDays: 1))
        }
        XCTAssertEqual(store.current(now: now).currentStreakDays, 3)
        XCTAssertEqual(store.current(now: now).cardsReviewed, 3)
    }

    func testStreakSurvivesTodayNotYetReviewed() {
        let store = InMemoryReviewStore(calendar: calendar)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        for offset in [-1, -2] { // reviewed yesterday and the day before, not today
            store.record(ReviewLog(cardID: card, deckID: deck, grade: .good,
                                   reviewedAt: day(offset, from: now), resultingIntervalDays: 1))
        }
        XCTAssertEqual(store.current(now: now).currentStreakDays, 2)
    }

    func testStreakBreaksAfterGap() {
        let store = InMemoryReviewStore(calendar: calendar)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        for offset in [0, -2, -3] { // missing -1 breaks the streak after today
            store.record(ReviewLog(cardID: card, deckID: deck, grade: .good,
                                   reviewedAt: day(offset, from: now), resultingIntervalDays: 1))
        }
        XCTAssertEqual(store.current(now: now).currentStreakDays, 1)
    }

    func testBreaksEarnedCounted() {
        let store = InMemoryReviewStore(calendar: calendar)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        store.recordBreakEarned(BreakEarnedLog(earnedAt: now, cardsReviewed: 5, breakDuration: 600))
        XCTAssertEqual(store.current(now: now).breaksEarned, 1)
    }

    // MARK: - Gate

    func testIndividualGateAllowsEditsAndPersists() throws {
        let policyStore = InMemoryPolicyStore()
        let controller = IndividualGateController(store: policyStore)
        XCTAssertTrue(controller.canCurrentUserEditPolicy)
        XCTAssertEqual(controller.policy, .default)

        let custom = GatePolicy(cardsToUnlock: 3, breakDuration: 120, passThreshold: 0.8)
        try controller.updatePolicy(custom)
        XCTAssertEqual(controller.policy, custom)

        // A fresh controller reads the persisted policy back.
        let reopened = IndividualGateController(store: policyStore)
        XCTAssertEqual(reopened.policy, custom)
    }
}
