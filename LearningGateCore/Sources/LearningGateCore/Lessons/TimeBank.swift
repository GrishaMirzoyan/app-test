import Foundation

/// Persists the earned-time balance (seconds).
public protocol TimeBankStore: AnyObject {
    func loadBalance() -> TimeInterval
    func saveBalance(_ balance: TimeInterval)
}

/// Non-persistent store for tests and previews.
public final class InMemoryTimeBankStore: TimeBankStore {
    private var balance: TimeInterval
    public init(balance: TimeInterval = 0) { self.balance = balance }
    public func loadBalance() -> TimeInterval { balance }
    public func saveBalance(_ balance: TimeInterval) { self.balance = balance }
}

/// JSON-file backed store inside an injected directory.
public final class FileTimeBankStore: TimeBankStore {
    private struct Payload: Codable { var balance: TimeInterval }

    private let fileURL: URL

    public init(containerURL: URL) throws {
        self.fileURL = containerURL.appendingPathComponent("timeBank.json")
        try FileManager.default.createDirectory(
            at: containerURL, withIntermediateDirectories: true
        )
    }

    public func loadBalance() -> TimeInterval {
        guard let data = try? Data(contentsOf: fileURL),
              let payload = try? JSONDecoder().decode(Payload.self, from: data)
        else { return 0 }
        return max(0, payload.balance)
    }

    public func saveBalance(_ balance: TimeInterval) {
        guard let data = try? JSONEncoder().encode(Payload(balance: max(0, balance)))
        else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

/// The wallet of earned app time: each completed lesson credits
/// `GatePolicy.timePerLesson`; starting a break redeems (and zeroes) what's
/// spendable. Doing several lessons back-to-back banks a longer break —
/// that's the "1 lesson = 1 minute" economy from the spec.
public final class TimeBank {
    private let store: TimeBankStore
    private let lock = NSLock()
    private var cached: TimeInterval

    public init(store: TimeBankStore) {
        self.store = store
        self.cached = max(0, store.loadBalance())
    }

    /// Spendable seconds currently banked.
    public var balance: TimeInterval {
        lock.lock(); defer { lock.unlock() }
        return cached
    }

    /// Add earned seconds; returns the new balance. Negative credits are ignored.
    @discardableResult
    public func credit(_ seconds: TimeInterval) -> TimeInterval {
        lock.lock(); defer { lock.unlock() }
        cached += max(0, seconds)
        store.saveBalance(cached)
        return cached
    }

    /// Withdraw up to `seconds`; returns what was actually granted.
    public func redeem(upTo seconds: TimeInterval) -> TimeInterval {
        lock.lock(); defer { lock.unlock() }
        let granted = min(max(0, seconds), cached)
        cached -= granted
        store.saveBalance(cached)
        return granted
    }

    /// Withdraw the whole balance; returns it.
    public func redeemAll() -> TimeInterval {
        lock.lock(); defer { lock.unlock() }
        let granted = cached
        cached = 0
        store.saveBalance(cached)
        return granted
    }
}
