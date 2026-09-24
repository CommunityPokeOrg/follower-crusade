import XCTest
@testable import FollowerCrusadeCore

final class MetricsEngineTests: XCTestCase {

    // MARK: - diff

    func testDiffEmitsFollowerGain() {
        let old = SocialMetrics(followerCount: 100, engagementScore: 0.5)
        let new = SocialMetrics(followerCount: 103, engagementScore: 0.5)
        XCTAssertEqual(MetricsEngine.diff(old, new), [.followersChanged(3)])
    }

    func testDiffEmitsFollowerLoss() {
        let old = SocialMetrics(followerCount: 100, engagementScore: 0.5)
        let new = SocialMetrics(followerCount: 97, engagementScore: 0.5)
        XCTAssertEqual(MetricsEngine.diff(old, new), [.followersChanged(-3)])
    }

    func testDiffEmitsEngagementChange() {
        let old = SocialMetrics(followerCount: 100, engagementScore: 0.5)
        let new = SocialMetrics(followerCount: 100, engagementScore: 0.8)
        XCTAssertEqual(MetricsEngine.diff(old, new), [.engagementUpdated(0.8)])
    }

    func testDiffNoChangeEmitsNothing() {
        let a = SocialMetrics(followerCount: 42, engagementScore: 0.3)
        XCTAssertEqual(MetricsEngine.diff(a, a), [])
    }

    func testDiffCombined() {
        let old = SocialMetrics(followerCount: 10, engagementScore: 0.2)
        let new = SocialMetrics(followerCount: 15, engagementScore: 0.9)
        XCTAssertEqual(MetricsEngine.diff(old, new),
                       [.followersChanged(5), .engagementUpdated(0.9)])
    }

    // MARK: - competitors

    func testCompetitorSurpassedOnce() {
        var comps = [Competitor(name: "Rival", handle: "@rival", followerThreshold: 500)]
        let id = comps[0].id
        let events = MetricsEngine.checkCompetitors(&comps, followers: 600)
        XCTAssertEqual(events, [.competitorSurpassed(id)])
        XCTAssertTrue(comps[0].captured)
        // No repeat event on a later check while still above threshold.
        XCTAssertEqual(MetricsEngine.checkCompetitors(&comps, followers: 700), [])
    }

    func testCompetitorRepassed() {
        var comps = [Competitor(name: "Rival", handle: "@rival", followerThreshold: 500, captured: true)]
        let id = comps[0].id
        let events = MetricsEngine.checkCompetitors(&comps, followers: 400)
        XCTAssertEqual(events, [.competitorRepassed(id)])
        XCTAssertFalse(comps[0].captured)
    }

    func testCompetitorBelowThresholdUntouched() {
        var comps = [Competitor(name: "Rival", handle: "@rival", followerThreshold: 500)]
        XCTAssertEqual(MetricsEngine.checkCompetitors(&comps, followers: 500), [])
        XCTAssertFalse(comps[0].captured)
    }

    // MARK: - morale

    func testMoraleBands() {
        XCTAssertEqual(MetricsEngine.morale(forEngagement: 0.05), .mutinous)
        XCTAssertEqual(MetricsEngine.morale(forEngagement: 0.25), .low)
        XCTAssertEqual(MetricsEngine.morale(forEngagement: 0.50), .steady)
        XCTAssertEqual(MetricsEngine.morale(forEngagement: 0.75), .high)
        XCTAssertEqual(MetricsEngine.morale(forEngagement: 0.95), .exultant)
    }

    func testDesertionOnlyWhenMoraleLow() {
        XCTAssertTrue(MetricsEngine.shouldDesert(morale: .mutinous, roll: 0.1))
        XCTAssertFalse(MetricsEngine.shouldDesert(morale: .mutinous, roll: 0.5))
        XCTAssertTrue(MetricsEngine.shouldDesert(morale: .low, roll: 0.05))
        XCTAssertFalse(MetricsEngine.shouldDesert(morale: .low, roll: 0.5))
        XCTAssertFalse(MetricsEngine.shouldDesert(morale: .steady, roll: 0.01))
        XCTAssertFalse(MetricsEngine.shouldDesert(morale: .exultant, roll: 0.01))
    }

    // MARK: - composition

    func testCompositionRespectsRatio() {
        // 1200 followers / 250 = 4 soldiers, below archer threshold.
        let small = MetricsEngine.composition(followers: 1200, ratio: 250, cap: 60)
        XCTAssertEqual(small, ArmyComposition(footSoldiers: 4, archers: 0, knights: 0))
    }

    func testCompositionRespectsCap() {
        // 100k followers -> capped at 60: 15 archers, 6 knights, 39 foot.
        let big = MetricsEngine.composition(followers: 100_000, ratio: 250, cap: 60)
        XCTAssertEqual(big.total, 60)
        XCTAssertEqual(big.archers, 15)
        XCTAssertEqual(big.knights, 6)
        XCTAssertEqual(big.footSoldiers, 39)
    }

    func testCompositionArcherAndKnightMilestones() {
        let at10 = MetricsEngine.composition(followers: 2500, ratio: 250, cap: 100)
        XCTAssertEqual(at10.total, 10)
        XCTAssertEqual(at10.archers, 2)
        XCTAssertEqual(at10.knights, 0)

        let at25 = MetricsEngine.composition(followers: 6250, ratio: 250, cap: 100)
        XCTAssertEqual(at25.total, 25)
        XCTAssertEqual(at25.knights, 2)
        XCTAssertEqual(at25.archers, 6)
    }
}
