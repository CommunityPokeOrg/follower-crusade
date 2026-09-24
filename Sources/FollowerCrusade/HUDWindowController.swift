#if canImport(AppKit) && canImport(SwiftUI)
import AppKit
import SwiftUI
import FollowerCrusadeCore

/// The floating medieval HUD: a borderless, always-on-top, non-activating
/// panel that can float freely or dock into a screen corner.
final class HUDWindowController: NSObject, NSWindowDelegate {

    static let defaultSize = NSSize(width: 360, height: 240)
    private let margin: CGFloat = 12
    private let snapDistance: CGFloat = 48

    private(set) var panel: NSPanel
    private let store = SettingsStore.shared

    init(state: AppState, scene: CampScene) {
        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.defaultSize),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init()

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.minSize = NSSize(width: 280, height: 200)
        panel.delegate = self
        panel.titleVisibility = .hidden

        let host = NSHostingView(rootView: HUDView(state: state, scene: scene))
        panel.contentView = host

        restorePosition()
    }

    func show() {
        panel.orderFrontRegardless()
    }

    func toggle() {
        panel.isVisible ? panel.orderOut(nil) : show()
    }

    var isVisible: Bool { panel.isVisible }

    // MARK: - Positioning

    private func restorePosition() {
        let dock = store.settings.dockCorner
        if dock == .free, let f = parseFrame(store.settings.floatingFrame) {
            panel.setFrame(f, display: false)
            clampToVisibleScreen()
        } else if dock != .free {
            self.dock(dock)
        } else {
            panel.setFrameOrigin(NSPoint(x: 80, y: 80))
        }
    }

    /// Dock to a screen corner (or float freely) and persist the choice.
    func dock(_ corner: DockCorner) {
        var s = store.settings
        s.dockCorner = corner
        store.settings = s
        guard let screen = NSScreen.main?.visibleFrame else { return }
        let f = panel.frame
        let origin: NSPoint
        switch corner {
        case .topLeft: origin = NSPoint(x: screen.minX + margin, y: screen.maxY - f.height - margin)
        case .topRight: origin = NSPoint(x: screen.maxX - f.width - margin, y: screen.maxY - f.height - margin)
        case .bottomLeft: origin = NSPoint(x: screen.minX + margin, y: screen.minY + margin)
        case .bottomRight: origin = NSPoint(x: screen.maxX - f.width - margin, y: screen.minY + margin)
        case .free: return
        }
        panel.setFrameOrigin(origin)
    }

    /// Snap to a corner when dragged near it; otherwise remember the free spot.
    func windowDidMove(_ notification: Notification) {
        guard let screen = panel.screen?.visibleFrame ?? NSScreen.main?.visibleFrame else { return }
        let f = panel.frame
        let nearL = abs(f.minX - screen.minX) < snapDistance
        let nearR = abs(f.maxX - screen.maxX) < snapDistance
        let nearT = abs(f.maxY - screen.maxY) < snapDistance
        let nearB = abs(f.minY - screen.minY) < snapDistance

        var s = store.settings
        if nearT && nearL { s.dockCorner = .topLeft; dock(.topLeft) }
        else if nearT && nearR { s.dockCorner = .topRight; dock(.topRight) }
        else if nearB && nearL { s.dockCorner = .bottomLeft; dock(.bottomLeft) }
        else if nearB && nearR { s.dockCorner = .bottomRight; dock(.bottomRight) }
        else {
            s.dockCorner = .free
            s.floatingFrame = NSStringFromRect(f)
            store.settings = s
        }
    }

    func windowDidResize(_ notification: Notification) {
        if store.settings.dockCorner != .free {
            dock(store.settings.dockCorner)
        } else {
            var s = store.settings
            s.floatingFrame = NSStringFromRect(panel.frame)
            store.settings = s
        }
    }

    private func clampToVisibleScreen() {
        guard let screen = NSScreen.main?.visibleFrame else { return }
        var f = panel.frame
        if f.minX < screen.minX { f.origin.x = screen.minX }
        if f.minY < screen.minY { f.origin.y = screen.minY }
        if f.maxX > screen.maxX { f.origin.x = screen.maxX - f.width }
        if f.maxY > screen.maxY { f.origin.y = screen.maxY - f.height }
        panel.setFrame(f, display: false)
    }

    private func parseFrame(_ s: String) -> NSRect? {
        guard !s.isEmpty else { return nil }
        let r = NSRectFromString(s)
        return r.width > 100 && r.height > 100 ? r : nil
    }
}
#endif
