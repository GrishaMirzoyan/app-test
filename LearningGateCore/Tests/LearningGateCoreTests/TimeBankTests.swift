import XCTest
@testable import LearningGateCore

final class TimeBankTests: XCTestCase {
    func testCreditAccumulates() {
        let bank = TimeBank(store: InMemoryTimeBankStore())
        XCTAssertEqual(bank.balance, 0)
        bank.credit(60)
        bank.credit(60)
        XCTAssertEqual(bank.balance, 120)
    }

    func testNegativeCreditIsIgnored() {
        let bank = TimeBank(store: InMemoryTimeBankStore())
        bank.credit(-30)
        XCTAssertEqual(bank.balance, 0)
    }

    func testRedeemAllZeroesTheBalance() {
        let bank = TimeBank(store: InMemoryTimeBankStore(balance: 180))
        XCTAssertEqual(bank.redeemAll(), 180)
        XCTAssertEqual(bank.balance, 0)
        XCTAssertEqual(bank.redeemAll(), 0)
    }

    func testRedeemUpToIsCappedByBalance() {
        let bank = TimeBank(store: InMemoryTimeBankStore(balance: 90))
        XCTAssertEqual(bank.redeem(upTo: 60), 60)
        XCTAssertEqual(bank.balance, 30)
        XCTAssertEqual(bank.redeem(upTo: 60), 30) // only what's left
        XCTAssertEqual(bank.balance, 0)
        XCTAssertEqual(bank.redeem(upTo: -5), 0)
    }

    func testBalancePersistsToStore() {
        let store = InMemoryTimeBankStore()
        TimeBank(store: store).credit(75)
        // A new bank over the same store sees the saved balance.
        XCTAssertEqual(TimeBank(store: store).balance, 75)
    }

    func testFileStoreRoundTripsAndClampsNegative() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("timebank-tests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = try FileTimeBankStore(containerURL: dir)
        XCTAssertEqual(store.loadBalance(), 0) // missing file → empty bank
        store.saveBalance(120)
        XCTAssertEqual(store.loadBalance(), 120)
        store.saveBalance(-10)
        XCTAssertEqual(store.loadBalance(), 0)

        let reopened = try FileTimeBankStore(containerURL: dir)
        XCTAssertEqual(reopened.loadBalance(), 0)
    }
}
