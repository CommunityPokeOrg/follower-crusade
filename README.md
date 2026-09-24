# follower-crusade
Follower Crusade: a native macOS pixel-art social follower tracker

> **Created by [WillMcfly (@WillMcflyLabs)](https://github.com/WillMcflyLabs)** — creator, lead designer, and architect of the game concept.

## Credits

Follower Crusade was created, designed, and architected by **[WillMcfly (@WillMcflyLabs)](https://github.com/WillMcflyLabs)**. All credit for the game concept goes to them.

## What it is

A lightweight floating desktop widget + menu bar app for macOS, built with native Swift, SwiftUI, AppKit, and SpriteKit. Your Instagram follower count is your army's headcount — rendered as animated pixel foot soldiers, archers, and knights camped in a framed medieval HUD on your desktop.

### The siege

- **Army = followers.** Each soldier represents a configurable number of followers (default: 1 per 250). Archers unlock at 10 soldiers, knights at 25. Composition is capped for performance; the true headcount shows in the HUD header and menu bar.
- **Follower gained** — a recruit emerges from the woods on the left and marches into camp.
- **Follower lost** — an arrow flies out of the fog of war on the right and downs a soldier: ragdoll collapse, brief skull, fade.
- **Engagement = supplies.** Posts/likes/comments roll into an engagement score driving camp morale: bright campfires and lively camps when high; smoldering fires, smoke, and desertions when low.
- **Competitor outposts.** Configure rival accounts with follower thresholds in Settings — they appear as towers on the right edge. Surpassing a rival's count sends a squad to storm the outpost and raises your banner on it. Captures persist across restarts (and are recaptured if you fall back below).
- **Instagram provenance.** Every soldier carries a tiny heraldic shield in Instagram's magenta/purple gradient, marking the platform the follower came from. Instagram is the only supported platform; the provider layer is built to extend.

## Requirements

- macOS 13+ (Ventura or later), Apple Silicon or Intel
- Swift toolchain: Xcode 15+ command line tools (or a standalone Swift 6 toolchain)
- Optional: [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) to produce a proper `.app` bundle

## Build & run

**Quick run (SwiftPM executable — no Xcode project needed):**

```bash
swift build -c release
swift run -c release   # or: .build/release/FollowerCrusade
```

The app launches as a menu-bar accessory (no Dock icon): a shield icon + follower count appear in the menu bar, and the framed HUD floats at your chosen corner.

**As a real `.app` bundle (recommended for distribution):**

```bash
brew install xcodegen   # once
make app                # generates FollowerCrusade.xcodeproj + builds
open build/FollowerCrusade.app
```

Or `xcodegen generate` then `open FollowerCrusade.xcodeproj` and press ⌘R.

**Tests:**

```bash
swift test
```

## Configuration

Open **Settings…** from the menu bar item.

### Data source ("Source of Intel")

| Provider | What it does | Needs |
|---|---|---|
| **Mock (slider mode)** | Default. Sliders for followers + engagement, optional random-walk simulation, and `+25 recruits` / `−25 arrows inbound` buttons in the menu — every animation is testable immediately, no credentials. | Nothing |
| **Instagram Graph API (direct)** | Reads `followers_count` via `graph.instagram.com/me` (Basic Display) or `graph.facebook.com/{ig-user-id}` (Graph API). Engagement is estimated from recent media like/comment counts when permissions allow. | Access token + IG user ID |
| **Metricool — Instagram connection** | Reads your Metricool-connected Instagram profile via Metricool's stats API (`X-Mc-Auth` header). | Metricool API key, user ID, blog ID |

> Only Instagram is currently supported. The `SocialDataSource` protocol + provider picker are designed so new platforms can be added later without touching the scene.

### Warband

- Soldiers-per-follower ratio, max on-screen soldiers, poll interval, and an effects toggle (particles/banners).

### HUD Window

- **Floating** remembers where you drag the frame; the four corner options dock it to the screen edge. Dragging near a corner also snaps it there.

### Rival Outposts

- Add competitors by name + follower threshold. Each appears as a tower; surpassing it triggers the storm-and-banner sequence.

## Architecture

```
Sources/
  FollowerCrusadeCore/   Pure Swift — no Apple UI frameworks.
    Models.swift           Snapshots, events, competitors, morale, dock corners.
    MetricsEngine.swift    Snapshot diffing → scene events, morale bands,
                           desertion rolls, army composition tiers.
    Settings.swift         Codable settings + UserDefaults persistence.
  FollowerCrusade/       The macOS app (AppKit + SwiftUI + SpriteKit).
    main.swift             Entry point (menu-bar accessory app).
    AppDelegate.swift      Wires state, scene, HUD window, menu bar, windows.
    AppState.swift         Polling loop + event dispatch to the scene.
    SocialDataSource.swift SocialDataSource protocol; Mock, Instagram Graph,
                           and Metricool-Instagram adapters; provider factory.
    CampScene.swift        SpriteKit diorama: woods, camp, outposts, fog.
    SoldierNode.swift      Soldier state machine (march/idle/die/desert/storm)
                           + IG provenance crest.
    CampfireNode.swift     Morale-driven fire + smoke.
    OutpostNode.swift      Competitor tower + banner-raise capture sequence.
    PixelArt.swift         Runtime pixel-grid → SKTexture factory (nearest).
    Sprites.swift          Hand-drawn pixel grids for every sprite.
    MedievalFrame.swift    Iron/parchment/stone HUD frame (SwiftUI Canvas).
    HUDView.swift          HUD content: header, SpriteView, frame.
    HUDWindowController.swift  Floating NSPanel, drag, corner docking, persist.
    MenuBarController.swift    NSStatusItem + menu (mock drill-yard included).
    SettingsView.swift     Settings window.
    AboutView.swift        Credits window.
Tests/FollowerCrusadeCoreTests/  Unit tests for the core engine (also run on Linux).
```

## Notes & limitations

- The app is a bare executable when run via `swift run` — it self-configures as a menu-bar accessory. For a signed/notarized distributable `.app`, use the xcodegen path and add your signing settings.
- Metricool and Instagram API calls are credential-gated and lightly integration-tested — endpoints/field names may need small adjustments for your account's API plan. Mock mode exercises every animation without them.
- Rendering is capped (default 60 soldiers); the HUD badge shows the true count.
