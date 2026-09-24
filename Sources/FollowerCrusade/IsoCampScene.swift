#if canImport(SpriteKit)
import SpriteKit
import FollowerCrusadeCore

/// The public contract AppState drives on the siege diorama. Both CampScene
/// (flat) and IsoCampScene (isometric prototype) conform, so the HUD can be
/// pointed at either without changing metric/event plumbing.
protocol CampSceneDriving: SKScene {
    func applyComposition(_ comp: ArmyComposition)
    func spawnRecruits(_ n: Int)
    func loseSoldiers(_ n: Int)
    func desertSoldier()
    func setMorale(_ m: Morale)
    func syncOutposts(_ comps: [Competitor])
    func captureOutpost(id: UUID)
    func uncaptureOutpost(id: UUID)
}

extension CampScene: CampSceneDriving {}

/// PROTOTYPE — isometric re-imagining of CampScene for Will's look-and-feel
/// review. Same sprites, same public API, but the warband stands on a
/// diamond (2:1) tile field instead of a flat strip:
///
///   - projection: screen = origin + ((i - j) * tileW/2, -(i + j) * tileH/2)
///   - depth sort: zPosition = 2000 - contactY, so the lower a sprite's
///     ground-contact point sits on screen, the further in front it renders.
///     Soldiers re-sort every frame (update); structures sort once at
///     placement since they never move.
///
/// Deliberately skipped (prototype scope): fog-of-war edge strips, per-tile
/// pathing, formation facing. The flat CampScene is untouched and remains
/// the default; `--iso` swaps it into the HUD, `--iso-demo` opens a large
/// dedicated demo window.
final class IsoCampScene: SKScene, CampSceneDriving {

    // MARK: - Grid geometry

    private struct Tile: Hashable { let i: Int; let j: Int }

    private let cols = 13
    private let rows = 9
    /// 2:1 diamond tiles, sized down if the scene is small (e.g. the HUD).
    private var tileW: CGFloat = 56
    private var tileH: CGFloat = 28
    /// Screen position of the far tile (0,0) center — the top diamond vertex.
    private var origin = CGPoint.zero

    private let fireTile = Tile(i: 6, j: 4)
    private let outpostTiles = [Tile(i: 11, j: 1), Tile(i: 9, j: 2)]
    /// i < 2 is the woods strip; outpost tiles and the fire tile are reserved.
    private func isReserved(_ t: Tile) -> Bool {
        t.i < 2 || t == fireTile || outpostTiles.contains(t)
    }

    private func screen(_ t: Tile) -> CGPoint {
        CGPoint(x: origin.x + CGFloat(t.i - t.j) * tileW / 2,
                y: origin.y - CGFloat(t.i + t.j) * tileH / 2)
    }

    /// Depth key: lower on screen (closer to viewer) renders in front.
    private func zDepth(_ contactY: CGFloat) -> CGFloat { 2000 - contactY }

    // MARK: - State

    private var soldiers: [SoldierNode] = []
    private var outposts: [UUID: OutpostNode] = [:]
    private var campfire: CampfireNode?
    private var morale: Morale = .steady
    private var built = false
    private var demoPending = false
    private var usedTiles = Set<Tile>()

    /// Existing nodes are center-anchored, so a soldier's feet sit ~16pt
    /// below its position and a tower's base ~27pt below its node position.
    private let soldierContactOffset: CGFloat = 16
    private let towerContactOffset: CGFloat = 27

    // MARK: - Scene setup

    override func didMove(to view: SKView) {
        guard !built else { return }
        built = true
        tileW = min(56, size.width * 1.9 / CGFloat(cols + rows - 2))
        tileH = tileW / 2
        let midX = CGFloat((cols - 1) - (rows - 1)) * tileW / 4
        origin = CGPoint(x: size.width / 2 - midX,
                         y: size.height - max(70, size.height * 0.16))
        buildWorld()
        if demoPending { populateDemo() }
    }

    private func buildWorld() {
        backgroundColor = SKColor(calibratedRed: 0.09, green: 0.13, blue: 0.16, alpha: 1)
        scaleMode = .resizeFill

        // Raised-plateau skirt: a darker copy of the board outline shifted
        // down, so the field reads as an elevated landmass.
        let skirt = SKShapeNode(path: boardOutline(offsetY: -9))
        skirt.fillColor = SKColor(calibratedRed: 0.16, green: 0.11, blue: 0.07, alpha: 1)
        skirt.strokeColor = .clear
        skirt.zPosition = -11
        addChild(skirt)

        // Diamond tile field: alternating grass checker, a worn dirt trail
        // along i - j = 2 (crosses under the fire toward the outpost flank).
        for i in 0..<cols {
            for j in 0..<rows {
                let t = Tile(i: i, j: j)
                let tile = SKShapeNode(path: diamondPath())
                tile.position = screen(t)
                tile.zPosition = -10
                tile.isAntialiased = false
                if t.i - t.j == 2 || abs(t.i - fireTile.i) + abs(t.j - fireTile.j) <= 1 {
                    tile.fillColor = SKColor(calibratedRed: 0.38, green: 0.28, blue: 0.17, alpha: 1)
                } else if (i + j) % 2 == 0 {
                    tile.fillColor = SKColor(calibratedRed: 0.25, green: 0.40, blue: 0.22, alpha: 1)
                } else {
                    tile.fillColor = SKColor(calibratedRed: 0.21, green: 0.34, blue: 0.19, alpha: 1)
                }
                tile.strokeColor = SKColor(calibratedRed: 0.11, green: 0.20, blue: 0.11, alpha: 0.5)
                tile.lineWidth = 0.5
                addChild(tile)
            }
        }

        // Woods along the far-left flank (i = 0 column + scattered i = 1).
        var treeIndex = 0
        for j in 0..<rows {
            for i in [0, 1] where i == 0 || (j * 3 + i) % 2 == 0 {
                let grid = treeIndex % 2 == 0 ? Sprites.treeA : Sprites.treeB
                let tree = SKSpriteNode(texture: PixelArt.texture(rows: grid))
                var p = screen(Tile(i: i, j: j))
                p.x += CGFloat(((j * 37 + i * 11) % 11) - 5)
                p.y += CGFloat(((j * 23 + i * 7) % 7) - 3)
                tree.position = p
                tree.anchorPoint = CGPoint(x: 0.5, y: 0.06) // trunk base = contact
                tree.zPosition = zDepth(p.y)
                addChild(tree)
                treeIndex += 1
            }
        }

        // Campfire at the center of camp.
        let fire = CampfireNode()
        var firePos = screen(fireTile)
        firePos.y += 6 // logs sit on the tile top face
        fire.position = firePos
        fire.zPosition = zDepth(firePos.y - 4)
        addChild(fire)
        campfire = fire
    }

    private func diamondPath() -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 0, y: tileH / 2))
        p.addLine(to: CGPoint(x: tileW / 2, y: 0))
        p.addLine(to: CGPoint(x: 0, y: -tileH / 2))
        p.addLine(to: CGPoint(x: -tileW / 2, y: 0))
        p.closeSubpath()
        return p
    }

    /// Hull through the four board corners, expanded outward half a tile.
    private func boardOutline(offsetY: CGFloat) -> CGPath {
        let top = screen(Tile(i: 0, j: 0))
        let right = screen(Tile(i: cols - 1, j: 0))
        let bottom = screen(Tile(i: cols - 1, j: rows - 1))
        let left = screen(Tile(i: 0, j: rows - 1))
        let p = CGMutablePath()
        p.move(to: CGPoint(x: top.x, y: top.y + tileH / 2 + offsetY))
        p.addLine(to: CGPoint(x: right.x + tileW / 2, y: right.y + offsetY))
        p.addLine(to: CGPoint(x: bottom.x, y: bottom.y - tileH / 2 + offsetY))
        p.addLine(to: CGPoint(x: left.x - tileW / 2, y: left.y + offsetY))
        p.closeSubpath()
        return p
    }

    // MARK: - Depth sort

    /// Soldiers move, so their z is re-derived every frame from the
    /// ground-contact y (feet = center-anchored position minus half height).
    override func update(_ currentTime: TimeInterval) {
        for s in soldiers {
            s.zPosition = zDepth(s.position.y - soldierContactOffset)
        }
    }

    // MARK: - Formation tiles

    /// Rank-aware formation: knights ring the fire, archers hold a mid
    /// line behind it, foot soldiers spread across the front field.
    private func formationTile(for rank: SoldierNode.Rank) -> Tile? {
        let knightRing = [Tile(i: 5, j: 4), Tile(i: 7, j: 4), Tile(i: 6, j: 5),
                          Tile(i: 5, j: 5), Tile(i: 7, j: 5), Tile(i: 6, j: 3)]
        let archerLine = [Tile(i: 4, j: 3), Tile(i: 5, j: 3), Tile(i: 7, j: 3), Tile(i: 8, j: 3),
                          Tile(i: 4, j: 4), Tile(i: 8, j: 4), Tile(i: 5, j: 2), Tile(i: 7, j: 2)]
        let footField = [Tile(i: 5, j: 6), Tile(i: 7, j: 6), Tile(i: 4, j: 5), Tile(i: 8, j: 5),
                         Tile(i: 6, j: 6), Tile(i: 3, j: 5), Tile(i: 9, j: 5),
                         Tile(i: 5, j: 7), Tile(i: 7, j: 7), Tile(i: 4, j: 6), Tile(i: 8, j: 6),
                         Tile(i: 6, j: 7), Tile(i: 3, j: 6), Tile(i: 9, j: 6),
                         Tile(i: 6, j: 8), Tile(i: 4, j: 7), Tile(i: 8, j: 7),
                         Tile(i: 10, j: 5), Tile(i: 10, j: 6), Tile(i: 3, j: 4)]
        let queue: [Tile]
        switch rank {
        case .knight: queue = knightRing
        case .archer: queue = archerLine
        case .foot: queue = footField
        }
        if let t = queue.first(where: { !usedTiles.contains($0) }) { return t }
        // Spillover: first free non-reserved tile, scanned front-to-back.
        for sum in stride(from: cols + rows - 2, through: 0, by: -1) {
            for i in 0..<cols {
                let j = sum - i
                guard j >= 0 && j < rows else { continue }
                let t = Tile(i: i, j: j)
                if !isReserved(t) && !usedTiles.contains(t) { return t }
            }
        }
        return nil
    }

    /// Ground-contact point for a tile (with a small deterministic jitter so
    /// units don't look rail-placed).
    private func contactPoint(for t: Tile) -> CGPoint {
        var p = screen(t)
        p.x += CGFloat((t.i * 17 + t.j * 29) % 9) - 4
        p.y += CGFloat((t.i * 13 + t.j * 19) % 5) - 2
        return p
    }

    /// Where a center-anchored soldier must sit for its feet to touch t.
    private func standingPosition(for t: Tile) -> CGPoint {
        var p = contactPoint(for: t)
        p.y += soldierContactOffset
        return p
    }

    // MARK: - Public API (CampSceneDriving)

    func applyComposition(_ comp: ArmyComposition) {
        let current = soldiers.count
        if current == comp.total { return }
        if current < comp.total {
            let deficit = comp.total - current
            for _ in 0..<deficit { spawnRecruit(animated: !soldiers.isEmpty) }
        } else {
            let excess = current - comp.total
            for _ in 0..<excess { soldiers.popLast()?.removeFromParent() }
        }
    }

    /// `n` recruits emerge from the woods and march to formation tiles.
    func spawnRecruits(_ n: Int) {
        for i in 0..<n {
            run(.sequence([
                .wait(forDuration: TimeInterval(i) * 0.45),
                .run { [weak self] in self?.spawnRecruit(animated: true) },
            ]))
        }
    }

    private func spawnRecruit(animated: Bool) {
        placeSoldier(rank: pickRank(), animated: animated)
    }

    private func placeSoldier(rank: SoldierNode.Rank, animated: Bool) {
        guard let t = formationTile(for: rank) else { return }
        usedTiles.insert(t)
        let soldier = SoldierNode(rank: rank)
        let target = standingPosition(for: t)
        soldiers.append(soldier)
        if animated {
            // March in from just off the left (woods) flank of the board.
            var entry = screen(Tile(i: 0, j: min(rows - 1, t.j + 1)))
            entry.x -= 60
            entry.y += soldierContactOffset
            soldier.position = entry
            addChild(soldier)
            soldier.march(to: target, speed: 40)
        } else {
            soldier.position = target
            addChild(soldier)
            soldier.startIdle()
        }
    }

    /// `n` soldiers are downed by arrows fired out of the fog, as in the
    /// flat scene — arrows fly in from the right edge toward the victim.
    func loseSoldiers(_ n: Int) {
        let victims = soldiers.filter { $0.state == .idle && $0.name != "patrol" }.shuffled().prefix(n)
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
        arrow.zPosition = 3000
        arrow.position = CGPoint(x: scene.size.width + 10, y: victim.position.y + 40)
        scene.addChild(arrow)
        let target = CGPoint(x: victim.position.x, y: victim.position.y)
        let dx = target.x - arrow.position.x
        let dy = target.y - arrow.position.y
        arrow.zRotation = atan2(dy, dx)
        arrow.run(.sequence([
            .move(to: target, duration: TimeInterval(sqrt(dx * dx + dy * dy) / 240)),
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

    /// Reconcile outpost towers with the configured competitors, placed
    /// along the right flank of the diamond.
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
            let t = i < outpostTiles.count
                ? outpostTiles[i]
                : Tile(i: cols - 1 - (i % 2), j: min(rows - 1, 1 + i))
            var p = screen(t)
            p.y += towerContactOffset // tower base sits on the tile
            node.position = p
            node.zPosition = zDepth(p.y - towerContactOffset)
            addChild(node)
            outposts[comp.id] = node
        }
    }

    /// Army storms the outpost and raises the banner.
    func captureOutpost(id: UUID) {
        guard let node = outposts[id] else { return }
        let squad = soldiers.filter { $0.state == .idle && $0.name != "patrol" }.prefix(5)
        var pending = squad.count
        let finish: () -> Void = { node.capture() }
        if squad.isEmpty { node.capture(); return }
        for soldier in squad {
            let base = CGPoint(x: node.position.x + .random(in: -26...26),
                               y: node.position.y - towerContactOffset - 6)
            soldier.storm(to: base) {
                pending -= 1
                if pending <= 0 { finish() }
            }
        }
    }

    func uncaptureOutpost(id: UUID) {
        outposts[id]?.uncapture()
    }

    // MARK: - Demo seeding (prototype only)

    /// Deterministic demo population for the look-and-feel review: woods,
    /// campfire, two outposts (one captured), an 18-strong formation with
    /// all three ranks, three recruits marching in, and a patrol knight
    /// crossing the field to exercise live depth sorting.
    func populateDemo() {
        guard built else { demoPending = true; return }

        syncOutposts([
            Competitor(name: "questgain", handle: "@questgain", followerThreshold: 100, captured: true),
            Competitor(name: "pixel_rivals", handle: "@pixel_rivals", followerThreshold: 9999, captured: false),
        ])
        setMorale(.high)

        let seeds: [(SoldierNode.Rank, Tile)] = [
            (.knight, Tile(i: 5, j: 4)), (.knight, Tile(i: 7, j: 4)), (.knight, Tile(i: 6, j: 5)),
            (.archer, Tile(i: 4, j: 3)), (.archer, Tile(i: 5, j: 3)), (.archer, Tile(i: 7, j: 3)),
            (.archer, Tile(i: 8, j: 3)), (.archer, Tile(i: 4, j: 4)), (.archer, Tile(i: 8, j: 4)),
            (.foot, Tile(i: 5, j: 6)), (.foot, Tile(i: 7, j: 6)), (.foot, Tile(i: 4, j: 5)),
            (.foot, Tile(i: 8, j: 5)), (.foot, Tile(i: 6, j: 6)), (.foot, Tile(i: 3, j: 5)),
            (.foot, Tile(i: 9, j: 5)), (.foot, Tile(i: 5, j: 7)), (.foot, Tile(i: 7, j: 7)),
        ]
        for (k, seed) in seeds.enumerated() {
            let (rank, t) = seed
            usedTiles.insert(t)
            let s = SoldierNode(rank: rank)
            s.position = standingPosition(for: t)
            addChild(s)
            soldiers.append(s)
            // De-phase the idle loops so the army doesn't bob in unison.
            s.removeAction(forKey: "anim")
            s.run(.sequence([
                .wait(forDuration: Double((k * 137) % 60) / 100.0),
                .run { [weak s] in s?.startIdle() },
            ]))
        }

        // Recruits marching in from the woods during the first ~2s.
        spawnRecruits(3)

        // Patrol knight sweeping the front field — exercises live depth
        // sorting as he crosses in front of / behind the formation.
        if let t = formationTile(for: .foot) {
            usedTiles.insert(t)
            let patrol = SoldierNode(rank: .knight)
            patrol.name = "patrol"
            patrol.position = standingPosition(for: t)
            addChild(patrol)
            soldiers.append(patrol)
            runPatrol(patrol, between: Tile(i: 3, j: 6), and: Tile(i: 9, j: 4))
        }
    }

    /// Loop a soldier between two tiles; each leg starts when the previous
    /// march completes, plus a short dwell at each end.
    private func runPatrol(_ s: SoldierNode, between a: Tile, and b: Tile) {
        var toB = true
        func leg() {
            guard s.state != .dying, s.scene != nil else { return }
            let target = standingPosition(for: toB ? b : a)
            toB.toggle()
            s.march(to: target, speed: 26) { [weak self] in
                self?.run(.sequence([
                    .wait(forDuration: 0.9),
                    .run { leg() },
                ]))
            }
        }
        leg()
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
