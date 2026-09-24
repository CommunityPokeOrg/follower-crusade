import XCTest
@testable import FollowerCrusadeCore

final class WarLedgerTests: XCTestCase {

    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    func testRecordFollowerGainAndLoss() {
        var ledger = WarLedger()
        ledger.record(.followersChanged(25), at: t0) { _ in nil }
        ledger.record(.followersChanged(-8), at: t0) { _ in nil }

        XCTAssertEqual(ledger.entries.count, 2)
        XCTAssertEqual(ledger.entries[0].kind, .recruitsJoined)
        XCTAssertEqual(ledger.entries[0].amount, 25)
        XCTAssertEqual(ledger.entries[0].detail, "+25 recruits arrived")
        XCTAssertEqual(ledger.entries[1].kind, .soldiersLost)
        XCTAssertEqual(ledger.entries[1].amount, 8)
    }

    func testRecordCompetitorEventsResolvesNames() {
        var ledger = WarLedger()
        let id = UUID()
        ledger.record(.competitorSurpassed(id), at: t0) { $0 == id ? "Rival Keep" : nil }
        ledger.record(.competitorRepassed(id), at: t0) { $0 == id ? "Rival Keep" : nil }

        XCTAssertEqual(ledger.entries[0].kind, .outpostCaptured)
        XCTAssertEqual(ledger.entries[0].detail, "Rival Keep captured")
        XCTAssertEqual(ledger.entries[1].kind, .outpostLost)
        XCTAssertEqual(ledger.entries[1].detail, "Rival Keep retaken by rivals")
    }

    func testEngagementEventsAreNotRecorded() {
        var ledger = WarLedger()
        ledger.record(.engagementUpdated(0.9), at: t0) { _ in nil }
        XCTAssertTrue(ledger.entries.isEmpty)
    }

    func testDesertionRecorded() {
        var ledger = WarLedger()
        ledger.recordDesertion(at: t0)
        XCTAssertEqual(ledger.entries[0].kind, .soldierDeserted)
        XCTAssertEqual(ledger.entries[0].amount, 1)
    }

    func testSummaryAggregatesWindow() {
        var ledger = WarLedger()
        ledger.record(.followersChanged(5), at: t0) { _ in nil }
        ledger.record(.followersChanged(-2), at: t0) { _ in nil }
        ledger.recordDesertion(at: t0)
        let id = UUID()
        ledger.record(.competitorSurpassed(id), at: t0) { _ in "Tower" }

        let s = ledger.summary(since: t0)
        XCTAssertEqual(s.joined, 5)
        XCTAssertEqual(s.lost, 2)
        XCTAssertEqual(s.deserted, 1)
        XCTAssertEqual(s.captured, 1)
        XCTAssertFalse(s.isEmpty)
        XCTAssertEqual(s.text, "+5 recruits arrived, 2 fallen in battle, 1 deserted, 1 outpost captured")
    }

    func testSummaryExcludesOlderEntries() {
        var ledger = WarLedger()
        ledger.record(.followersChanged(5), at: t0) { _ in nil }
        let later = t0.addingTimeInterval(60)
        let s = ledger.summary(since: later)
        XCTAssertTrue(s.isEmpty)
    }

    func testRecentIsNewestFirstAndCapped() {
        var ledger = WarLedger()
        for i in 0..<5 {
            ledger.record(.followersChanged(i + 1), at: t0.addingTimeInterval(TimeInterval(i))) { _ in nil }
        }
        let recent = ledger.recent(3)
        XCTAssertEqual(recent.count, 3)
        XCTAssertEqual(recent[0].amount, 5)
        XCTAssertEqual(recent[2].amount, 3)
    }

    func testLedgerTrimsAtLimit() {
        var ledger = WarLedger(limit: 10)
        for i in 0..<15 {
            ledger.record(.followersChanged(i + 1), at: t0) { _ in nil }
        }
        XCTAssertEqual(ledger.entries.count, 10)
        XCTAssertEqual(ledger.entries.last?.amount, 15)
        XCTAssertEqual(ledger.entries.first?.amount, 6)
    }
}
