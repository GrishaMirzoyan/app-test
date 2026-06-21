import XCTest
@testable import LearningGateCore

final class UnlockSessionTests: XCTestCase {
    private let deck = DeckID(rawValue: "d")
    private let scheduler = SM2Scheduler()
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeStore(_ cards: [Card]) -> InMemoryCardStore {
        InMemoryCardStore(cards: cards)
    }

    func testPassingAllCardsEarnsBreak() throws {
        let cards = (0..<5).map { Card.due("c\($0)", deck: deck, secondsAgo: Double($0 + 1), now: now) }
        let store = makeStore(cards)
        let session = UnlockSession(
            dueCards: cards, policy: .default, scheduler: scheduler, store: store, now: { self.now }
        )
        XCTAssertEqual(session.requiredPasses, 5)

        for i in 0..<5 {
            XCTAssertNotNil(session.currentCard)
            let result = try session.grade(.good)
            if i < 4 {
                XCTAssertEqual(result, .inProgress(remaining: 4 - i))
            } else {
                XCTAssertEqual(result, .passed(grantDuration: GatePolicy.default.breakDuration))
            }
        }
        XCTAssertNil(session.currentCard)
        XCTAssertTrue(session.isComplete)
    }

    func testAgainRequeuesCardUntilPassed() throws {
        let card = Card.due("x", deck: deck, now: now)
        let store = makeStore([card])
        let policy = GatePolicy(cardsToUnlock: 1, breakDuration: 600, passThreshold: 1.0)
        let session = UnlockSession(dueCards: [card], policy: policy, scheduler: scheduler, store: store, now: { self.now })

        let r1 = try session.grade(.again)
        XCTAssertEqual(r1, .inProgress(remaining: 1))
        XCTAssertEqual(session.currentCard?.id, card.id) // re-queued, shown again
        XCTAssertFalse(session.isComplete)

        let r2 = try session.grade(.good)
        XCTAssertEqual(r2, .passed(grantDuration: 600))
        XCTAssertEqual(session.attemptCount, 2)
    }

    func testPartialThresholdFinishesEarly() throws {
        let cards = (0..<4).map { Card.due("c\($0)", deck: deck, secondsAgo: Double($0 + 1), now: now) }
        let store = makeStore(cards)
        let policy = GatePolicy(cardsToUnlock: 4, breakDuration: 300, passThreshold: 0.5)
        let session = UnlockSession(dueCards: cards, policy: policy, scheduler: scheduler, store: store, now: { self.now })
        XCTAssertEqual(session.requiredPasses, 2) // ceil(4 * 0.5)

        XCTAssertEqual(try session.grade(.good), .inProgress(remaining: 1))
        XCTAssertEqual(try session.grade(.good), .passed(grantDuration: 300))
    }

    func testNoDueCardsGrantsBreakImmediately() {
        let store = makeStore([])
        let session = UnlockSession(dueCards: [], policy: .default, scheduler: scheduler, store: store, now: { self.now })
        XCTAssertTrue(session.isComplete)
        XCTAssertNil(session.currentCard)
        XCTAssertEqual(session.outcome(), .passed(grantDuration: GatePolicy.default.breakDuration))
    }

    func testTargetCappedByAvailableDueCards() throws {
        let cards = [Card.due("only", deck: deck, now: now)]
        let store = makeStore(cards)
        // Policy wants 5 but only 1 is due.
        let session = UnlockSession(dueCards: cards, policy: .default, scheduler: scheduler, store: store, now: { self.now })
        XCTAssertEqual(session.requiredPasses, 1)
        XCTAssertEqual(try session.grade(.good), .passed(grantDuration: GatePolicy.default.breakDuration))
    }

    func testGradingPersistsScheduleAndRecordsLogs() throws {
        let card = Card.due("p", deck: deck, now: now)
        let store = makeStore([card])
        let recorder = InMemoryReviewStore()
        let policy = GatePolicy(cardsToUnlock: 1, breakDuration: 600, passThreshold: 1.0)
        let session = UnlockSession(dueCards: [card], policy: policy, scheduler: scheduler,
                                    store: store, recorder: recorder, now: { self.now })

        _ = try session.grade(.good)

        // Card's schedule advanced and was persisted.
        let stored = try XCTUnwrap(store.card(card.id))
        XCTAssertEqual(stored.scheduling.repetitions, 1)
        XCTAssertGreaterThan(stored.scheduling.dueDate, now)

        // One review log + exactly one break-earned event.
        let stats = recorder.current(now: now)
        XCTAssertEqual(stats.cardsReviewed, 1)
        XCTAssertEqual(stats.breaksEarned, 1)
    }

    func testGradingAfterCompletionIsNoOp() throws {
        let card = Card.due("p", deck: deck, now: now)
        let store = makeStore([card])
        let policy = GatePolicy(cardsToUnlock: 1, breakDuration: 600, passThreshold: 1.0)
        let session = UnlockSession(dueCards: [card], policy: policy, scheduler: scheduler, store: store, now: { self.now })
        _ = try session.grade(.good)
        let after = try session.grade(.good) // no card left
        XCTAssertEqual(after, .passed(grantDuration: 600))
        XCTAssertEqual(session.attemptCount, 1) // second grade did nothing
    }
}
