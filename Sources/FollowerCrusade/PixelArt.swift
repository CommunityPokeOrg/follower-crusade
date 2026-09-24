#if canImport(SpriteKit)
import SpriteKit

/// Procedural pixel-art texture factory. Sprites are described as rows of
/// characters mapped through a palette; each character becomes `scale`
/// screen pixels. Everything is generated at runtime — no bundled assets.
enum PixelArt {

    // MARK: - Palette

    static let palette: [Character: SKColor] = [
        "O": SKColor(calibratedRed: 0.10, green: 0.10, blue: 0.10, alpha: 1), // outline
        "H": SKColor(calibratedRed: 0.60, green: 0.63, blue: 0.66, alpha: 1), // helmet steel
        "h": SKColor(calibratedRed: 0.42, green: 0.45, blue: 0.48, alpha: 1), // dark steel
        "F": SKColor(calibratedRed: 0.91, green: 0.73, blue: 0.54, alpha: 1), // skin
        "T": SKColor(calibratedRed: 0.17, green: 0.23, blue: 0.40, alpha: 1), // tunic navy
        "B": SKColor(calibratedRed: 0.29, green: 0.21, blue: 0.13, alpha: 1), // boots/leather
        "L": SKColor(calibratedRed: 0.35, green: 0.27, blue: 0.20, alpha: 1), // legs
        "W": SKColor.white,
        "K": SKColor.black,
        "S": SKColor(calibratedRed: 0.55, green: 0.43, blue: 0.30, alpha: 1), // spear/wood
        "G": SKColor(calibratedRed: 0.88, green: 0.70, blue: 0.25, alpha: 1), // gold/knight trim
        "X": SKColor(calibratedRed: 0.78, green: 0.80, blue: 0.83, alpha: 1), // blade
        "M": SKColor(calibratedRed: 0.84, green: 0.16, blue: 0.46, alpha: 1), // IG magenta
        "V": SKColor(calibratedRed: 0.51, green: 0.20, blue: 0.69, alpha: 1), // IG purple
        "R": SKColor(calibratedRed: 0.72, green: 0.20, blue: 0.18, alpha: 1), // rival flag
        "g": SKColor(calibratedRed: 0.26, green: 0.42, blue: 0.24, alpha: 1), // tree green
        "d": SKColor(calibratedRed: 0.18, green: 0.30, blue: 0.17, alpha: 1), // dark green
        "t": SKColor(calibratedRed: 0.35, green: 0.24, blue: 0.15, alpha: 1), // trunk
        "Y": SKColor(calibratedRed: 1.00, green: 0.80, blue: 0.25, alpha: 1), // fire yellow
        "r": SKColor(calibratedRed: 0.91, green: 0.45, blue: 0.14, alpha: 1), // fire orange
        "e": SKColor(calibratedRed: 0.70, green: 0.22, blue: 0.10, alpha: 1), // ember
        "s": SKColor(calibratedRed: 0.55, green: 0.55, blue: 0.58, alpha: 1), // stone
        "o": SKColor(calibratedRed: 0.38, green: 0.38, blue: 0.41, alpha: 1), // dark stone
        "w": SKColor(calibratedRed: 0.93, green: 0.87, blue: 0.72, alpha: 1), // skull bone
        "a": SKColor(calibratedRed: 0.75, green: 0.60, blue: 0.40, alpha: 1), // arrow shaft
        "f": SKColor(calibratedRed: 0.85, green: 0.85, blue: 0.88, alpha: 1), // fletching
    ]

    /// Renders a character grid into a nearest-neighbor texture.
    static func texture(rows: [String], scale: CGFloat = 3, extra: [Character: SKColor] = [:]) -> SKTexture {
        let pal = palette.merging(extra) { _, new in new }
        let width = rows.map(\.count).max() ?? 1
        let height = rows.count
        let w = max(1, Int(CGFloat(width) * scale))
        let h = max(1, Int(CGFloat(height) * scale))
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
        )!
        let ctx = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        for (y, row) in rows.enumerated() {
            for (x, ch) in row.enumerated() {
                guard ch != ".", let color = pal[ch] else { continue }
                color.setFill()
                // NSBitmapImageRep y=0 is top-left of the first row we draw;
                // we keep row order top-to-bottom and flip the texture view.
                NSRect(x: Int(CGFloat(x) * scale), y: Int(CGFloat(y) * scale),
                       width: Int(scale), height: Int(scale)).fill()
            }
        }
        NSGraphicsContext.restoreGraphicsState()
        guard let cg = rep.cgImage else { return SKTexture() }
        let tex = SKTexture(cgImage: cg)
        tex.filteringMode = .nearest
        return tex
    }

    static func circleTexture(diameter: CGFloat, color: SKColor) -> SKTexture {
        let size = Int(diameter)
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
        )!
        let ctx = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        color.setFill()
        NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: size, height: size)).fill()
        NSGraphicsContext.restoreGraphicsState()
        guard let cg = rep.cgImage else { return SKTexture() }
        return SKTexture(cgImage: cg)
    }
}
#endif
