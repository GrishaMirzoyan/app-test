import Foundation

/// Shared streak math, factored out so both store implementations agree.
enum StreakCalculator {
    /// Consecutive days (by `calendar`) ending today that have at least one
    /// review. Today not yet reviewed doesn't break the streak — we anchor on
    /// yesterday in that case so the count only resets after a full missed day.
    static func currentStreak(reviewDates: [Date], now: Date, calendar: Calendar) -> Int {
        guard !reviewDates.isEmpty else { return 0 }
        let days = Set(reviewDates.map { calendar.startOfDay(for: $0) })
        let today = calendar.startOfDay(for: now)

        var anchor: Date
        if days.contains(today) {
            anchor = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  days.contains(yesterday) {
            anchor = yesterday
        } else {
            return 0
        }

        var streak = 0
        var cursor = anchor
        while days.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }
}

/// Non-persistent review store for tests and previews.
public final class InMemoryReviewStore: ReviewRecorder, StatsService {
    private var logs: [ReviewLog] = []
    private var breaks: [BreakEarnedLog] = []
    private let calendar: Calendar
    private let lock = NSLock()

    public init(calendar: Calendar = .current) { self.calendar = calendar }

    public func record(_ log: ReviewLog) {
        lock.lock(); defer { lock.unlock() }
        logs.append(log)
    }

    public func recordBreakEarned(_ event: BreakEarnedLog) {
        lock.lock(); defer { lock.unlock() }
        breaks.append(event)
    }

    public func current(now: Date) -> Stats {
        lock.lock(); defer { lock.unlock() }
        return Stats(
            cardsReviewed: logs.count,
            currentStreakDays: StreakCalculator.currentStreak(
                reviewDates: logs.map { $0.reviewedAt }, now: now, calendar: calendar
            ),
            breaksEarned: breaks.count
        )
    }
}

/// JSON-file backed review store inside an injected directory (the App Group
/// container in the app). Appends are loaded into memory and rewritten
/// atomically; v1 log volumes are small enough that this is fine.
public final class FileReviewStore: ReviewRecorder, StatsService {
    private let reviewsURL: URL
    private let breaksURL: URL
    private let calendar: Calendar
    private let lock = NSLock()
    private var logs: [ReviewLog]
    private var breaks: [BreakEarnedLog]

    public init(containerURL: URL, calendar: Calendar = .current) throws {
        self.calendar = calendar
        self.reviewsURL = containerURL.appendingPathComponent("reviews.json")
        self.breaksURL = containerURL.appendingPathComponent("breaks.json")
        try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)

        let decoder = JSONDecoder()
        if let data = try? Data(contentsOf: reviewsURL),
           let decoded = try? decoder.decode([ReviewLog].self, from: data) {
            self.logs = decoded
        } else { self.logs = [] }
        if let data = try? Data(contentsOf: breaksURL),
           let decoded = try? decoder.decode([BreakEarnedLog].self, from: data) {
            self.breaks = decoded
        } else { self.breaks = [] }
    }

    public func record(_ log: ReviewLog) {
        lock.lock(); defer { lock.unlock() }
        logs.append(log)
        try? Data.encodeAtomically(logs, to: reviewsURL)
    }

    public func recordBreakEarned(_ event: BreakEarnedLog) {
        lock.lock(); defer { lock.unlock() }
        breaks.append(event)
        try? Data.encodeAtomically(breaks, to: breaksURL)
    }

    public func current(now: Date) -> Stats {
        lock.lock(); defer { lock.unlock() }
        return Stats(
            cardsReviewed: logs.count,
            currentStreakDays: StreakCalculator.currentStreak(
                reviewDates: logs.map { $0.reviewedAt }, now: now, calendar: calendar
            ),
            breaksEarned: breaks.count
        )
    }
}

private extension Data {
    static func encodeAtomically<T: Encodable>(_ value: T, to url: URL) throws {
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: .atomic)
    }
}
