import XCTest
@testable import LearningGateCore

final class CourseProgressTests: XCTestCase {
    /// Two units, two lessons each — a minimal path.
    private let course = Course(
        id: CourseID("c"),
        title: "Test Course",
        units: [
            CourseUnit(id: CourseUnitID("u1"), title: "One", lessons: [
                Lesson(id: LessonID("l1"), title: "A", icon: "🅰️", exercises: []),
                Lesson(id: LessonID("l2"), title: "B", icon: "🅱️", exercises: [])
            ]),
            CourseUnit(id: CourseUnitID("u2"), title: "Two", lessons: [
                Lesson(id: LessonID("l3"), title: "C", icon: "©️", exercises: [])
            ])
        ]
    )

    func testOnlyFirstLessonUnlockedInitially() {
        let progress = LessonProgress()
        XCTAssertTrue(course.isUnlocked(LessonID("l1"), progress: progress))
        XCTAssertFalse(course.isUnlocked(LessonID("l2"), progress: progress))
        XCTAssertFalse(course.isUnlocked(LessonID("l3"), progress: progress))
        XCTAssertEqual(course.nextLesson(progress: progress)?.id, LessonID("l1"))
    }

    func testCompletionUnlocksTheNextLessonAcrossUnits() {
        var progress = LessonProgress()
        progress.recordCompletion(of: LessonID("l1"))
        XCTAssertTrue(course.isUnlocked(LessonID("l2"), progress: progress))
        XCTAssertFalse(course.isUnlocked(LessonID("l3"), progress: progress))

        progress.recordCompletion(of: LessonID("l2"))
        XCTAssertTrue(course.isUnlocked(LessonID("l3"), progress: progress)) // crosses the unit boundary
        XCTAssertEqual(course.nextLesson(progress: progress)?.id, LessonID("l3"))
    }

    func testUnknownLessonIsNeverUnlocked() {
        XCTAssertFalse(course.isUnlocked(LessonID("nope"), progress: LessonProgress()))
    }

    func testPracticeLessonPrefersNewThenLeastPractised() {
        var progress = LessonProgress()
        // New content first.
        XCTAssertEqual(course.practiceLesson(progress: progress)?.id, LessonID("l1"))

        // Course finished: serve the least-practised lesson.
        progress.recordCompletion(of: LessonID("l1"))
        progress.recordCompletion(of: LessonID("l1"))
        progress.recordCompletion(of: LessonID("l2"))
        progress.recordCompletion(of: LessonID("l3"))
        let practice = course.practiceLesson(progress: progress)
        // l2 and l3 both have 1 completion; tie breaks deterministically to l2.
        XCTAssertEqual(practice?.id, LessonID("l2"))
    }

    func testProgressCounts() {
        var progress = LessonProgress()
        progress.recordCompletion(of: LessonID("l1"))
        progress.recordCompletion(of: LessonID("l1"))
        progress.recordCompletion(of: LessonID("l2"))
        XCTAssertEqual(progress.lessonsCompleted, 2)
        XCTAssertEqual(progress.totalCompletions, 3)
        XCTAssertEqual(progress.completions(of: LessonID("l1")), 2)
        XCTAssertEqual(progress.completions(of: LessonID("l9")), 0)
    }

    func testFileStorePersistsProgress() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("lesson-progress-tests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = try FileLessonProgressStore(containerURL: dir)
        var progress = store.load()
        XCTAssertEqual(progress.totalCompletions, 0)
        progress.recordCompletion(of: LessonID("l1"))
        store.save(progress)

        let reopened = try FileLessonProgressStore(containerURL: dir)
        XCTAssertEqual(reopened.load().completions(of: LessonID("l1")), 1)
    }
}
