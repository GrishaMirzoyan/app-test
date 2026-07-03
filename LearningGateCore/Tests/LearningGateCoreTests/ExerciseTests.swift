import XCTest
@testable import LearningGateCore

final class ExerciseTests: XCTestCase {
    // MARK: - Normalizer

    func testNormalizeStripsCasePunctuationAndExtraSpaces() {
        XCTAssertEqual(AnswerNormalizer.normalize("  Good   MORNING! "), "good morning")
        XCTAssertEqual(AnswerNormalizer.normalize("I'm fine."), "im fine")
        XCTAssertEqual(AnswerNormalizer.normalize("don\u{2019}t stop"), "dont stop")
        XCTAssertEqual(AnswerNormalizer.normalize("what is your name?"), "what is your name")
        XCTAssertEqual(AnswerNormalizer.normalize("..."), "")
    }

    // MARK: - Choice

    func testChoiceChecking() {
        let exercise = Exercise(
            id: ExerciseID("e"),
            kind: .choice(prompt: "🍎", choices: ["apple", "bread"], answerIndex: 0)
        )
        XCTAssertTrue(exercise.check(.choice(0)))
        XCTAssertFalse(exercise.check(.choice(1)))
        XCTAssertFalse(exercise.check(.choice(99))) // out of range is just wrong
        XCTAssertFalse(exercise.check(.text("apple"))) // mismatched shape
        XCTAssertEqual(exercise.correctAnswerText, "apple")
    }

    // MARK: - Word order

    func testWordOrderChecking() {
        let exercise = Exercise(
            id: ExerciseID("e"),
            kind: .wordOrder(prompt: "🌅", words: ["Good", "morning", "night"], answer: "Good morning")
        )
        XCTAssertTrue(exercise.check(.words(["Good", "morning"])))
        XCTAssertTrue(exercise.check(.words(["good", "MORNING"]))) // case-tolerant
        XCTAssertFalse(exercise.check(.words(["Good", "night"])))
        XCTAssertFalse(exercise.check(.words([])))
        XCTAssertEqual(exercise.correctAnswerText, "Good morning")
    }

    // MARK: - Type answer

    func testTypeAnswerCheckingIsTolerant() {
        let exercise = Exercise(
            id: ExerciseID("e"),
            kind: .typeAnswer(prompt: "👋", answer: "hello", accepted: ["hi"])
        )
        XCTAssertTrue(exercise.check(.text("hello")))
        XCTAssertTrue(exercise.check(.text("  Hello!  ")))
        XCTAssertTrue(exercise.check(.text("hi")))
        XCTAssertFalse(exercise.check(.text("goodbye")))
        XCTAssertFalse(exercise.check(.text("")))
        XCTAssertFalse(exercise.check(.text("!!!"))) // normalises to empty ≠ pass
    }

    func testExerciseRoundTripsThroughCodable() throws {
        let exercises = [
            Exercise(id: ExerciseID("a"), kind: .choice(prompt: "p", choices: ["x", "y"], answerIndex: 1)),
            Exercise(id: ExerciseID("b"), kind: .wordOrder(prompt: "p", words: ["a", "b"], answer: "a b")),
            Exercise(id: ExerciseID("c"), kind: .typeAnswer(prompt: "p", answer: "z", accepted: ["w"]))
        ]
        let data = try JSONEncoder().encode(exercises)
        let decoded = try JSONDecoder().decode([Exercise].self, from: data)
        XCTAssertEqual(decoded, exercises)
    }
}
