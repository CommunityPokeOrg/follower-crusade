#if canImport(AppKit) && canImport(SwiftUI)
import AppKit
import SpriteKit
import SwiftUI
import FollowerCrusadeCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var state: AppState!
    private var scene: CampScene!
    private var hud: HUDWindowController!
    private var menuBar: MenuBarController!
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?
    private var ledgerWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        state = AppState()
        scene = CampScene(size: HUDWindowController.defaultSize)
        state.scene = scene

        hud = HUDWindowController(state: state, scene: scene)
        hud.show()

        menuBar = MenuBarController(state: state)
        menuBar.onToggleHUD = { [weak self] in
            guard let self else { return }
            self.hud.toggle()
            // For a menu-bar HUD widget, "away" means the HUD was hidden or
            // the app was inactive — recap on re-show either way.
            if self.hud.isVisible {
                self.state.showRecapIfNeeded()
            } else {
                self.state.appResignedActive()
            }
        }
        menuBar.onOpenSettings = { [weak self] in self?.openSettings() }
        menuBar.onOpenAbout = { [weak self] in self?.openAbout() }
        menuBar.onOpenLedger = { [weak self] in self?.openLedger() }
        state.onOpenLedger = { [weak self] in self?.openLedger() }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.state.showRecapIfNeeded() }
        }
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.state.appResignedActive() }
        }

        state.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        state.appResignedActive()
        state.stop()
    }

    // MARK: - Windows

    private func openSettings() {
        if let w = settingsWindow {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 560),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        w.title = "Follower Crusade — Settings"
        w.contentView = NSHostingView(rootView: SettingsView(state: state))
        w.center()
        w.isReleasedWhenClosed = false
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = w
    }

    private func openAbout() {
        if let w = aboutWindow {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 340),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        w.title = "About Follower Crusade"
        w.contentView = NSHostingView(rootView: AboutView())
        w.center()
        w.isReleasedWhenClosed = false
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        aboutWindow = w
    }

    private func openLedger() {
        if let w = ledgerWindow {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 440),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        w.title = "War Ledger"
        w.contentView = NSHostingView(rootView: WarLedgerView(state: state))
        w.center()
        w.isReleasedWhenClosed = false
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        ledgerWindow = w
    }
}
#endif
