import XCTest
@testable import LearningGateCore

/// Integrity checks for the built-in course so content mistakes fail CI
/// instead of shipping (bad answer indexes, duplicate IDs, unsolvable
/// word-order banks, …).
final class EnglishCourseContentTests: XCTestCase {
    private let course = Course.beginnerEnglish

    func testCourseShapeIsNonTrivial() {
        XCTAssertGreaterThanOrEqual(course.units.count, 3)
        for unit in course.units {
            XCTAssertFalse(unit.lessons.isEmpty, "unit \(unit.id) has no lessons")
            for lesson in unit.lessons {
                XCTAssertGreaterThanOrEqual(
                    lesson.exercises.count, 5,
                    "lesson \(lesson.id) is too short to be worth a minute"
                )
            }
        }
    }

    func testAllIDsAreUnique() {
        let lessonIDs = course.orderedLessons.map(\.id.rawValue)
        XCTAssertEqual(lessonIDs.count, Set(lessonIDs).count, "duplicate lesson IDs")

        let exerciseIDs = course.orderedLessons.flatMap(\.exercises).map(\.id.rawValue)
        XCTAssertEqual(exerciseIDs.count, Set(exerciseIDs).count, "duplicate exercise IDs")

        let unitIDs = course.units.map(\.id.rawValue)
        XCTAssertEqual(unitIDs.count, Set(unitIDs).count, "duplicate unit IDs")
    }

    func testEveryExerciseIsSolvable() {
        for lesson in course.orderedLessons {
            for exercise in lesson.exercises {
                switch exercise.kind {
                case let .choice(prompt, choices, answerIndex):
                    XCTAssertFalse(prompt.isEmpty, "\(exercise.id): empty prompt")
                    XCTAssertGreaterThanOrEqual(choices.count, 2, "\(exercise.id): too few choices")
                    XCTAssertTrue(choices.indices.contains(answerIndex),
                                  "\(exercise.id): answer index out of range")
                    XCTAssertEqual(choices.count, Set(choices).count,
                                   "\(exercise.id): duplicate choices")
                    XCTAssertTrue(exercise.check(.choice(answerIndex)))

                case let .wordOrder(prompt, words, answer):
                    XCTAssertFalse(prompt.isEmpty, "\(exercise.id): empty prompt")
                    let answerWords = answer.split(separator: " ").map(String.init)
                    XCTAssertGreaterThanOrEqual(answerWords.count, 2,
                                                "\(exercise.id): word-order needs ≥ 2 words")
                    // The bank must contain enough copies of every answer word.
                    var bank = words
                    for word in answerWords {
                        if let index = bank.firstIndex(of: word) {
                            bank.remove(at: index)
                        } else {
                            XCTFail("\(exercise.id): answer word \"\(word)\" missing from bank")
                        }
                    }
                    XCTAssertTrue(exercise.check(.words(answerWords)),
                                  "\(exercise.id): correct order doesn't pass its own check")

                case let .typeAnswer(prompt, answer, accepted):
                    XCTAssertFalse(prompt.isEmpty, "\(exercise.id): empty prompt")
                    XCTAssertFalse(AnswerNormalizer.normalize(answer).isEmpty,
                                   "\(exercise.id): answer normalises to nothing")
                    XCTAssertTrue(exercise.check(.text(answer)))
                    for alternative in accepted {
                        XCTAssertTrue(exercise.check(.text(alternative)),
                                      "\(exercise.id): accepted alternative \"\(alternative)\" fails")
                    }
                }
            }
        }
    }

    func testCourseRoundTripsThroughCodable() throws {
        let data = try JSONEncoder().encode(course)
        let decoded = try JSONDecoder().decode(Course.self, from: data)
        XCTAssertEqual(decoded, course)
    }
}
