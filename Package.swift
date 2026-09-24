// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FollowerCrusade",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "FollowerCrusade", targets: ["FollowerCrusade"]),
        .library(name: "FollowerCrusadeCore", targets: ["FollowerCrusadeCore"]),
    ],
    targets: [
        // Pure-Swift game/metric logic — no Apple UI frameworks, compiles and
        // tests on Linux as well as macOS.
        .target(
            name: "FollowerCrusadeCore",
            path: "Sources/FollowerCrusadeCore"
        ),
        // The macOS app shell: floating HUD window, menu bar extra, SpriteKit
        // siege scene, settings. Sources are wrapped in canImport guards so the
        // package still parses/builds its core on Linux.
        .executableTarget(
            name: "FollowerCrusade",
            dependencies: ["FollowerCrusadeCore"],
            path: "Sources/FollowerCrusade"
        ),
        .testTarget(
            name: "FollowerCrusadeCoreTests",
            dependencies: ["FollowerCrusadeCore"],
            path: "Tests/FollowerCrusadeCoreTests"
        ),
    ]
)
