#if canImport(SpriteKit)
import SpriteKit
import FollowerCrusadeCore

/// A pixel soldier in the warband. Carries a small Instagram crest shield
/// (magenta/purple gradient) marking its platform provenance.
final class SoldierNode: SKSpriteNode {

    enum Rank { case foot, archer, knight }
    enum State { case mustering, idle, marching, dying, deserting, storming }

    private(set) var rank: Rank
    private(set) var state: State = .idle
    private let originPlatform: OriginPlatform

    private var idleFrames: [SKTexture] = []
    private var marchFrames: [SKTexture] = []
    private var hitTexture: SKTexture?

    init(rank: Rank, platform: OriginPlatform = .instagram) {
        self.rank = rank
        self.originPlatform = platform
        let atlas = SoldierNode.makeFrames(rank: rank)
        idleFrames = atlas.idle
        marchFrames = atlas.march
        hitTexture = atlas.hit
        super.init(texture: idleFrames.first, color: .clear, size: idleFrames.first!.size())
        texture?.filteringMode = .nearest
        addProvenanceCrest()
        startIdle()
    }

    required init?(coder: NSCoder) { fatalError("not implemented") }

    // MARK: - Textures

    private static func makeFrames(rank: Rank) -> (idle: [SKTexture], march: [SKTexture], hit: SKTexture) {
        switch rank {
        case .foot:
            return ([Sprites.footIdleA, Sprites.footIdleB].map { PixelArt.texture(rows: $0, scale: 2) },
                    [Sprites.footMarchA, Sprites.footMarchB].map { PixelArt.texture(rows: $0, scale: 2) },
                    PixelArt.texture(rows: Sprites.footHit, scale: 2))
        case .archer:
            return ([Sprites.archerIdle].map { PixelArt.texture(rows: $0, scale: 2) },
                    [Sprites.archerMarch, Sprites.archerIdle].map { PixelArt.texture(rows: $0, scale: 2) },
                    PixelArt.texture(rows: Sprites.archerHit, scale: 2))
        case .knight:
            return ([Sprites.knightIdle].map { PixelArt.texture(rows: $0, scale: 2) },
                    [Sprites.knightMarch, Sprites.knightIdle].map { PixelArt.texture(rows: $0, scale: 2) },
                    PixelArt.texture(rows: Sprites.knightHit, scale: 2))
        }
    }

    /// Tiny heraldic shield marking the soldier's source platform.
    /// Instagram provenance: magenta/purple gradient trim.
    private func addProvenanceCrest() {
        let tex = PixelArt.texture(rows: Sprites.igCrest, scale: 1)
        let crest = SKSpriteNode(texture: tex)
        crest.anchorPoint = CGPoint(x: 1.0, y: 0.5)
        crest.position = CGPoint(x: -size.width / 2 - 1, y: 0)
        crest.zPosition = 2
        addChild(crest)
    }

    // MARK: - Behavior

    func startIdle() {
        guard state != .dying else { return }
        state = .idle
        removeAction(forKey: "anim")
        run(.repeatForever(.animate(with: idleFrames, timePerFrame: 0.6)), withKey: "anim")
    }

    /// March to a target x-position, then settle into idle.
    func march(to target: CGPoint, speed: CGFloat = 30, completion: (() -> Void)? = nil) {
        guard state != .dying else { return }
        state = .marching
        removeAction(forKey: "anim")
        run(.repeatForever(.animate(with: marchFrames, timePerFrame: 0.18)), withKey: "anim")
        let dx = target.x - position.x
        xScale = dx < 0 ? -abs(xScale) : abs(xScale)
        let duration = TimeInterval(abs(dx) / speed)
        run(.move(to: target, duration: max(0.1, duration))) { [weak self] in
            self?.startIdle()
            completion?()
        }
    }

    /// Arrow kill: visible flinch (hit frame + white flash + recoil), then
    /// ragdoll collapse, brief skull, then fade out.
    func die() {
        guard state != .dying else { return }
        state = .dying
        removeAllActions()
        let fallen = PixelArt.texture(rows: Sprites.fallen, scale: 2)
        let skull = PixelArt.texture(rows: Sprites.skull, scale: 2)
        // The flinch beat: recoil backwards with a white hit-flash so the
        // arrow impact reads before the body drops.
        let flinch = SKAction.sequence([
            .setTexture(hitTexture ?? idleFrames[0]),
            .group([
                .moveBy(x: -5, y: 2, duration: 0.14),
                .sequence([
                    .colorize(with: .white, colorBlendFactor: 0.85, duration: 0.05),
                    .wait(forDuration: 0.12),
                    .colorize(withColorBlendFactor: 0, duration: 0.12),
                ]),
            ]),
        ])
        let tipOver = SKAction.sequence([
            .rotate(toAngle: -.pi / 2, duration: 0.18),
            .rotate(toAngle: -.pi / 2 + 0.25, duration: 0.12),
            .rotate(toAngle: -.pi / 2, duration: 0.1),
        ])
        let slump = SKAction.moveBy(x: 4, y: -4, duration: 0.3)
        let impact = SKAction.group([tipOver, slump])
        run(.sequence([
            flinch,
            impact,
            .setTexture(fallen),
            .wait(forDuration: 0.7),
            .run { [weak self] in self?.showSkull(skull) },
            .wait(forDuration: 0.9),
            .fadeOut(withDuration: 0.4),
            .removeFromParent(),
        ]))
    }

    /// Walk off-screen (desertion when morale is low).
    func desert(from scene: SKScene) {
        guard state == .idle || state == .marching else { return }
        state = .deserting
        removeAllActions()
        run(.repeatForever(.animate(with: marchFrames, timePerFrame: 0.16)), withKey: "anim")
        let exit = CGPoint(x: scene.size.width + 40, y: position.y)
        let duration = TimeInterval(abs(exit.x - position.x) / 40)
        run(.move(to: exit, duration: duration)) { [weak self] in
            self?.removeFromParent()
        }
    }

    /// Charge toward an outpost during a capture (fast march right).
    func storm(to target: CGPoint, completion: (() -> Void)? = nil) {
        guard state != .dying else { return }
        state = .storming
        removeAction(forKey: "anim")
        run(.repeatForever(.animate(with: marchFrames, timePerFrame: 0.12)), withKey: "anim")
        xScale = abs(xScale)
        let duration = TimeInterval(abs(target.x - position.x) / 55)
        run(.move(to: target, duration: max(0.1, duration))) { [weak self] in
            self?.startIdle()
            completion?()
        }
    }

    private func showSkull(_ tex: SKTexture) {
        let node = SKSpriteNode(texture: tex)
        node.position = CGPoint(x: 0, y: size.height / 2 + 6)
        node.zPosition = 3
        addChild(node)
        node.run(.sequence([
            .moveBy(x: 0, y: 8, duration: 0.35),
            .moveBy(x: 0, y: -4, duration: 0.3),
            .fadeOut(withDuration: 0.4),
            .removeFromParent(),
        ]))
    }
}
#endif
