#if canImport(Foundation)
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation
import FollowerCrusadeCore

/// A source of social metrics. Only Instagram is currently supported, exposed
/// through two adapters selectable in Settings, plus a mock source for testing.
public protocol SocialDataSource: Sendable {
    var kind: DataProviderKind { get }
    func fetchMetrics() async throws -> SocialMetrics
}

public enum DataSourceError: LocalizedError {
    case missingCredentials(String)
    case badResponse(Int)
    case malformed(String)

    public var errorDescription: String? {
        switch self {
        case .missingCredentials(let what): return "Missing credential: \(what)"
        case .badResponse(let code): return "HTTP \(code)"
        case .malformed(let what): return "Malformed response: \(what)"
        }
    }
}

// MARK: - Mock

/// Deterministic mock source driven by Settings sliders plus an optional
/// random walk so every animation is testable without credentials.
public final class MockDataSource: SocialDataSource, @unchecked Sendable {
    public let kind = DataProviderKind.mock
    private let store: SettingsStore
    private var followers: Int
    private var engagement: Double

    public init(store: SettingsStore = .shared) {
        self.store = store
        followers = store.settings.mockFollowers
        engagement = store.settings.mockEngagement
    }

    /// Apply slider-driven values from Settings directly (no random walk).
    public func snapToSettings() {
        followers = store.settings.mockFollowers
        engagement = store.settings.mockEngagement
    }

    public func simulate(_ delta: Int) {
        followers = max(0, followers + delta)
        persist()
    }

    public func fetchMetrics() async throws -> SocialMetrics {
        if store.settings.mockRandomWalk {
            // Small random drift: occasional gains and rarer losses.
            let roll = Double.random(in: 0...1)
            if roll < 0.55 { followers += Int.random(in: 1...4) }
            else if roll < 0.65 { followers = max(0, followers - Int.random(in: 1...2)) }
            engagement = min(1, max(0, engagement + Double.random(in: -0.08...0.08)))
        } else {
            // Sliders are authoritative when random walk is off.
            followers = store.settings.mockFollowers
            engagement = store.settings.mockEngagement
        }
        persist()
        return SocialMetrics(followerCount: followers, engagementScore: engagement)
    }

    private func persist() {
        var s = store.settings
        s.mockFollowers = followers
        s.mockEngagement = engagement
        store.settings = s
    }
}

// MARK: - Instagram Graph API (direct)

/// Direct adapter for Instagram via the Graph API. Works with:
///  - Instagram Graph API (business/creator): GET /{ig-user-id}?fields=followers_count
///  - Instagram Basic Display API: GET graph.instagram.com/me?fields=...&access_token=
/// Engagement is estimated from recent media like/comment counts when the
/// token has `instagram_basic` + `pages_read_engagement` access; otherwise a
/// neutral value is returned.
public struct InstagramGraphDataSource: SocialDataSource {
    public let kind = DataProviderKind.instagramGraph
    private let accessToken: String
    private let userID: String
    private static let apiVersion = "v21.0"

    public init(accessToken: String, userID: String) {
        self.accessToken = accessToken
        self.userID = userID.isEmpty ? "me" : userID
    }

    public func fetchMetrics() async throws -> SocialMetrics {
        guard !accessToken.isEmpty else {
            throw DataSourceError.missingCredentials("Instagram access token")
        }
        let base = userID == "me"
            ? "https://graph.instagram.com"
            : "https://graph.facebook.com/\(Self.apiVersion)"
        var comps = URLComponents(string: "\(base)/\(userID)")!
        comps.queryItems = [
            URLQueryItem(name: "fields", value: "followers_count,media_count"),
            URLQueryItem(name: "access_token", value: accessToken),
        ]
        let (data, resp) = try await URLSession.shared.data(from: comps.url!)
        if let http = resp as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw DataSourceError.badResponse(http.statusCode)
        }
        struct Profile: Decodable { let followers_count: Int? }
        let profile = try JSONDecoder().decode(Profile.self, from: data)
        guard let followers = profile.followers_count else {
            throw DataSourceError.malformed("no followers_count field")
        }
        let engagement = (try? await fetchEngagement()) ?? 0.5
        return SocialMetrics(followerCount: followers, engagementScore: engagement, platform: .instagram)
    }

    /// Mean like+comment counts across recent media, normalized to 0...1.
    /// Requires business-account permissions; failures degrade to nil.
    private func fetchEngagement() async throws -> Double? {
        var comps = URLComponents(string: "https://graph.facebook.com/\(Self.apiVersion)/\(userID)/media")!
        comps.queryItems = [
            URLQueryItem(name: "fields", value: "like_count,comments_count"),
            URLQueryItem(name: "limit", value: "12"),
            URLQueryItem(name: "access_token", value: accessToken),
        ]
        let (data, resp) = try await URLSession.shared.data(from: comps.url!)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
        struct Media: Decodable { let like_count: Int?; let comments_count: Int? }
        struct Page: Decodable { let data: [Media] }
        let page = try JSONDecoder().decode(Page.self, from: data)
        guard !page.data.isEmpty else { return nil }
        let mean = page.data.reduce(0.0) { $0 + Double($1.like_count ?? 0) + Double($1.comments_count ?? 0) } / Double(page.data.count)
        // ~200 interactions/post counts as full engagement; tune as desired.
        return min(1, mean / 200.0)
    }
}

// MARK: - Metricool (Instagram connection)

/// Adapter for Metricool's API reading the connected Instagram profile.
/// Requires a Metricool user token and the blogId of the Instagram network
/// connection. See https://app.metricool.com/api/docs (paths may need adjusting
/// to your Metricool plan's available endpoints).
public struct MetricoolInstagramDataSource: SocialDataSource {
    public let kind = DataProviderKind.metricoolInstagram
    private let apiKey: String
    private let userID: String
    private let blogID: String
    private let baseURL = URL(string: "https://app.metricool.com/api")!

    public init(apiKey: String, userID: String, blogID: String) {
        self.apiKey = apiKey
        self.userID = userID
        self.blogID = blogID
    }

    public func fetchMetrics() async throws -> SocialMetrics {
        guard !apiKey.isEmpty else { throw DataSourceError.missingCredentials("Metricool API key") }
        guard !userID.isEmpty else { throw DataSourceError.missingCredentials("Metricool user ID") }
        guard !blogID.isEmpty else { throw DataSourceError.missingCredentials("Metricool blog ID") }

        // Followers over the trailing period; summed to a current count.
        var comps = URLComponents(url: baseURL.appendingPathComponent("/v2/stats/aggregation/instagram/followers"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "start", value: "19700101000000"),
            URLQueryItem(name: "end", value: "21000101000000"),
            URLQueryItem(name: "timezone", value: "UTC"),
            URLQueryItem(name: "userId", value: userID),
            URLQueryItem(name: "blogId", value: blogID),
        ]
        var req = URLRequest(url: comps.url!)
        req.setValue(apiKey, forHTTPHeaderField: "X-Mc-Auth")
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw DataSourceError.badResponse(http.statusCode)
        }
        // Metricool aggregation payloads vary by plan; accept a few shapes.
        let followers = try Self.extractFollowerCount(from: data)
        let engagement = (try? await fetchEngagement()) ?? 0.5
        return SocialMetrics(followerCount: followers, engagementScore: engagement, platform: .instagram)
    }

    private static func extractFollowerCount(from data: Data) throws -> Int {
        let json = try JSONSerialization.jsonObject(with: data)
        if let obj = json as? [String: Any] {
            if let n = obj["data"] as? NSNumber { return n.intValue }
            if let arr = obj["data"] as? [[String: Any]],
               let last = arr.last, let n = last["value"] as? NSNumber { return n.intValue }
            if let n = obj["followers"] as? NSNumber { return n.intValue }
        }
        if let arr = json as? [[String: Any]], let last = arr.last, let n = last["value"] as? NSNumber {
            return n.intValue
        }
        throw DataSourceError.malformed("unrecognized followers payload")
    }

    private func fetchEngagement() async throws -> Double? {
        var comps = URLComponents(url: baseURL.appendingPathComponent("/v2/stats/aggregation/instagram/interactions"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "start", value: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-30 * 86400)).replacingOccurrences(of: "[-:T.Z]", with: "", options: .regularExpression)),
            URLQueryItem(name: "end", value: "21000101000000"),
            URLQueryItem(name: "timezone", value: "UTC"),
            URLQueryItem(name: "userId", value: userID),
            URLQueryItem(name: "blogId", value: blogID),
        ]
        var req = URLRequest(url: comps.url!)
        req.setValue(apiKey, forHTTPHeaderField: "X-Mc-Auth")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
        let json = try JSONSerialization.jsonObject(with: data)
        if let obj = json as? [String: Any], let arr = obj["data"] as? [[String: Any]] {
            let total = arr.compactMap { ($0["value"] as? NSNumber)?.doubleValue }.reduce(0, +)
            return min(1, total / 500.0)
        }
        return nil
    }
}

// MARK: - Factory

public enum DataSourceFactory {
    /// The mock source is retained so Settings sliders and simulation buttons
    /// can poke at it directly.
    public static let mock = MockDataSource()

    public static func makeSource(for settings: AppSettings) -> SocialDataSource {
        switch settings.providerKind {
        case .mock:
            return mock
        case .instagramGraph:
            return InstagramGraphDataSource(accessToken: settings.instagramAccessToken,
                                            userID: settings.instagramUserID)
        case .metricoolInstagram:
            return MetricoolInstagramDataSource(apiKey: settings.metricoolAPIKey,
                                                userID: settings.metricoolUserID,
                                                blogID: settings.metricoolBlogID)
        }
    }
}
#endif
