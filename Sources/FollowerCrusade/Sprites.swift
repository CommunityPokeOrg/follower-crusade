#if canImport(SpriteKit)
import SpriteKit

/// Hand-drawn pixel grids. Each character maps through `PixelArt.palette`;
/// `.` is transparent. Sprites are ~14px wide rendered at 3x scale.
enum Sprites {

    // MARK: - Foot soldier (idle, 2 frames)

    static let footIdleA = [
        "..............",
        ".....OOO......",
        "....OHHHO.....",
        "....OHHHO.....",
        "....OFFFF.....",
        "....OFFFF.....",
        ".....OFFF.....",
        "...OTTTTTTO...",
        "..OTVTTTVTO...",
        "..OTTTTTTTO..",
        "..OBBTTTTTO...",
        "...OTTTTTO....",
        "....OLLOLO....",
        "....OLOLO.....",
        "....OLOLO.....",
        "...OBBOBB.....",
    ]

    static let footIdleB = [
        "..............",
        ".....OOO......",
        "....OHHHO.....",
        "....OHHHO.....",
        "....OFFFF.....",
        "....OFFF......",
        ".....OFFF.....",
        "...OTTTTTTO...",
        "..OTVTTTVTO...",
        "..OTTTTTTTO..",
        "..OBBTTTTTO...",
        "...OTTTTTO....",
        "....OLLOLO....",
        "....OLOLO.....",
        "....OLOLO.....",
        "...OBBOBB.....",
    ]

    // MARK: - Foot soldier (march, 2 frames)

    static let footMarchA = [
        "..............",
        ".....OOO......",
        "....OHHHO.....",
        "....OHHHO.....",
        "....OFFFF.....",
        "....OFFFF.....",
        ".....OFFF.....",
        "...OTTTTTTO...",
        "..OTVTTTVTO...",
        "..OTTTTTTTO..",
        "..OBBTTTTTO...",
        "...OTTTTTO....",
        "....OLLO.....",
        "....OLO.O....",
        "...OLO..O....",
        "..OBB...OB...",
    ]

    static let footMarchB = [
        "..............",
        ".....OOO......",
        "....OHHHO.....",
        "....OHHHO.....",
        "....OFFFF.....",
        "....OFFFF.....",
        ".....OFFF.....",
        "...OTTTTTTO...",
        "..OTVTTTVTO...",
        "..OTTTTTTTO..",
        "..OBBTTTTTO...",
        "...OTTTTTO....",
        ".....OLLO....",
        "....O.LOLO...",
        "....O..OLO...",
        "...OB..OBB...",
    ]

    // MARK: - Archer (bow in left hand, quiver on back)

    static let archerIdle = [
        "..............",
        ".....OOO......",
        "....OHHHO.....",
        "....OFFFF.....",
        "....OFFFF.....",
        ".....OFFF.....",
        "..SOTTTTTTO...",
        ".S.OTVTVTO...",
        ".S.OTTTTTTO..",
        ".SOBBTTTTTO...",
        ".S..OTTTTO....",
        ".S...OLLOL....",
        "....S.OLOLO...",
        ".....OLOLO....",
        "....OBBOBB....",
    ]

    static let archerMarch = [
        "..............",
        ".....OOO......",
        "....OHHHO.....",
        "....OFFFF.....",
        "....OFFFF.....",
        ".....OFFF.....",
        "..SOTTTTTTO...",
        ".S.OTVTVTO...",
        ".S.OTTTTTTO..",
        ".SOBBTTTTTO...",
        ".S..OTTTTO....",
        ".S...OLLO.....",
        "....S.OLO.O..",
        ".....OLO..O..",
        "....OBB..OB..",
    ]

    // MARK: - Knight (plumed helm, gold trim, shield left)

    static let knightIdle = [
        "..............",
        ".....OMM......",
        "....OMHHO.....",
        "....OHHHO.....",
        "....OHHHO.....",
        ".....OHH......",
        "...OGGGGGO....",
        "..OGVGGGVOG...",
        ".OOOGGGGGGO...",
        ".OBOGGGGGGO...",
        ".OBOGGGGGGO...",
        ".OOOGGGGGO....",
        "....OLLOLO....",
        "....OLOLO.....",
        "....OLOLO.....",
        "...OBBOBB.....",
    ]

    static let knightMarch = [
        "..............",
        ".....OMM......",
        "....OMHHO.....",
        "....OHHHO.....",
        "....OHHHO.....",
        ".....OHH......",
        "...OGGGGGO....",
        "..OGVGGGVOG...",
        ".OOOGGGGGGO...",
        ".OBOGGGGGGO...",
        ".OBOGGGGGGO...",
        ".OOOGGGGGO....",
        "....OLLO.....",
        "....OLO.O....",
        "...OLO..O....",
        "..OBB...OB...",
    ]

    // MARK: - Fallen soldier / skull

    static let fallen = [
        "..............",
        "..............",
        "..............",
        "..............",
        "..............",
        "..............",
        "..............",
        "..............",
        "..............",
        "..............",
        "..OOO......",
        ".OHHHOOOO...",
        ".OFFFFFFOOO.",
        ".OTTTTTTTT..",
        ".OTVTTVT....",
        ".OBBOBBO....",
    ]

    static let skull = [
        "........",
        "..OOOO..",
        ".OwwwwO.",
        ".OwKKwO.",
        ".OwwwwO.",
        ".OwKKwO.",
        "..OwwO..",
        "..OKKO..",
    ]

    // MARK: - Campfire (3 flicker frames) + logs

    static let fireA = [
        "........",
        "...Y....",
        "..YYr...",
        "..Yrr...",
        ".rYYrr..",
        ".rrYrer.",
        ".rreerr.",
        "ereeeeer",
    ]

    static let fireB = [
        "........",
        "....Y...",
        "..rYY...",
        "..rrY...",
        ".rrYYr..",
        ".reYrrr.",
        ".rreerr.",
        "ereeeeer",
    ]

    static let fireC = [
        "........",
        "..Y.....",
        "..YY....",
        "..rYYr..",
        ".rrrYr..",
        ".rreYrr.",
        ".ereerr.",
        "ereeeeer",
    ]

    static let logs = [
        "........",
        "........",
        "..t..t..",
        ".tSStS..",
        "..SSSS..",
        ".tSStSt.",
        "..t..t..",
        "........",
    ]

    // MARK: - Trees (left-edge woods)

    static let treeA = [
        "....d.....",
        "...dgd....",
        "..dgggd...",
        "..dgggd...",
        ".dgggggd..",
        ".dgggggd..",
        "dgggggggd.",
        "...ttt....",
        "...ttt....",
        "...ttt....",
    ]

    static let treeB = [
        "...d.d....",
        "..dgggd...",
        ".dgggggd..",
        ".dgdgdgd..",
        "dgggggggd.",
        "..ttttt...",
        "...ttt....",
        "...ttt....",
        "...ttt....",
        "...ttt....",
    ]

    // MARK: - Outpost tower (competitor)

    static let tower = [
        "sosososososo",
        "sosososososo",
        "sooooooooooo",
        ".ooooooooo..",
        ".oososssoo..",
        ".oososssoo..",
        ".oososssoo..",
        ".ooosssooo..",
        ".ooosssooo..",
        ".ooosssooo..",
        ".ooosssooo..",
        ".oosssssoo..",
        ".oosssssoo..",
        "oosssssssoo.",
        "oosssssssoo.",
    ]

    // MARK: - Banners (neutral/rival vs Instagram-captured)

    static let flagNeutral = [
        "SS.......",
        "SRRRRRRR.",
        "SRRRRRRR.",
        "SRRRRR...",
        "S........",
        "S........",
    ]

    static let flagCaptured = [
        "SS.......",
        "SMMMMMMM.",
        "SMMWWMMM.",   // magenta pennant w/ white IG crest stripe
        "SMVVMM...",
        "S........",
        "S........",
    ]

    // MARK: - Arrow (fired from the fog)

    static let arrow = [
        "ffaaaaaaaaXXX.",
        "..ffaaaaaXXXX.",
        "ffaaaaaaaaXXX.",
    ]

    // MARK: - Instagram crest shield overlay (provenance marker)

    static let igCrest = [
        ".MMMM.",
        "MVMVMM",
        "MMWMMM",
        "MWMWMM",
        "MMWMMM",
        "MVMVMM",
        ".MMMM.",
        "..MM..",
    ]
}
#endif
