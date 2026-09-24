#if canImport(SpriteKit)
import SpriteKit
import FollowerCrusadeCore

/// Campfire whose flame size and smoke track morale (supplies/engagement).
final class CampfireNode: SKNode {

    private let flames: SKSpriteNode
    private let logs: SKSpriteNode
    private let smoke: SKEmitterNode
    private let glow: SKSpriteNode
    private(set) var morale: Morale = .steady

    /// Distance from the node origin down to the bottom of the stone
    /// fire-pit — the line where the campfire contacts the ground.
    var groundContactOffset: CGFloat { logs.size.height / 2 }

    override init() {
        let logTex = PixelArt.texture(rows: Sprites.logs)
        logs = SKSpriteNode(texture: logTex)
        let fireTex = PixelArt.texture(rows: Sprites.fireA)
        flames = SKSpriteNode(texture: fireTex)
        flames.position.y = logTex.size().height / 2

        glow = SKSpriteNode(texture: PixelArt.circleTexture(diameter: 44, color: SKColor(calibratedRed: 1, green: 0.6, blue: 0.2, alpha: 1)))
        glow.alpha = 0.25
        glow.blendMode = .add
        glow.position.y = 6

        smoke = SKEmitterNode()
        smoke.particleTexture = PixelArt.circleTexture(diameter: 6, color: SKColor(white: 0.5, alpha: 0.6))
        smoke.particleBirthRate = 3
        smoke.particleLifetime = 2.5
        smoke.particleSpeed = 8
        smoke.particleSpeedRange = 6
        smoke.emissionAngle = .pi / 2
        smoke.emissionAngleRange = 0.4
        smoke.particleAlphaSpeed = -0.22
        smoke.particleScaleSpeed = 0.25
        smoke.particlePositionRange = CGVector(dx: 6, dy: 2)
        smoke.position.y = 14
        smoke.zPosition = 5

        super.init()
        addChild(glow)
        addChild(logs)
        addChild(flames)
        addChild(smoke)
        runFlames()
        setMorale(.steady)
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    private func runFlames() {
        let frames = [Sprites.fireA, Sprites.fireB, Sprites.fireC].map { PixelArt.texture(rows: $0) }
        flames.run(.repeatForever(.animate(with: frames, timePerFrame: 0.18)))
    }

    /// Morale drives flame size, glow and smoke. Mutinous = smoldering smoky wreck.
    func setMorale(_ m: Morale) {
        morale = m
        let (flameScale, smokeRate, glowA): (CGFloat, CGFloat, CGFloat)
        switch m {
        case .mutinous: (flameScale, smokeRate, glowA) = (0.35, 9, 0.08)
        case .low: (flameScale, smokeRate, glowA) = (0.6, 6, 0.15)
        case .steady: (flameScale, smokeRate, glowA) = (1.0, 3, 0.25)
        case .high: (flameScale, smokeRate, glowA) = (1.25, 1.5, 0.32)
        case .exultant: (flameScale, smokeRate, glowA) = (1.5, 0.8, 0.4)
        }
        flames.run(.scale(to: flameScale, duration: 0.5))
        glow.run(.fadeAlpha(to: glowA, duration: 0.5))
        smoke.particleBirthRate = smokeRate
    }
}
#endif
