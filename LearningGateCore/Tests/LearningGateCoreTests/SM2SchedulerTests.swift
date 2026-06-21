import XCTest
@testable import LearningGateCore

final class SM2SchedulerTests: XCTestCase {
    private let scheduler = SM2Scheduler()
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testFirstGoodGivesOneDayInterval() {
        let next = scheduler.nextState(for: .new(), grade: .good, now: now)
        XCTAssertEqual(next.intervalDays, 1)
        XCTAssertEqual(next.repetitions, 1)
        XCTAssertEqual(next.easeFactor, 2.5, accuracy: 1e-9) // good is EF-neutral
        XCTAssertGreaterThan(next.dueDate, now)
    }

    func testSecondGoodGivesSixDays() {
        var state = scheduler.nextState(for: .new(), grade: .good, now: now)
        state = scheduler.nextState(for: state, grade: .good, now: now)
        XCTAssertEqual(state.intervalDays, 6)
        XCTAssertEqual(state.repetitions, 2)
    }

    func testThirdGoodMultipliesByEase() {
        var state = scheduler.nextState(for: .new(), grade: .good, now: now) // 1
        state = scheduler.nextState(for: state, grade: .good, now: now)      // 6
        state = scheduler.nextState(for: state, grade: .good, now: now)      // round(6 * 2.5) = 15
        XCTAssertEqual(state.intervalDays, 15)
        XCTAssertEqual(state.repetitions, 3)
    }

    func testEaseFactorAdjustsPerGrade() {
        XCTAssertEqual(scheduler.nextState(for: .new(), grade: .easy, now: now).easeFactor, 2.6, accuracy: 1e-9)
        XCTAssertEqual(scheduler.nextState(for: .new(), grade: .good, now: now).easeFactor, 2.5, accuracy: 1e-9)
        XCTAssertEqual(scheduler.nextState(for: .new(), grade: .hard, now: now).easeFactor, 2.36, accuracy: 1e-9)
        XCTAssertEqual(scheduler.nextState(for: .new(), grade: .again, now: now).easeFactor, 2.18, accuracy: 1e-9)
    }

    func testAgainLapsesAndBecomesDueImmediately() {
        var state = scheduler.nextState(for: .new(), grade: .good, now: now) // graduate a bit
        state = scheduler.nextState(for: state, grade: .good, now: now)
        let lapsed = scheduler.nextState(for: state, grade: .again, now: now)
        XCTAssertEqual(lapsed.repetitions, 0)
        XCTAssertEqual(lapsed.intervalDays, 0)
        XCTAssertEqual(lapsed.lapses, 1)
        XCTAssertEqual(lapsed.dueDate, now)
    }

    func testEaseFactorNeverDropsBelowFloor() {
        var state = SchedulingState.new()
        for _ in 0..<20 { state = scheduler.nextState(for: state, grade: .again, now: now) }
        XCTAssertEqual(state.easeFactor, SM2Scheduler.minimumEaseFactor, accuracy: 1e-9)
    }

    func testIsDue() {
        XCTAssertTrue(scheduler.isDue(.new(due: now.addingTimeInterval(-1)), now: now))
        XCTAssertFalse(scheduler.isDue(.new(due: now.addingTimeInterval(1000)), now: now))
    }
}
