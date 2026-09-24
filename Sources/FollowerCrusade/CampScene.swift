#if canImport(SpriteKit)
import SpriteKit
import FollowerCrusadeCore

/// The siege diorama: woods on the left, your warband camped center,
/// competitor outposts along the right edge, fog of war at the margins.
final class CampScene: SKScene {

    // Layout (logical points in the ~360x220 HUD)
    private let woodsX: CGFloat = 26
    private let campCenter = CGPoint(x: 150, y: 62)
    private let outpostX: CGFloat = 320

    private var soldiers: [SoldierNode] = []
    private var outposts: [UUID: OutpostNode] = [:]
    private var campfire: CampfireNode?
    private var morale: Morale = .steady
    private var built = false

    override func didMove(to view: SKView) {
        guard !built else { return }
        built = true
        buildWorld()
    }

    // MARK: - World construction

    private func buildWorld() {
        backgroundColor = SKColor(calibratedRed: 0.09, green: 0.13, blue: 0.16, alpha: 1)
        scaleMode = .resizeFill

        // Ground strip
        let ground = SKSpriteNode(color: SKColor(calibratedRed: 0.16, green: 0.22, blue: 0.18, alpha: 1),
                                  size: CGSize(width: size.width, height: 46))
        ground.anchorPoint = CGPoint(x: 0.5, y: 0)
        ground.position = CGPoint(x: size.width / 2, y: 24)
        addChild(ground)

        // Woods on the left
        for (i, x) in stride(from: 8, through: 44, by: 18).enumerated() {
            let grid = i % 2 == 0 ? Sprites.treeA : Sprites.treeB
            let tree = SKSpriteNode(texture: PixelArt.texture(rows: grid))
            tree.position = CGPoint(x: CGFloat(x), y: 92 + CGFloat(i % 2) * 14)
            addChild(tree)
        }

        // Fog of war at both edges
        addFogEdge(atX: -6, flip: false)
        addFogEdge(atX: size.width + 6, flip: true)

        // Campfire
        let fire = CampfireNode()
        fire.position = campCenter
        addChild(fire)
        campfire = fire
    }

    private func addFogEdge(atX x: CGFloat, flip: Bool) {
        let fog = SKSpriteNode(color: SKColor(white: 0.05, alpha: 0.55),
                               size: CGSize(width: 34, height: size.height))
        fog.anchorPoint = CGPoint(x: 0.5, y: 0)
        fog.position = CGPoint(x: x, y: 0)
        fog.zPosition = 8
        if flip { fog.xScale = -1 }
        addChild(fog)
    }

    // MARK: - Camp slots

    /// Loose formation slots ringing the campfire, nearest first.
    private func slot(for index: Int) -> CGPoint {
        let ring = index / 10
        let angle = CGFloat(index % 10) / 10.0 * .pi * 2 + CGFloat(ring) * 0.31
        let r = 30 + CGFloat(ring) * 18
        return CGPoint(x: campCenter.x + cos(angle) * r,
                       y: max(34, campCenter.y + sin(angle) * r * 0.45))
    }

    // MARK: - Public API (called by AppState)

    /// Reconcile rendered soldiers with the target composition.
    func applyComposition(_ comp: ArmyComposition) {
        let want: [(SoldierNode.Rank, Int)] = [(.knight, comp.knights), (.archer, comp.archers), (.foot, comp.footSoldiers)]
        var neededByRank: [SoldierNode.Rank: Int] = [:]
        for (rank, n) in want { neededByRank[rank] = n }
        // Count current per rank; simplest approach: rebuild if total differs.
        let current = soldiers.count
        if current == comp.total { return }
        if current < comp.total {
            // Recruits arrive via spawnRecruits (event-driven); this only
            // top-ups silently on first build / after deserter losses.
            let deficit = comp.total - current
            for _ in 0..<deficit { spawnRecruit(animated: soldiers.isEmpty == false) }
        } else {
            let excess = current - comp.total
            for _ in 0..<excess { soldiers.last?.removeFromParent(); _ = soldiers.popLast() }
        }
    }

    /// `n` recruits emerge from the woods and march into camp.
    func spawnRecruits(_ n: Int) {
        for i in 0..<n {
            run(.sequence([
                .wait(forDuration: TimeInterval(i) * 0.35),
                .run { [weak self] in self?.spawnRecruit(animated: true) },
            ]))
        }
    }

    private func spawnRecruit(animated: Bool) {
        let rank = pickRank()
        let soldier = SoldierNode(rank: rank)
        let target = slot(for: soldiers.count)
        soldiers.append(soldier)
        soldier.position = CGPoint(x: woodsX + 10, y: 44 + CGFloat.random(in: 0...20))
        addChild(soldier)
        if animated {
            soldier.march(to: target, speed: 34)
        } else {
            soldier.position = target
            soldier.startIdle()
        }
    }

    /// `n` soldiers are downed by arrows fired out of the fog.
    func loseSoldiers(_ n: Int) {
        let victims = soldiers.filter { $0.state == .idle }.shuffled().prefix(n)
        for (i, victim) in victims.enumerated() {
            run(.sequence([
                .wait(forDuration: TimeInterval(i) * 0.4),
                .run { [weak self] in self?.fireArrow(at: victim) },
            ]))
        }
    }

    private func fireArrow(at victim: SoldierNode) {
        guard let scene = victim.scene else { return }
        let arrow = SKSpriteNode(texture: PixelArt.texture(rows: Sprites.arrow, scale: 2))
        arrow.zPosition = 9
        arrow.position = CGPoint(x: scene.size.width + 10, y: victim.position.y + 30)
        scene.addChild(arrow)
        let target = CGPoint(x: victim.position.x, y: victim.position.y + 10)
        let dx = target.x - arrow.position.x
        let dy = target.y - arrow.position.y
        arrow.zRotation = atan2(dy, dx)
        arrow.run(.sequence([
            .move(to: target, duration: TimeInterval(sqrt(dx * dx + dy * dy) / 220)),
            .run { victim.die() },
            .removeFromParent(),
        ]))
        soldiers.removeAll { $0 === victim }
    }

    /// A soldier walks off (low morale desertion).
    func desertSoldier() {
        guard let victim = soldiers.filter({ $0.state == .idle }).randomElement() else { return }
        soldiers.removeAll { $0 === victim }
        victim.desert(from: self)
    }

    func setMorale(_ m: Morale) {
        morale = m
        campfire?.setMorale(m)
    }

    // MARK: - Outposts

    /// Reconcile outpost towers with the configured competitors.
    func syncOutposts(_ comps: [Competitor]) {
        let wanted = Set(comps.map(\.id))
        for (id, node) in outposts where !wanted.contains(id) {
            node.removeFromParent()
            outposts.removeValue(forKey: id)
        }
        for (i, comp) in comps.enumerated() {
            if let node = outposts[comp.id] {
                if comp.captured { node.capture() } else { node.uncapture() }
                continue
            }
            let node = OutpostNode(competitor: comp)
            // Stack up to 4 outposts along the right edge.
            let y = 60 + CGFloat(i % 4) * 52
            node.position = CGPoint(x: outpostX, y: y)
            addChild(node)
            outposts[comp.id] = node
        }
    }

    /// Army storms the outpost and raises the banner.
    func captureOutpost(id: UUID) {
        guard let node = outposts[id] else { return }
        // Send a squad to storm the tower.
        let squad = soldiers.filter { $0.state == .idle }.prefix(5)
        var pending = squad.count
        let finish: () -> Void = { node.capture() }
        if squad.isEmpty { node.capture(); return }
        for soldier in squad {
            let target = CGPoint(x: node.position.x - 20 + .random(in: -8...8),
                                 y: node.position.y - 26)
            soldier.storm(to: target) {
                pending -= 1
                if pending <= 0 { finish() }
            }
        }
    }

    func uncaptureOutpost(id: UUID) {
        outposts[id]?.uncapture()
    }

    // MARK: - Helpers

    private func pickRank() -> SoldierNode.Rank {
        let r = Double.random(in: 0...1)
        if soldiers.count > 24 && r < 0.12 { return .knight }
        if soldiers.count > 8 && r < 0.35 { return .archer }
        return .foot
    }
}
#endif
