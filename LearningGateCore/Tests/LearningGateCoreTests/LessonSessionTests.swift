import XCTest
@testable import LearningGateCore

final class LessonSessionTests: XCTestCase {
    private func makeLesson(_ count: Int) -> Lesson {
        let exercises = (0..<count).map { i in
            Exercise(
                id: ExerciseID("e\(i)"),
                kind: .choice(prompt: "\(i)", choices: ["right", "wrong"], answerIndex: 0)
            )
        }
        return Lesson(id: LessonID("l"), title: "Test", icon: "🧪", exercises: exercises)
    }

    func testAllCorrectCompletesAndEarnsTime() {
        let session = LessonSession(lesson: makeLesson(3), earnedOnCompletion: 60)
        XCTAssertEqual(session.outcome(), .inProgress(remaining: 3))

        for i in 0..<3 {
            XCTAssertEqual(session.currentExercise?.id, ExerciseID("e\(i)"))
            XCTAssertEqual(session.submit(.choice(0)), .correct)
        }
        XCTAssertTrue(session.isComplete)
        XCTAssertNil(session.currentExercise)
        XCTAssertEqual(session.outcome(), .completed(earned: 60))
        XCTAssertEqual(session.mistakeCount, 0)
        XCTAssertEqual(session.progress, 1.0, accuracy: 0.001)
    }

    func testWrongAnswerRequeuesToEndOfSession() {
        let session = LessonSession(lesson: makeLesson(2), earnedOnCompletion: 60)

        XCTAssertEqual(session.submit(.choice(1)), .incorrect(correctAnswer: "right"))
        // e0 was re-queued behind e1.
        XCTAssertEqual(session.currentExercise?.id, ExerciseID("e1"))
        XCTAssertEqual(session.submit(.choice(0)), .correct)
        XCTAssertEqual(session.currentExercise?.id, ExerciseID("e0"))
        XCTAssertEqual(session.submit(.choice(0)), .correct)

        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.mistakeCount, 1)
        XCTAssertEqual(session.attemptCount, 3)
    }

    func testSubmitAfterCompletionIsNoOp() {
        let session = LessonSession(lesson: makeLesson(1), earnedOnCompletion: 60)
        XCTAssertEqual(session.submit(.choice(0)), .correct)
        XCTAssertNil(session.submit(.choice(0)))
        XCTAssertEqual(session.attemptCount, 1)
    }

    func testEmptyLessonIsImmediatelyComplete() {
        let session = LessonSession(lesson: makeLesson(0), earnedOnCompletion: 60)
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.outcome(), .completed(earned: 60))
        XCTAssertEqual(session.progress, 1.0, accuracy: 0.001)
    }

    func testProgressCountsDistinctPasses() {
        let session = LessonSession(lesson: makeLesson(4), earnedOnCompletion: 60)
        _ = session.submit(.choice(0))
        _ = session.submit(.choice(1)) // mistake shouldn't move the bar
        XCTAssertEqual(session.passedCount, 1)
        XCTAssertEqual(session.progress, 0.25, accuracy: 0.001)
    }
}
