#if canImport(AppKit) && canImport(SwiftUI)
import AppKit
import Combine
import SwiftUI
import FollowerCrusadeCore

/// Menu bar accessory: follower count plus controls for the HUD, mock
/// simulation, settings, about, and quit.
@MainActor
final class MenuBarController: NSObject {

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var state: AppState
    private var observation: AnyCancellable?

    var onToggleHUD: () -> Void = {}
    var onOpenSettings: () -> Void = {}
    var onOpenAbout: () -> Void = {}

    init(state: AppState) {
        self.state = state
        super.init()
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "shield.lefthalf.filled",
                                   accessibilityDescription: "Follower Crusade")
            button.imagePosition = .imageLeading
            button.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        }
        rebuildMenu()
        observation = state.$latest
            .receive(on: RunLoop.main)
            .sink { [weak self] m in self?.updateTitle(m.followerCount) }
        updateTitle(state.latest.followerCount)
    }

    private func updateTitle(_ count: Int) {
        statusItem.button?.title = " \(count)"
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let provider = NSMenuItem(title: "Source: \(state.providerLabel)", action: nil, keyEquivalent: "")
        provider.isEnabled = false
        menu.addItem(provider)
        menu.addItem(.separator())

        let hud = NSMenuItem(title: "Show / Hide Banner", action: #selector(toggleHUD), keyEquivalent: "h")
        hud.target = self
        menu.addItem(hud)

        let refresh = NSMenuItem(title: "Muster Now (refresh)", action: #selector(refresh), keyEquivalent: "r")
        refresh.target = self
        menu.addItem(refresh)
        menu.addItem(.separator())

        let mockHeader = NSMenuItem(title: "Drill Yard (mock)", action: nil, keyEquivalent: "")
        mockHeader.isEnabled = false
        menu.addItem(mockHeader)

        let gain = NSMenuItem(title: "+25 recruits", action: #selector(simGain), keyEquivalent: "")
        gain.target = self
        menu.addItem(gain)
        let loss = NSMenuItem(title: "-25 arrows inbound", action: #selector(simLoss), keyEquivalent: "")
        loss.target = self
        menu.addItem(loss)
        menu.addItem(.separator())

        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        let about = NSMenuItem(title: "About Follower Crusade", action: #selector(openAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Abandon Campaign (quit)", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    func refreshProviderLabel() {
        if let item = statusItem.menu?.items.first {
            item.title = "Source: \(state.providerLabel)"
        }
    }

    @objc private func toggleHUD() { onToggleHUD() }
    @objc private func openSettings() { onOpenSettings() }
    @objc private func openAbout() { onOpenAbout() }
    @objc private func quit() { NSApp.terminate(nil) }
    @objc private func refresh() { Task { await state.refreshNow() } }
    @objc private func simGain() { Task { await state.simulateGain() } }
    @objc private func simLoss() { Task { await state.simulateLoss() } }
}
#endif
