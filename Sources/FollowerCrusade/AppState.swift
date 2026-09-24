#if canImport(AppKit) && canImport(SwiftUI)
import AppKit
import Combine
import FollowerCrusadeCore

/// Central state: owns the settings store, polls the selected data source,
/// diffs snapshots into events, and drives the SpriteKit scene + menu bar.
@MainActor
final class AppState: ObservableObject {
    @Published private(set) var latest = SocialMetrics(followerCount: 0, engagementScore: 0.5)
    @Published private(set) var morale: Morale = .steady
    @Published var lastError: String?
    @Published private(set) var providerLabel: String = ""
    /// True while the SpriteKit scene is paused (rendering throttled).
    @Published var paused = false

    let store = SettingsStore.shared
    weak var scene: CampScene?

    private var pollTask: Task<Void, Never>?
    private var tickCount = 0
    private var currentSoldierTotal = 0

    init() {
        providerLabel = store.settings.providerKind.displayName
    }

    func start() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.tick()
                let interval = max(10, self.store.settings.pollIntervalSeconds)
                try? await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000_000)
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    /// One metrics cycle: fetch -> diff -> apply to scene -> persist captures.
    func tick() async {
        let settings = store.settings
        let source = DataSourceFactory.makeSource(for: settings)
        providerLabel = settings.providerKind.displayName
        do {
            let new = try await source.fetchMetrics()
            apply(new)
        } catch {
            lastError = error.localizedDescription
        }
        tickCount += 1
    }

    /// Apply a fresh snapshot: diff events, competitor thresholds, morale.
    func apply(_ new: SocialMetrics) {
        let old = latest
        latest = new
        lastError = nil

        var events = MetricsEngine.diff(old, new)

        var comps = store.settings.competitors
        let compEvents = MetricsEngine.checkCompetitors(&comps, followers: new.followerCount)
        if compEvents.contains(where: {
            if case .competitorSurpassed = $0 { return true }
            if case .competitorRepassed = $0 { return true }
            return false
        }) {
            var s = store.settings
            s.competitors = comps
            store.settings = s
        }
        events.append(contentsOf: compEvents)

        let settings = store.settings
        let composition = MetricsEngine.composition(
            followers: new.followerCount,
            ratio: settings.soldiersPerFollower,
            cap: settings.maxSoldiers
        )

        scene?.syncOutposts(comps)
        for event in events {
            switch event {
            case .followersChanged:
                let soldierDelta = composition.total - currentSoldierTotal
                if soldierDelta > 0 {
                    scene?.spawnRecruits(min(soldierDelta, 8))
                } else if soldierDelta < 0 {
                    scene?.loseSoldiers(min(-soldierDelta, 8))
                }
                currentSoldierTotal = composition.total
            case .engagementUpdated(let score):
                let m = MetricsEngine.morale(forEngagement: score)
                morale = m
                scene?.setMorale(m)
            case .competitorSurpassed(let id):
                scene?.captureOutpost(id: id)
            case .competitorRepassed(let id):
                scene?.uncaptureOutpost(id: id)
            }
        }
        scene?.applyComposition(composition)
        currentSoldierTotal = composition.total

        // Occasional desertion while morale is poor.
        if tickCount % 4 == 0,
           MetricsEngine.shouldDesert(morale: morale, roll: .random(in: 0...1)) {
            scene?.desertSoldier()
        }
    }

    // Mock-mode helpers wired to the menu / settings.
    func simulateGain(_ n: Int = 25) async {
        DataSourceFactory.mock.simulate(n)
        await tick()
    }

    func simulateLoss(_ n: Int = 25) async {
        DataSourceFactory.mock.simulate(-n)
        await tick()
    }

    func refreshNow() async { await tick() }
}
#endif
