import Foundation

/// How often each lesson has been completed. Keys are `LessonID.rawValue`
/// so the dictionary encodes as a plain JSON object.
public struct LessonProgress: Codable, Equatable, Sendable {
    public var completionCounts: [String: Int]

    public init(completionCounts: [String: Int] = [:]) {
        self.completionCounts = completionCounts
    }

    public func completions(of id: LessonID) -> Int {
        completionCounts[id.rawValue] ?? 0
    }

    public mutating func recordCompletion(of id: LessonID) {
        completionCounts[id.rawValue, default: 0] += 1
    }

    /// Distinct lessons completed at least once.
    public var lessonsCompleted: Int {
        completionCounts.values.lazy.filter { $0 > 0 }.count
    }

    /// Total completions including repeats (each one earned app time).
    public var totalCompletions: Int {
        completionCounts.values.reduce(0, +)
    }
}

public protocol LessonProgressStore: AnyObject {
    func load() -> LessonProgress
    func save(_ progress: LessonProgress)
}

/// Non-persistent store for tests and previews.
public final class InMemoryLessonProgressStore: LessonProgressStore {
    private var progress: LessonProgress
    private let lock = NSLock()

    public init(progress: LessonProgress = LessonProgress()) {
        self.progress = progress
    }

    public func load() -> LessonProgress {
        lock.lock(); defer { lock.unlock() }
        return progress
    }

    public func save(_ progress: LessonProgress) {
        lock.lock(); defer { lock.unlock() }
        self.progress = progress
    }
}

/// JSON-file backed store inside an injected directory (the App Group
/// container in the app; a temp directory in tests).
public final class FileLessonProgressStore: LessonProgressStore {
    private let fileURL: URL
    private let lock = NSLock()
    private var cached: LessonProgress

    public init(containerURL: URL) throws {
        self.fileURL = containerURL.appendingPathComponent("lessonProgress.json")
        try FileManager.default.createDirectory(
            at: containerURL, withIntermediateDirectories: true
        )
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(LessonProgress.self, from: data) {
            self.cached = decoded
        } else {
            self.cached = LessonProgress()
        }
    }

    public func load() -> LessonProgress {
        lock.lock(); defer { lock.unlock() }
        return cached
    }

    public func save(_ progress: LessonProgress) {
        lock.lock(); defer { lock.unlock() }
        cached = progress
        if let data = try? JSONEncoder().encode(progress) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
