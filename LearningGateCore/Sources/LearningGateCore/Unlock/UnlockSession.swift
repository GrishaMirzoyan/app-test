import Foundation

/// Drives one "learn to unlock" round.
///
/// The learner is presented up to `policy.cardsToUnlock` due cards. Each grade
/// advances the card's schedule (persisted immediately) and is logged. A card
/// graded `again` is re-queued to the end so the learner retries it this
/// session — reward framing: you keep going until you've earned it, you don't
/// "lose". The session is `passed` once enough distinct cards have been recalled
/// to meet `policy.passThreshold`, at which point a break of `breakDuration` is
/// granted (the caller lifts the shield and records the break).
///
/// Pure with respect to time: inject `now` for deterministic tests. Holds no
/// Screen Time concern — the caller wires the result to a `BlockingController`.
public final class UnlockSession {
    public let policy: GatePolicy

    private let scheduler: SpacedRepetitionScheduler
    private let store: CardStore
    private let recorder: ReviewRecorder?
    private let now: () -> Date

    /// Cards the learner targets this session (capped by what's actually due).
    private let targetCount: Int
    /// Distinct cards that must be passed to clear the gate.
    public let requiredPasses: Int

    private var queue: [Card]
    private var passedIDs: Set<CardID> = []
    private var totalAttempts = 0
    private var breakAlreadyRecorded = false

    public init(
        dueCards: [Card],
        policy: GatePolicy,
        scheduler: SpacedRepetitionScheduler,
        store: CardStore,
        recorder: ReviewRecorder? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.policy = policy
        self.scheduler = scheduler
        self.store = store
        self.recorder = recorder
        self.now = now

        let target = min(max(0, policy.cardsToUnlock), dueCards.count)
        self.targetCount = target
        self.queue = Array(dueCards.prefix(target))

        if target == 0 {
            self.requiredPasses = 0
        } else {
            let clamped = min(max(policy.passThreshold, 0), 1)
            self.requiredPasses = max(1, Int((Double(target) * clamped).rounded(.up)))
        }
    }

    // MARK: - State for the UI

    /// The card to show now, or nil when the session is complete.
    public var currentCard: Card? {
        isComplete ? nil : queue.first
    }

    /// Distinct cards passed so far.
    public var passedCount: Int { passedIDs.count }

    /// Total grade actions taken (including retries).
    public var attemptCount: Int { totalAttempts }

    public var isComplete: Bool {
        if case .passed = outcome() { return true }
        return false
    }

    // MARK: - Actions

    /// Grade the current card, persist its new schedule, log it, and return the
    /// updated outcome. No-op (returns current outcome) when already complete.
    @discardableResult
    public func grade(_ grade: ReviewGrade) throws -> UnlockResult {
        guard !isComplete, var card = queue.first else { return outcome() }

        let timestamp = now()
        let nextState = scheduler.nextState(for: card.scheduling, grade: grade, now: timestamp)
        card.scheduling = nextState
        try store.upsert([card])
        totalAttempts += 1

        recorder?.record(ReviewLog(
            cardID: card.id,
            deckID: card.deckID,
            grade: grade,
            reviewedAt: timestamp,
            resultingIntervalDays: nextState.intervalDays
        ))

        queue.removeFirst()
        if grade.isPass {
            passedIDs.insert(card.id)
            queue.removeAll { $0.id == card.id } // drop any stale retry copy
        } else {
            queue.append(card) // retry later this session, with advanced state
        }

        let result = outcome()
        if case .passed(let duration) = result, !breakAlreadyRecorded {
            breakAlreadyRecorded = true
            recorder?.recordBreakEarned(BreakEarnedLog(
                earnedAt: timestamp,
                cardsReviewed: totalAttempts,
                breakDuration: duration
            ))
        }
        return result
    }

    /// Current outcome without mutating anything.
    public func outcome() -> UnlockResult {
        if targetCount == 0 {
            // Nothing due — you've already earned your break.
            return .passed(grantDuration: policy.breakDuration)
        }
        if passedIDs.count >= requiredPasses {
            return .passed(grantDuration: policy.breakDuration)
        }
        return .inProgress(remaining: requiredPasses - passedIDs.count)
    }
}
