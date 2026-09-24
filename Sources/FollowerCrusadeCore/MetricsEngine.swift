import Foundation

/// Pure functions that turn metric snapshots into scene events.
public enum MetricsEngine {

    // MARK: - Snapshot diffing

    /// Diff two snapshots into scene events. Ordered so follower deltas
    /// arrive before morale/competitor changes.
    public static func diff(_ old: SocialMetrics, _ new: SocialMetrics) -> [MetricEvent] {
        var events: [MetricEvent] = []
        let delta = new.followerCount - old.followerCount
        if delta != 0 {
            events.append(.followersChanged(delta))
        }
        if abs(new.engagementScore - old.engagementScore) > 0.001 {
            events.append(.engagementUpdated(new.engagementScore))
        }
        return events
    }

    /// Check competitors against the latest follower count and mark captures.
    /// Returns `competitorSurpassed` for newly captured outposts and
    /// `competitorRepassed` if the count fell back under a captured threshold.
    @discardableResult
    public static func checkCompetitors(_ competitors: inout [Competitor], followers: Int) -> [MetricEvent] {
        var events: [MetricEvent] = []
        for i in competitors.indices {
            if !competitors[i].captured && followers > competitors[i].followerThreshold {
                competitors[i].captured = true
                events.append(.competitorSurpassed(competitors[i].id))
            } else if competitors[i].captured && followers <= competitors[i].followerThreshold {
                competitors[i].captured = false
                events.append(.competitorRepassed(competitors[i].id))
            }
        }
        return events
    }

    // MARK: - Morale

    /// Map an engagement score (0...1) to camp morale.
    public static func morale(forEngagement score: Double) -> Morale {
        switch score {
        case ..<0.15: return .mutinous
        case ..<0.35: return .low
        case ..<0.60: return .steady
        case ..<0.85: return .high
        default: return .exultant
        }
    }

    /// Whether morale is low enough that a soldier may desert on a tick.
    /// `engagement` below the threshold rolls `chance` of desertion.
    public static func shouldDesert(morale: Morale, roll: Double) -> Bool {
        switch morale {
        case .mutinous: return roll < 0.30
        case .low: return roll < 0.08
        default: return false
        }
    }

    // MARK: - Army composition

    /// Map a follower count to rendered soldier counts. One soldier per
    /// `ratio` followers, capped at `cap`; archers and knights unlock as the
    /// army grows and make up fixed shares of the roster.
    public static func composition(followers: Int, ratio: Int, cap: Int) -> ArmyComposition {
        let r = max(1, ratio)
        let total = min(max(0, followers / r), max(0, cap))
        // Milestone unlocks: archers at 10+ soldiers, knights at 25+.
        let knights = total >= 25 ? total / 10 : 0
        let archers = total >= 10 ? total / 4 : 0
        let foot = total - archers - knights
        return ArmyComposition(footSoldiers: foot, archers: archers, knights: knights)
    }
}
