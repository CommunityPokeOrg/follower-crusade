#if canImport(SwiftUI)
import SwiftUI

/// The framed medieval border for the HUD: iron outer band with rivets,
/// a parchment inner edge, and stone-tone corner blocks. Pure SwiftUI —
/// scales with the window.
struct MedievalFrame: View {

    var cornerRadius: CGFloat = 10

    private let iron = LinearGradient(
        colors: [Color(white: 0.28), Color(white: 0.18), Color(white: 0.32), Color(white: 0.20)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
    private let parchment = LinearGradient(
        colors: [Color(red: 0.87, green: 0.78, blue: 0.58), Color(red: 0.76, green: 0.65, blue: 0.44)],
        startPoint: .top, endPoint: .bottom)
    private let stone = Color(red: 0.45, green: 0.44, blue: 0.42)

    var body: some View {
        ZStack {
            // Iron band
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(iron, lineWidth: 10)
            // Parchment inner edge
            RoundedRectangle(cornerRadius: cornerRadius - 5)
                .stroke(parchment, lineWidth: 4)
                .padding(6)
            // Hairline
            RoundedRectangle(cornerRadius: cornerRadius - 8)
                .stroke(Color.black.opacity(0.5), lineWidth: 1)
                .padding(10)
            rivets
            cornerBlocks
        }
        .allowsHitTesting(false)
    }

    /// Rivets along the iron band.
    private var rivets: some View {
        Canvas { ctx, size in
            let step: CGFloat = 34
            let r: CGFloat = 2.2
            let top = Path { p in
                var x: CGFloat = 20
                while x < size.width - 20 {
                    p.addEllipse(in: CGRect(x: x - r, y: 5 - r, width: r * 2, height: r * 2))
                    p.addEllipse(in: CGRect(x: x - r, y: size.height - 5 - r, width: r * 2, height: r * 2))
                    x += step
                }
                var y: CGFloat = 30
                while y < size.height - 30 {
                    p.addEllipse(in: CGRect(x: 5 - r, y: y - r, width: r * 2, height: r * 2))
                    p.addEllipse(in: CGRect(x: size.width - 5 - r, y: y - r, width: r * 2, height: r * 2))
                    y += step
                }
            }
            ctx.fill(top, with: .color(Color(white: 0.62)))
            ctx.fill(top, with: .linearGradient(
                Gradient(colors: [Color(white: 0.7), Color(white: 0.35)]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: size.width, y: size.height)))
        }
    }

    /// Stone blocks at the four corners.
    private var cornerBlocks: some View {
        Canvas { ctx, size in
            let s: CGFloat = 12
            let corners = [
                CGRect(x: 0, y: 0, width: s, height: s),
                CGRect(x: size.width - s, y: 0, width: s, height: s),
                CGRect(x: 0, y: size.height - s, width: s, height: s),
                CGRect(x: size.width - s, y: size.height - s, width: s, height: s),
            ]
            for rect in corners {
                ctx.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(stone))
                ctx.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(Color.black.opacity(0.5)), lineWidth: 1)
            }
        }
    }
}
#endif
