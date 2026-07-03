import Foundation

/// Feedback for one submitted answer.
public enum LessonSubmission: Equatable, Sendable {
    case correct
    /// Wrong — the exercise is re-queued to the end of the session so the
    /// learner retries it before finishing (same reward framing as
    /// `UnlockSession`: you keep going until you've earned it).
    case incorrect(correctAnswer: String)
}

/// Where the session stands after a submission.
public enum LessonOutcome: Equatable, Sendable {
    case inProgress(remaining: Int)
    /// All exercises answered correctly; `earned` seconds go to the TimeBank.
    case completed(earned: TimeInterval)
}

/// Drives one lesson: presents exercises in order, re-queues mistakes, and
/// completes when every exercise has been answered correctly once.
///
/// Pure logic — no persistence, no Screen Time. The caller (view model)
/// credits the `TimeBank` and `LessonProgressStore` on `.completed`.
public final class LessonSession {
    public let lesson: Lesson
    /// Seconds of app time this lesson is worth (from `GatePolicy.timePerLesson`).
    public let earnedOnCompletion: TimeInterval

    private var queue: [Exercise]
    private var passedIDs: Set<ExerciseID> = []
    public private(set) var attemptCount = 0
    public private(set) var mistakeCount = 0

    public init(lesson: Lesson, earnedOnCompletion: TimeInterval) {
        self.lesson = lesson
        self.earnedOnCompletion = earnedOnCompletion
        self.queue = lesson.exercises
    }

    // MARK: - State for the UI

    /// The exercise to show now, or nil when the lesson is complete.
    public var currentExercise: Exercise? { queue.first }

    public var totalExercises: Int { lesson.exercises.count }
    public var passedCount: Int { passedIDs.count }

    /// Fraction of distinct exercises passed (drives the progress bar).
    public var progress: Double {
        totalExercises == 0 ? 1 : Double(passedCount) / Double(totalExercises)
    }

    public var isComplete: Bool { queue.isEmpty }

    // MARK: - Actions

    /// Check the answer for the current exercise. Returns nil if the session
    /// is already complete.
    @discardableResult
    public func submit(_ answer: ExerciseAnswer) -> LessonSubmission? {
        guard let exercise = queue.first else { return nil }
        attemptCount += 1

        if exercise.check(answer) {
            queue.removeFirst()
            passedIDs.insert(exercise.id)
            return .correct
        } else {
            mistakeCount += 1
            queue.removeFirst()
            queue.append(exercise) // retry later this session
            return .incorrect(correctAnswer: exercise.correctAnswerText)
        }
    }

    /// Current outcome without mutating anything.
    public func outcome() -> LessonOutcome {
        isComplete
            ? .completed(earned: earnedOnCompletion)
            : .inProgress(remaining: totalExercises - passedCount)
    }
}
