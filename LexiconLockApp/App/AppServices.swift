import Foundation
import LearningGateCore

/// Composition root: builds the LearningGateCore services against the shared App
/// Group container and exposes them to SwiftUI. Everything Screen Time-specific
/// is injected as the core's `BlockingController` so the views stay testable.
@MainActor
final class AppServices: ObservableObject {
    let cardStore: CardStore
    let reviewStore: ReviewRecorder & StatsService
    let gateController: GateController
    let selectionStore: SelectionStore
    let blockingController: BlockingController
    let localDeckSource: LocalDeckSource
    let course: Course
    let timeBank: TimeBank
    let lessonProgressStore: LessonProgressStore

    init() {
        let container = AppGroup.containerURL
        // Force-try is acceptable here: failure means the App Group capability
        // isn't configured, which is a build-time setup error (see README).
        let store = try! FileCardStore(containerURL: container)
        self.cardStore = store
        self.reviewStore = try! FileReviewStore(containerURL: container)
        self.gateController = IndividualGateController(store: UserDefaultsPolicyStore())
        self.selectionStore = SelectionStore()
        self.blockingController = ScreenTimeBlockingController(selectionStore: selectionStore)
        self.localDeckSource = LocalDeckSource(store: store)
        self.course = .beginnerEnglish
        self.timeBank = TimeBank(store: try! FileTimeBankStore(containerURL: container))
        self.lessonProgressStore = try! FileLessonProgressStore(containerURL: container)
    }

    /// Total cards due right now (drives the home screen call-to-action).
    func dueCount(now: Date = Date()) -> Int {
        (try? cardStore.dueCount(now: now)) ?? 0
    }

    /// Whole minutes of app time currently banked.
    func bankedMinutes() -> Int {
        Int(timeBank.balance / 60)
    }

    /// The lesson to serve when the learner asks for one (shield tap or the
    /// home CTA): next new lesson, else the least-practised for review.
    func lessonToServe() -> Lesson? {
        course.practiceLesson(progress: lessonProgressStore.load())
    }
}
