#if canImport(SwiftUI) && canImport(SpriteKit)
import AppKit
import SwiftUI
import SpriteKit
import FollowerCrusadeCore

/// SwiftUI content hosted inside the floating HUD panel: header strip with
/// the headcount and morale, the SpriteKit siege scene, and the medieval frame.
struct HUDView: View {
    @ObservedObject var state: AppState
    let scene: CampScene
    @State private var isPaused = false

    var body: some View {
        ZStack {
            // Drag handle across the whole background (borderless panels
            // can't drag via SwiftUI content otherwise).
            WindowDragHandle()

            // Parchment-dark backing
            LinearGradient(colors: [Color(red: 0.10, green: 0.11, blue: 0.13),
                                    Color(red: 0.14, green: 0.13, blue: 0.11)],
                           startPoint: .top, endPoint: .bottom)

            VStack(spacing: 0) {
                header
                SpriteView(scene: scene)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                    .padding(.top, 2)
            }
            .padding(.top, 12)

            MedievalFrame()
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var header: some View {
        HStack(spacing: 6) {
            InstagramBadge()
                .frame(width: 14, height: 14)
            Text("\(state.latest.followerCount)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text("soldiers")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            moraleBadge
            Button(action: { isPaused.toggle(); state.paused = isPaused; scene.isPaused = isPaused }) {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.top, 2)
    }

    private var moraleBadge: some View {
        Text(state.morale.displayName)
            .font(.system(size: 8, weight: .semibold, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(moraleColor.opacity(0.25), in: Capsule())
            .overlay(Capsule().stroke(moraleColor.opacity(0.7), lineWidth: 0.5))
            .foregroundStyle(moraleColor)
    }

    private var moraleColor: Color {
        switch state.morale {
        case .mutinous: return .red
        case .low: return .orange
        case .steady: return .yellow
        case .high: return .green
        case .exultant: return .cyan
        }
    }
}

/// Small Instagram-provenance crest used in the header.
struct InstagramBadge: View {
    var body: some View {
        Canvas { ctx, size in
            let rect = CGRect(origin: .zero, size: size)
            ctx.fill(Path(roundedRect: rect, cornerRadius: size.width * 0.28),
                     with: .linearGradient(
                        Gradient(colors: [Color(red: 0.98, green: 0.26, blue: 0.47),
                                          Color(red: 0.84, green: 0.16, blue: 0.46),
                                          Color(red: 0.51, green: 0.20, blue: 0.69)]),
                        startPoint: CGPoint(x: 0, y: size.height),
                        endPoint: CGPoint(x: size.width, y: 0)))
            let inset = rect.insetBy(dx: size.width * 0.22, dy: size.width * 0.22)
            ctx.stroke(Path(roundedRect: inset, cornerRadius: size.width * 0.14),
                       with: .color(.white), lineWidth: 1)
            ctx.fill(Path(ellipseIn: CGRect(x: size.width * 0.42, y: size.height * 0.42,
                                            width: size.width * 0.16, height: size.width * 0.16)),
                     with: .color(.white))
            ctx.fill(Path(ellipseIn: CGRect(x: size.width * 0.68, y: size.height * 0.16,
                                            width: size.width * 0.14, height: size.width * 0.14)),
                     with: .color(.white))
        }
    }
}

/// Invisible NSView that turns the whole HUD background into a drag region
/// for the borderless panel (SwiftUI has no window-drag primitive).
struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> DragView { DragView() }
    func updateNSView(_ nsView: DragView, context: Context) {}

    final class DragView: NSView {
        override var acceptsFirstResponder: Bool { false }
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}
#endif
