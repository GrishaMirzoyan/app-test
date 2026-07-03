import Foundation

/// A short, self-contained learning session — the unit of currency of the
/// gate: one completed lesson earns `GatePolicy.timePerLesson` of app time.
public struct Lesson: Identifiable, Codable, Equatable, Sendable {
    public let id: LessonID
    public var title: String
    /// Emoji shown on the course path (language-neutral iconography).
    public var icon: String
    public var exercises: [Exercise]

    public init(id: LessonID, title: String, icon: String, exercises: [Exercise]) {
        self.id = id
        self.title = title
        self.icon = icon
        self.exercises = exercises
    }
}

/// A themed group of lessons on the course path.
public struct CourseUnit: Identifiable, Codable, Equatable, Sendable {
    public let id: CourseUnitID
    public var title: String
    public var lessons: [Lesson]

    public init(id: CourseUnitID, title: String, lessons: [Lesson]) {
        self.id = id
        self.title = title
        self.lessons = lessons
    }
}

/// An ordered course (units → lessons). v1 ships one built-in beginner
/// English course; the model is generic so more courses can be added.
public struct Course: Identifiable, Codable, Equatable, Sendable {
    public let id: CourseID
    public var title: String
    public var units: [CourseUnit]

    public init(id: CourseID, title: String, units: [CourseUnit]) {
        self.id = id
        self.title = title
        self.units = units
    }

    /// All lessons in path order.
    public var orderedLessons: [Lesson] { units.flatMap(\.lessons) }

    public func lesson(_ id: LessonID) -> Lesson? {
        orderedLessons.first { $0.id == id }
    }

    /// A lesson is unlocked once every earlier lesson on the path has been
    /// completed at least once. The first lesson is always unlocked.
    public func isUnlocked(_ id: LessonID, progress: LessonProgress) -> Bool {
        for lesson in orderedLessons {
            if lesson.id == id { return true }
            if progress.completions(of: lesson.id) == 0 { return false }
        }
        return false // unknown lesson id
    }

    /// The first never-completed lesson (the "continue" target), or nil when
    /// the whole course has been completed at least once.
    public func nextLesson(progress: LessonProgress) -> Lesson? {
        orderedLessons.first { progress.completions(of: $0.id) == 0 }
    }

    /// What to serve when the learner asks for "a lesson" (e.g. from the
    /// shield): the next new lesson, or — once the course is finished — the
    /// least-practised lesson so repeats stay useful.
    public func practiceLesson(progress: LessonProgress) -> Lesson? {
        if let next = nextLesson(progress: progress) { return next }
        return orderedLessons.min { lhs, rhs in
            let l = progress.completions(of: lhs.id)
            let r = progress.completions(of: rhs.id)
            return l == r
                ? lhs.id.rawValue < rhs.id.rawValue // deterministic tie-break
                : l < r
        }
    }
}
