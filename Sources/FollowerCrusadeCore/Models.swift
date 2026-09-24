import Foundation

/// The social platform a metric batch or a soldier originates from.
/// Instagram is the only platform currently supported; the type stays
/// extensible so additional platforms can be added later.
public enum OriginPlatform: String, Codable, CaseIterable, Sendable {
    case instagram

    public var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        }
    }
}

/// Which data adapter feeds follower metrics. Selectable in Settings.
public enum DataProviderKind: String, Codable, CaseIterable, Sendable {
    case mock
    case instagramGraph
    case metricoolInstagram

    public var displayName: String {
        switch self {
        case .mock: return "Mock (slider mode)"
        case .instagramGraph: return "Instagram Graph API (direct)"
        case .metricoolInstagram: return "Metricool — Instagram connection"
        }
    }
}

/// A point-in-time snapshot of the tracked account.
public struct SocialMetrics: Equatable, Sendable {
    public var followerCount: Int
    /// Rolled-up engagement signal in 0...1 (posts, likes, comments).
    /// Drives supplies/campfire morale.
    public var engagementScore: Double
    public var platform: OriginPlatform
    public var fetchedAt: Date

    public init(followerCount: Int, engagementScore: Double, platform: OriginPlatform = .instagram, fetchedAt: Date = Date()) {
        self.followerCount = followerCount
        self.engagementScore = min(1, max(0, engagementScore))
        self.platform = platform
        self.fetchedAt = fetchedAt
    }
}

/// Events produced by diffing two snapshots; they drive scene animations.
public enum MetricEvent: Equatable, Sendable {
    /// Signed follower delta — positive spawns recruits, negative sends arrows.
    case followersChanged(Int)
    /// New engagement score — adjusts campfires/morale.
    case engagementUpdated(Double)
    /// A competitor outpost should be stormed and the banner raised.
    case competitorSurpassed(UUID)
    /// Fell back below a previously captured competitor's threshold.
    case competitorRepassed(UUID)
}

/// A rival account shown as an outpost/tower on the campaign map.
public struct Competitor: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var handle: String
    /// Follower threshold the user must surpass to capture this outpost.
    public var followerThreshold: Int
    /// Whether the banner has already been raised on this outpost.
    public var captured: Bool

    public init(id: UUID = UUID(), name: String, handle: String, followerThreshold: Int, captured: Bool = false) {
        self.id = id
        self.name = name
        self.handle = handle
        self.followerThreshold = followerThreshold
        self.captured = captured
    }
}

/// Camp morale derived from engagement. Drives campfire size, smoke,
/// soldier idle behavior, and desertion.
public enum Morale: Int, Comparable, Sendable {
    case mutinous = 0
    case low
    case steady
    case high
    case exultant

    public static func < (lhs: Morale, rhs: Morale) -> Bool { lhs.rawValue < rhs.rawValue }

    public var displayName: String {
        switch self {
        case .mutinous: return "Mutinous"
        case .low: return "Low"
        case .steady: return "Steady"
        case .high: return "High"
        case .exultant: return "Exultant"
        }
    }
}

/// How the rendered army is composed for a given follower count.
/// Ranks unlock with headcount milestones.
public struct ArmyComposition: Equatable, Sendable {
    public var footSoldiers: Int
    public var archers: Int
    public var knights: Int

    public var total: Int { footSoldiers + archers + knights }
}

/// Where the HUD window sits. `.free` floats wherever it was dragged;
/// the rest dock to a screen corner.
public enum DockCorner: String, Codable, CaseIterable, Sendable {
    case free
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    public var displayName: String {
        switch self {
        case .free: return "Floating"
        case .topLeft: return "Top-left corner"
        case .topRight: return "Top-right corner"
        case .bottomLeft: return "Bottom-left corner"
        case .bottomRight: return "Bottom-right corner"
        }
    }
}
