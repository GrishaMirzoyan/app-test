import XCTest
@testable import LearningGateCore

final class LeitnerSchedulerTests: XCTestCase {
    private let scheduler = LeitnerScheduler() // boxes [0,1,2,4,8,16,32]
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testGoodPromotesOneBox() {
        let next = scheduler.nextState(for: .new(), grade: .good, now: now)
        XCTAssertEqual(next.leitnerBox, 1)
        XCTAssertEqual(next.intervalDays, 1)
        XCTAssertEqual(next.repetitions, 1)
    }

    func testEasyPromotesTwoBoxes() {
        let next = scheduler.nextState(for: .new(), grade: .easy, now: now)
        XCTAssertEqual(next.leitnerBox, 2)
        XCTAssertEqual(next.intervalDays, 2)
    }

    func testHardHoldsPosition() {
        var state = scheduler.nextState(for: .new(), grade: .good, now: now) // box 1
        state = scheduler.nextState(for: state, grade: .hard, now: now)      // stays box 1
        XCTAssertEqual(state.leitnerBox, 1)
        XCTAssertEqual(state.intervalDays, 1)
    }

    func testAgainResetsToBoxZeroAndLapses() {
        var state = scheduler.nextState(for: .new(), grade: .easy, now: now) // box 2
        state = scheduler.nextState(for: state, grade: .again, now: now)
        XCTAssertEqual(state.leitnerBox, 0)
        XCTAssertEqual(state.intervalDays, 0)
        XCTAssertEqual(state.lapses, 1)
        XCTAssertEqual(state.dueDate, now)
    }

    func testPromotionCapsAtLastBox() {
        var state = SchedulingState.new()
        for _ in 0..<10 { state = scheduler.nextState(for: state, grade: .good, now: now) }
        XCTAssertEqual(state.leitnerBox, 6)        // last index
        XCTAssertEqual(state.intervalDays, 32)
    }
}
