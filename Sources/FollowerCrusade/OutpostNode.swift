#if canImport(SpriteKit)
import SpriteKit
import FollowerCrusadeCore

/// A competitor's outpost tower on the campaign map. Captured towers fly
/// the user's banner (Instagram pennant).
final class OutpostNode: SKNode {

    let competitorID: UUID
    private let tower: SKSpriteNode
    private let flag: SKSpriteNode
    private let label: SKLabelNode
    private(set) var captured = false

    init(competitor: Competitor) {
        competitorID = competitor.id
        tower = SKSpriteNode(texture: PixelArt.texture(rows: Sprites.tower))
        flag = SKSpriteNode(texture: PixelArt.texture(rows: Sprites.flagNeutral))
        label = SKLabelNode(text: competitor.name)
        label.fontName = "Menlo-Bold"
        label.fontSize = 7
        label.fontColor = SKColor(white: 0.85, alpha: 1)

        super.init()
        addChild(tower)
        flag.position = CGPoint(x: tower.size.width / 2 + 2, y: tower.size.height / 2 - 4)
        flag.anchorPoint = CGPoint(x: 0, y: 0.5)
        addChild(flag)
        label.position = CGPoint(x: 0, y: tower.size.height / 2 + 8)
        addChild(label)

        if competitor.captured { applyCapturedFlag(animated: false) }
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    /// Overrun the outpost: shake, flash, raise the captured banner.
    func capture() {
        guard !captured else { return }
        captured = true
        let shake = SKAction.sequence([
            .moveBy(x: -3, y: 0, duration: 0.06),
            .moveBy(x: 6, y: 0, duration: 0.08),
            .moveBy(x: -6, y: 0, duration: 0.08),
            .moveBy(x: 3, y: 0, duration: 0.06),
        ])
        tower.run(.repeat(shake, count: 3))
        flag.run(.sequence([
            .wait(forDuration: 0.6),
            .run { [weak self] in self?.applyCapturedFlag(animated: true) },
        ]))
        // Dust puff at the base.
        let puff = SKSpriteNode(texture: PixelArt.circleTexture(diameter: 20, color: SKColor(white: 0.7, alpha: 0.5)))
        puff.position = CGPoint(x: 0, y: -tower.size.height / 2 + 4)
        puff.blendMode = .alpha
        addChild(puff)
        puff.run(.sequence([
            .group([.scale(to: 1.8, duration: 0.5), .fadeOut(withDuration: 0.5)]),
            .removeFromParent(),
        ]))
    }

    /// Count fell back below the threshold — the banner comes down.
    func uncapture() {
        captured = false
        flag.texture = PixelArt.texture(rows: Sprites.flagNeutral)
        flag.xScale = abs(flag.xScale)
    }

    private func applyCapturedFlag(animated: Bool) {
        let tex = PixelArt.texture(rows: Sprites.flagCaptured)
        if animated {
            flag.run(.sequence([
                .scaleY(to: 0.1, duration: 0.15),
                .setTexture(tex),
                .scaleY(to: 1.0, duration: 0.2),
                .group([.repeatForever(.sequence([
                    .rotate(toAngle: 0.06, duration: 0.5),
                    .rotate(toAngle: -0.06, duration: 0.5),
                ]))]),
            ]))
        } else {
            flag.texture = tex
        }
    }
}
#endif
