import Foundation
import LearningGateCore

/// Drives one "learn to unlock" round on top of the core's `UnlockSession`,
/// then grants a break via the injected `BlockingController` when passed.
@MainActor
final class ReviewViewModel: ObservableObject {
    enum Phase: Equatable {
        case reviewing
        case earned(minutes: Int)
        case nothingDue
    }

    @Published private(set) var phase: Phase = .reviewing
    @Published private(set) var showingBack = false
    @Published private(set) var front = ""
    @Published private(set) var back = ""
    @Published private(set) var passed = 0
    @Published private(set) var required = 0

    private let session: UnlockSession
    private let blockingController: BlockingController

    init(
        cardStore: CardStore,
        gateController: GateController,
        recorder: ReviewRecorder,
        blockingController: BlockingController,
        scheduler: SpacedRepetitionScheduler = SM2Scheduler(),
        now: @escaping () -> Date = Date.init
    ) {
        let policy = gateController.policy
        let due = (try? cardStore.dueCards(limit: policy.cardsToUnlock, now: now())) ?? []
        self.session = UnlockSession(
            dueCards: due, policy: policy, scheduler: scheduler,
            store: cardStore, recorder: recorder, now: now
        )
        self.blockingController = blockingController
        self.required = session.requiredPasses
        syncFromSession()
    }

    func reveal() { showingBack = true }

    func grade(_ grade: ReviewGrade) {
        let result = (try? session.grade(grade)) ?? session.outcome()
        passed = session.passedCount
        showingBack = false

        switch result {
        case .inProgress:
            syncFromSession()
        case .passed(let duration):
            blockingController.grantBreak(for: duration)
            phase = .earned(minutes: max(1, Int(duration / 60)))
        }
    }

    private func syncFromSession() {
        guard let card = session.currentCard else {
            // No cards to review — treat as already earned / nothing due.
            phase = session.requiredPasses == 0 ? .nothingDue : phase
            return
        }
        front = card.front
        back = card.back
    }
}
