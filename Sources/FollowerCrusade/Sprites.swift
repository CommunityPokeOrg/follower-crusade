#if canImport(SpriteKit)
import SpriteKit

/// Hand-drawn pixel grids. Each character maps through `PixelArt.palette`;
/// `.` is transparent. Soldier sprites are 16px wide × 18px tall on a shared
/// canvas (idle/march/hit/fallen) so `setTexture` swaps never rescale the
/// node; rendered at 2x nearest-neighbor. Shading convention: light hits the
/// upper-left (`q`/`n`/`i`), shade pools lower-right (`h`/`p`/`j`/`m`/`z`).
enum Sprites {

    // MARK: - Foot soldier (kettle helm, spear, navy tunic)

    static let footIdleA = [
        ".............X..",
        "......OOOO...XX.",
        ".....OqqHHHhO.S.",
        "....OqHHHHhhO.S.",
        "...OqhhhhhhhO.S.",
        "....OFFFFFFFu.S.",
        "....OFuFKFFuO.S.",
        "....OFFFFFuO..S.",
        ".....OFFFFO...S.",
        "..OTnnTTTTpTO.S.",
        "..OTnTTTTTTpTOS.",
        "..OTnTTTTTTpTOS.",
        "..OTnTTTTTTpTOS.",
        "..OBBGBBBBBBBOS.",
        "...OTTppTTTO..S.",
        "...OLLuLuLL...S.",
        "...OLL.LOLL...S.",
        "..OBBz...zBBO.S.",
    ]

    static let footIdleB = [
        ".............X..",
        "......OOOO...XX.",
        ".....OqqHHHhO.S.",
        "....OqHHHHhhO.S.",
        "...OqhhhhhhhO.S.",
        "....OFFFFFFFu.S.",
        "....OFuFKFFuO.S.",
        "....OFFFFFuO..S.",
        ".....OFFFFO...S.",
        "..OTnnTTTTpTO.S.",
        "..OTnTTTTTTpTOS.",
        "..OTnTTTTTTpTOS.",
        "..OTnTTTTTTpTOS.",
        "..OBBGBBBBBBBOS.",
        "...OTTppTTTO..S.",
        "...OLLuLLL...S..",
        "...OLLuLLL...S..",
        "...OBBzBBO...S..",
    ]

    // MARK: - Foot soldier (march, 2 frames)

    static let footMarchA = [
        ".............X..",
        "......OOOO...XX.",
        ".....OqqHHHhO.S.",
        "....OqHHHHhhO.S.",
        "...OqhhhhhhhO.S.",
        "....OFFFFFFFu.S.",
        "....OFuFKFFuO.S.",
        "....OFFFFFuO..S.",
        ".....OFFFFO...S.",
        "..OTnnTTTTpTO.S.",
        "..OTnTTTTTTpTOS.",
        "..OTnTTTTTTpTOS.",
        "..OTnTTTTTTpTOS.",
        "..OBBGBBBBBBBOS.",
        "..OTTppTTTO...S.",
        "..OLLuLLL....S..",
        ".OLL...LLL...S..",
        ".OBBz..zBBO..S..",
    ]

    static let footMarchB = [
        ".............X..",
        "......OOOO...XX.",
        ".....OqqHHHhO.S.",
        "....OqHHHHhhO.S.",
        "...OqhhhhhhhO.S.",
        "....OFFFFFFFu.S.",
        "....OFuFKFFuO.S.",
        "....OFFFFFuO..S.",
        ".....OFFFFO...S.",
        "..OTnnTTTTpTO.S.",
        "..OTnTTTTTTpTOS.",
        "..OTnTTTTTTpTOS.",
        "..OTnTTTTTTpTOS.",
        "..OBBGBBBBBBBOS.",
        "..OTTppTTTO...S.",
        "...LLLuLL...S...",
        "...LL...LLL..S..",
        "..OBBz..zBBO.S..",
    ]

    /// Hit frame: figure rocked back a pixel, chin up, arm thrown out —
    /// the beat before the collapse.
    static let footHit = [
        "............XX..",
        ".....OOOO.....S.",
        "....OqqHHHhO..S.",
        "...OqHHHHhhO..S.",
        "..OqhhhhhhhO..S.",
        "...OFFFFFFFu..S.",
        "...OFuFFKFuO..S.",
        "...OFFFFFuO...S.",
        "....OFFFFO....S.",
        ".OTnnTTTTpTO..S.",
        ".OTnTTTTTTpTO.S.",
        "OFnTTTTTTpTO..S.",
        "OFTnTTTTTTpTO.S.",
        ".OBBGBBBBBBBO.S.",
        "..OTTppTTTO...S.",
        "..OLLuLuLL....S.",
        ".OLL..LLL.....S.",
        ".OBBz...zBBO..S.",
    ]

    // MARK: - Archer (hooded, longbow left, quiver + arrows on the back)

    static let archerIdle = [
        "................",
        "......OOOO......",
        ".....OjiiiidO...",
        "....OjddddddO...",
        "..S.OFFFFFFFFO..",
        ".S..OFuFKFFuO...",
        ".S..OFFFFFuO.a..",
        ".S...OFFFFO..a..",
        "..S...........a.",
        "..SOTnnTTTTpTOc.",
        ".S.OTnTTTTTTpTO.",
        ".S.OTnTTTTTTpTc.",
        ".S.OTnTTTTTTpTc.",
        "..SOBBGBBBBBBBO.",
        "...OTTppTTTO....",
        "...OLLuLuLL.....",
        "...OLL.LOLL.....",
        "..OBBz...zBBO...",
    ]

    static let archerMarch = [
        "................",
        "......OOOO......",
        ".....OjiiiidO...",
        "....OjddddddO...",
        "..S.OFFFFFFFFO..",
        ".S..OFuFKFFuO...",
        ".S..OFFFFFuO.a..",
        ".S...OFFFFO..a..",
        "..S...........a.",
        "..SOTnnTTTTpTOc.",
        ".S.OTnTTTTTTpTO.",
        ".S.OTnTTTTTTpTc.",
        ".S.OTnTTTTTTpTc.",
        "..SOBBGBBBBBBBO.",
        "..OTTppTTTO.....",
        "..OLLuLLL.......",
        ".OLL...LLL......",
        ".OBBz..zBBO.....",
    ]

    static let archerHit = [
        "................",
        ".....OOOO.......",
        "....OjiiiidO....",
        "...OjddddddO....",
        "..SOFFFFFFFFO...",
        ".S.OFuFFKFuO....",
        ".S.OFFFFFuO..a..",
        ".S..OFFFFO...a..",
        "..S...........a.",
        "..OTnnTTTTpTO.c.",
        ".SOTnTTTTTTpTO..",
        ".SOTnTTTTTTpTc..",
        ".SOTnTTTTTTpTc..",
        "..SOBBGBBBBBBBO.",
        "..OTTppTTTO.....",
        "..OLLuLuLL......",
        ".OLL..LLL.......",
        ".OBBz...zBBO....",
    ]

    // MARK: - Knight (plumed greathelm, gold pauldrons, IG crest shield left)

    static let knightIdle = [
        "......RRR.......",
        "......RRRR......",
        ".....ORRRRO.....",
        "....OOqqHHO.....",
        "...OqqHHHHHhO...",
        "...OhHHKKHHhO...",
        "...OhHHHHHHhO...",
        "....OhHHHHhO....",
        ".....OOkkOO.....",
        "..OGGGkkGGGGO...",
        ".OGkGOHHHHOOGkO.",
        ".OGGOHqHHHHOGGO.",
        "OMVOOHqHHHHOO...",
        "OMMVOHqHHHHkO...",
        "OMVMOOBGBBBO....",
        ".OMMOLLuLuLL....",
        "..OO.OLL.LOLL...",
        "....OBBz...zBBO.",
    ]

    static let knightMarch = [
        "......RRR.......",
        "......RRRR......",
        ".....ORRRRO.....",
        "....OOqqHHO.....",
        "...OqqHHHHHhO...",
        "...OhHHKKHHhO...",
        "...OhHHHHHHhO...",
        "....OhHHHHhO....",
        ".....OOkkOO.....",
        "..OGGGkkGGGGO...",
        ".OGkGOHHHHOOGkO.",
        ".OGGOHqHHHHOGGO.",
        "OMVOOHqHHHHOO...",
        "OMMVOHqHHHHkO...",
        "OMVMOOBGBBBO....",
        ".OMMOLLuLLL.....",
        "..OOOLL...LLL...",
        "....OBBz..zBBO..",
    ]

    static let knightHit = [
        ".....RRR........",
        ".....RRRR.......",
        "....ORRRRO......",
        "...OOqqHHO......",
        "..OqqHHHHHhO....",
        "..OhHHKKHHhO....",
        "..OhHHHHHHhO....",
        "...OhHHHHhO.....",
        ".....OOkkOO.....",
        "..OGGGkkGGGGO...",
        "MOGkGOHHHHOOGkO.",
        "OMVGOHqHHHHOGGO.",
        "OMMVOHqHHHHOO...",
        ".OMMOHqHHHHkO...",
        "..OO.OBGBBBO....",
        "....OLLuLuLL....",
        "...OLL..LLL.....",
        "...OBBz..zBBO...",
    ]

    // MARK: - Fallen soldier (same canvas; body lies along the bottom)

    static let fallen = [
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
        "........a.......",
        ".......f........",
        "..OOO...a.......",
        ".OqHhO.OOOOOOOO.",
        "OFFuFFnTTTTTTTnO",
        ".OFFFFpTTTTTppLO",
        ".OOOuTBBBBBBBBO.",
        "....OOOzzzzOO...",
        "................",
    ]

    static let skull = [
        "..OOOO..",
        ".OwwwwO.",
        ".OwKKwO.",
        ".ObwwbO.",
        ".OwKKwO.",
        ".OwbwbO.",
        "..OwwO..",
        "..ObbO..",
    ]

    // MARK: - Campfire (3 flicker frames) + stone fire-pit ring

    static let fireA = [
        "...y....",
        "...Yy...",
        "..rYYr..",
        "..rYyr..",
        ".rrYyr..",
        ".rYrYrr.",
        "rrreerrr",
        "eeeeevee",
    ]

    static let fireB = [
        "....y...",
        "...Yy...",
        "..rYY...",
        "..rYyr..",
        ".rrYYrr.",
        ".rrYrYr.",
        "rrreerrr",
        "eeveeeve",
    ]

    static let fireC = [
        "..y.....",
        "..Yy....",
        "..YYr...",
        ".rYyr...",
        ".rrYYr..",
        ".rYrYrr.",
        "rrreerrr",
        "eveeevee",
    ]

    static let logs = [
        "........",
        "..t..t..",
        ".tsssst.",
        ".ts..st.",
        ".ts..st.",
        ".tsssst.",
        "..t..t..",
        "........",
    ]

    // MARK: - Trees (left-edge woods): pine + round oak

    static let treeA = [
        ".....j......",
        "....jgg.....",
        "...jgggi....",
        "..jgggggi...",
        "..jgggggi...",
        ".jgggggggi..",
        ".jggggggggi.",
        "jggggggggggi",
        "...tlltt....",
        "....tllt....",
        "....tllt....",
    ]

    static let treeB = [
        "....jjj.....",
        "...jgggi....",
        "..jggiggi...",
        ".jgggggggi..",
        ".jggiggggi..",
        ".jgggggggi..",
        "..jgggggi...",
        "...jggi.....",
        "....ttt.....",
        "....tlt.....",
        "....tlt.....",
    ]

    // MARK: - Outpost tower (competitor): crenellated keep

    static let tower = [
        "ososososososos",
        "ososososososos",
        "oooooooooooooo",
        ".qqssssssssso.",
        ".qsssssKsssso.",
        ".qssssKKKssso.",
        ".qsssssKsssso.",
        ".qsssssssssso.",
        ".osssssssssso.",
        ".ossssKssssso.",
        ".osssssssssso.",
        ".osssssssssso.",
        ".osssssssssso.",
        ".osssOOOOssso.",
        ".ossOzzzzOsso.",
        ".ossOzzzzOsso.",
        "oossOzzzzOssoo",
        "oossOOOOOOssoo",
    ]

    // MARK: - Banners (neutral/rival vs Instagram-captured)

    static let flagNeutral = [
        "S.........",
        "SRRRRRRR..",
        "SRrRRrR...",
        "SRRrR.....",
        "SRr.......",
        "S.........",
        "S.........",
    ]

    static let flagCaptured = [
        "S.........",
        "SMMMMMMMm.",
        "SMMWWMMm..",   // magenta pennant w/ white IG crest stripe
        "SMVWVMm...",
        "SMmMm.....",
        "S.m.......",
        "S.........",
    ]

    // MARK: - Arrow (fired from the fog)

    static let arrow = [
        "ffaaaaaaaaXXx..",
        "..ffaaaaaXXXXx.",
        "ffaaaaaaaaXXx..",
    ]

    // MARK: - Instagram crest shield overlay (provenance marker)

    static let igCrest = [
        ".MMMMMM.",
        "MMWWMMM.",
        "MmWWMm..",
        "MMVWVM..",
        ".MmWMm..",
        "..MMm...",
        "...Mm...",
        "........",
    ]
}
#endif
