import Foundation
import LearningGateCore

/// Drives one lesson on top of the core's `LessonSession`. On completion it
/// credits the earned time to the `TimeBank` and records course progress;
/// "unlock my apps" redeems the whole bank into a Screen Time break.
@MainActor
final class LessonViewModel: ObservableObject {
    enum Phase: Equatable {
        case exercising
        case completed(earnedMinutes: Int, bankedMinutes: Int)
        /// Bank redeemed and shield lifted — show the send-off.
        case unlocked(minutes: Int)
    }

    enum Feedback: Equatable {
        case correct
        case incorrect(correctAnswer: String)
    }

    /// A word-bank chip. Identified by position so duplicate words (e.g. two
    /// "the") stay distinct chips.
    struct WordChip: Identifiable, Equatable {
        let id: Int
        let word: String
    }

    @Published private(set) var phase: Phase = .exercising
    @Published private(set) var feedback: Feedback?
    @Published private(set) var progress: Double = 0

    // Per-exercise input state.
    @Published var selectedChoiceIndex: Int?
    @Published var typedAnswer = ""
    @Published private(set) var arrangedChips: [WordChip] = []
    @Published private(set) var bankChips: [WordChip] = []

    let lessonTitle: String

    private let session: LessonSession
    private let timeBank: TimeBank
    private let progressStore: LessonProgressStore
    private let blockingController: BlockingController

    init(lesson: Lesson, services: AppServices) {
        self.lessonTitle = lesson.title
        self.session = LessonSession(
            lesson: lesson,
            earnedOnCompletion: services.gateController.policy.timePerLesson
        )
        self.timeBank = services.timeBank
        self.progressStore = services.lessonProgressStore
        self.blockingController = services.blockingController
        prepareCurrentExercise()
        if session.isComplete { finishLesson() } // defensive: empty lesson
    }

    var currentExercise: Exercise? { session.currentExercise }

    /// Whether the learner has produced something checkable.
    var canSubmit: Bool {
        guard feedback == nil, let exercise = currentExercise else { return false }
        switch exercise.kind {
        case .choice: return selectedChoiceIndex != nil
        case .wordOrder: return !arrangedChips.isEmpty
        case .typeAnswer:
            return !typedAnswer.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    // MARK: - Word bank

    func pickChip(_ chip: WordChip) {
        guard feedback == nil, let index = bankChips.firstIndex(of: chip) else { return }
        bankChips.remove(at: index)
        arrangedChips.append(chip)
    }

    func returnChip(_ chip: WordChip) {
        guard feedback == nil, let index = arrangedChips.firstIndex(of: chip) else { return }
        arrangedChips.remove(at: index)
        bankChips.append(chip)
    }

    // MARK: - Flow

    func submit() {
        guard canSubmit, let exercise = currentExercise else { return }
        let answer: ExerciseAnswer
        switch exercise.kind {
        case .choice:
            answer = .choice(selectedChoiceIndex ?? -1)
        case .wordOrder:
            answer = .words(arrangedChips.map(\.word))
        case .typeAnswer:
            answer = .text(typedAnswer)
        }

        switch session.submit(answer) {
        case .correct:
            feedback = .correct
        case .incorrect(let correctAnswer):
            feedback = .incorrect(correctAnswer: correctAnswer)
        case nil:
            break
        }
        progress = session.progress
    }

    func continueAfterFeedback() {
        feedback = nil
        if session.isComplete {
            finishLesson()
        } else {
            prepareCurrentExercise()
        }
    }

    /// Redeem the whole bank into a Screen Time break.
    func unlockApps() {
        let seconds = timeBank.redeemAll()
        guard seconds > 0 else { return }
        blockingController.grantBreak(for: seconds)
        phase = .unlocked(minutes: max(1, Int(seconds / 60)))
    }

    // MARK: - Helpers

    private func prepareCurrentExercise() {
        selectedChoiceIndex = nil
        typedAnswer = ""
        arrangedChips = []
        bankChips = []
        if case let .wordOrder(_, words, _)? = currentExercise?.kind {
            bankChips = words.enumerated()
                .map { WordChip(id: $0.offset, word: $0.element) }
                .shuffled()
        }
    }

    private func finishLesson() {
        guard case .exercising = phase else { return } // only credit once
        let earned = session.earnedOnCompletion
        let newBalance = timeBank.credit(earned)

        var courseProgress = progressStore.load()
        courseProgress.recordCompletion(of: session.lesson.id)
        progressStore.save(courseProgress)

        phase = .completed(
            earnedMinutes: max(1, Int(earned / 60)),
            bankedMinutes: Int(newBalance / 60)
        )
    }
}
