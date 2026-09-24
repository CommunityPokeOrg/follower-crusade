#if canImport(SwiftUI)
import SwiftUI

/// About / credits window.
struct AboutView: View {
    var body: some View {
        VStack(spacing: 14) {
            MedievalCrest()
                .frame(width: 56, height: 56)

            Text("Follower Crusade")
                .font(.system(size: 20, weight: .bold, design: .serif))

            Text("A medieval siege in your menu bar — your followers are the army, engagement keeps the campfires burning, and rival outposts fall as your headcount grows.")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 320)

            Divider()

            VStack(spacing: 6) {
                Text("Created by")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("WillMcfly (@WillMcflyLabs)")
                    .font(.system(size: 14, weight: .semibold))
                Text("Creator, lead designer, and architect of the game concept.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Link("github.com/WillMcflyLabs",
                     destination: URL(string: "https://github.com/WillMcflyLabs")!)
                    .font(.caption)
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.87, green: 0.78, blue: 0.58).opacity(0.18))
            )
        }
        .padding(24)
        .frame(width: 380)
    }
}

/// Crossed-swords style crest for the About window.
private struct MedievalCrest: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [Color(red: 0.84, green: 0.16, blue: 0.46),
                                              Color(red: 0.51, green: 0.20, blue: 0.69)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
    }
}
#endif
