#if canImport(AppKit) && canImport(SwiftUI)
import AppKit
import SpriteKit
import SwiftUI
import FollowerCrusadeCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var state: AppState!
    private var scene: SKScene!
    private var hud: HUDWindowController!
    private var menuBar: MenuBarController!
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?
    private var ledgerWindow: NSWindow?
    private var isoDemoWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // PROTOTYPE: `--iso-demo` (or FC_ISO_DEMO=1) opens a dedicated large
        // window running the isometric IsoCampScene instead of the HUD — the
        // 360x240 HUD is too small to judge depth. `--iso-shot <path>` also
        // writes a PNG of the scene after it settles. The HUD/menubar are
        // skipped in demo mode so desktop captures stay clean.
        state = AppState()
        if isoDemoRequested {
            runIsoDemo()
            return
        }
        // `--iso` (or FC_ISO=1) swaps the HUD's flat scene for the iso
        // prototype so live metrics drive it inside the normal app chrome.
        let useIso = flag("--iso") || ProcessInfo.processInfo.environment["FC_ISO"] == "1"
        let camp: CampSceneDriving = useIso
            ? IsoCampScene(size: HUDWindowController.defaultSize)
            : CampScene(size: HUDWindowController.defaultSize)
        scene = camp
        state.scene = camp

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

    // MARK: - Isometric prototype demo

    private func flag(_ name: String) -> Bool {
        CommandLine.arguments.contains(name)
    }

    private var isoDemoRequested: Bool {
        flag("--iso-demo") || ProcessInfo.processInfo.environment["FC_ISO_DEMO"] == "1"
    }

    /// Standalone demo window for the iso prototype: large enough to judge
    /// depth, seeded deterministically, and (with --iso-shot) able to write
    /// a clean PNG capture of the rendered scene for review.
    private func runIsoDemo() {
        let size = NSSize(width: 780, height: 560)
        let isoScene = IsoCampScene(size: size)
        let skView = SKView(frame: NSRect(origin: .zero, size: size))
        skView.presentScene(isoScene)
        isoScene.populateDemo()

        let window = NSWindow(
            contentRect: skView.frame,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Follower Crusade — Isometric Camp Prototype"
        window.contentView = skView
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        isoDemoWindow = window
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if let path = shotPath() {
            let delay = shotDelay()
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak isoScene] in
                guard let isoScene else { return }
                self?.writeSnapshot(of: isoScene, to: path)
            }
        }
    }

    private func shotPath() -> String? {
        if let i = CommandLine.arguments.firstIndex(of: "--iso-shot"),
           CommandLine.arguments.indices.contains(i + 1) {
            return CommandLine.arguments[i + 1]
        }
        return ProcessInfo.processInfo.environment["FC_ISO_SHOT"]
    }

    /// Seconds to wait before capturing — long enough for the march-in
    /// recruits to reach their tiles and the patrol to be mid-field.
    private func shotDelay() -> Double {
        if let i = CommandLine.arguments.firstIndex(of: "--iso-shot-delay"),
           CommandLine.arguments.indices.contains(i + 1),
           let d = Double(CommandLine.arguments[i + 1]) { return d }
        if let d = ProcessInfo.processInfo.environment["FC_ISO_SHOT_DELAY"].flatMap(Double.init) { return d }
        return 8
    }

    private func writeSnapshot(of scene: SKScene, to path: String) {
        guard let view = scene.view, let tex = view.texture(from: scene) else {
            print("[iso-demo] snapshot failed: no view/texture")
            return
        }
        let rep = NSBitmapImageRep(cgImage: tex.cgImage())
        guard let png = rep.representation(using: .png, properties: [:]) else {
            print("[iso-demo] snapshot failed: PNG encode")
            return
        }
        do {
            try png.write(to: URL(fileURLWithPath: path))
            print("[iso-demo] wrote snapshot to \(path)")
        } catch {
            print("[iso-demo] snapshot failed: \(error.localizedDescription)")
        }
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
