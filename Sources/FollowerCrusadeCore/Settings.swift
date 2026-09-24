import Foundation

/// Persisted app configuration.
public struct AppSettings: Codable, Equatable, Sendable {
    // Data source selection — Instagram is the only supported platform; the
    // provider layer is extensible for future platforms.
    public var providerKind: DataProviderKind = .mock

    // Direct Instagram API / Graph API adapter
    public var instagramAccessToken: String = ""
    /// Instagram-scoped user ID (IGSID) or "me" when using Basic Display tokens.
    public var instagramUserID: String = "me"

    // Metricool adapter (Instagram connection)
    public var metricoolAPIKey: String = ""
    public var metricoolUserID: String = ""
    /// Metricool "blogId" identifying the Instagram connection's profile.
    public var metricoolBlogID: String = ""

    // Rendering / behavior
    /// One soldier per N followers.
    public var soldiersPerFollower: Int = 250
    /// Maximum simultaneously rendered soldiers (keeps the scene light).
    public var maxSoldiers: Int = 60
    public var pollIntervalSeconds: TimeInterval = 60
    public var effectsEnabled: Bool = true

    // Mock-mode controls (slider mode)
    public var mockFollowers: Int = 1240
    public var mockEngagement: Double = 0.6
    public var mockRandomWalk: Bool = true

    // Window
    public var dockCorner: DockCorner = .bottomRight
    /// Last free-floating frame, persisted across launches (AppKit rect string).
    public var floatingFrame: String = ""

    // Competitors / outposts
    public var competitors: [Competitor] = []

    public init() {}
}

/// UserDefaults-backed settings persistence. Deliberately tiny: one JSON blob.
public final class SettingsStore: @unchecked Sendable {
    public static let shared = SettingsStore()

    private let defaults: UserDefaults
    private let key = "followerCrusade.settings.v1"
    private let lock = NSLock()
    private var _settings: AppSettings

    public var settings: AppSettings {
        get { lock.lock(); defer { lock.unlock() }; return _settings }
        set {
            lock.lock()
            _settings = newValue
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: key)
            }
            lock.unlock()
        }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        var loaded = AppSettings()
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            loaded = decoded
        }
        _settings = loaded
    }
}
