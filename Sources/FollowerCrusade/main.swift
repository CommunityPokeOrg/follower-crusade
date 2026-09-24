#if canImport(AppKit)
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
#else
import Foundation
print("FollowerCrusade is a macOS-only application. Build and run it on macOS.")
#endif
