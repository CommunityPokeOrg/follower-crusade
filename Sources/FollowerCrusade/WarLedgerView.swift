#if canImport(SwiftUI)
import SwiftUI
import FollowerCrusadeCore

/// The War Ledger: a timestamped recap log of recent campaign events —
/// recruits joined, soldiers lost, desertions, outpost captures.
struct WarLedgerView: View {
    @ObservedObject var state: AppState

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.12, green: 0.11, blue: 0.10),
                                    Color(red: 0.17, green: 0.14, blue: 0.10)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            if state.ledgerEntries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "scroll")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(red: 0.72, green: 0.60, blue: 0.40))
                    Text("No battles recorded yet")
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundStyle(Color(red: 0.82, green: 0.74, blue: 0.58))
                    Text("Joins, drops, desertions and captures\nwill be written here as they happen.")
                        .font(.system(size: 10))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(red: 0.82, green: 0.74, blue: 0.58).opacity(0.6))
                }
            } else {
                List(state.ledgerEntries) { entry in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: icon(for: entry.kind))
                            .font(.system(size: 11))
                            .foregroundStyle(color(for: entry.kind))
                            .frame(width: 16)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.detail)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white)
                            Text(entry.at, format: .dateTime.month(.abbreviated).day().hour().minute())
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(minWidth: 340, minHeight: 380)
    }

    private func icon(for kind: LedgerEntry.Kind) -> String {
        switch kind {
        case .recruitsJoined: return "person.crop.circle.badge.plus"
        case .soldiersLost: return "arrow.down.circle.fill"
        case .soldierDeserted: return "figure.walk"
        case .outpostCaptured: return "flag.fill"
        case .outpostLost: return "flag.slash.fill"
        }
    }

    private func color(for kind: LedgerEntry.Kind) -> Color {
        switch kind {
        case .recruitsJoined: return Color(red: 0.45, green: 0.80, blue: 0.45)
        case .soldiersLost: return Color(red: 0.90, green: 0.40, blue: 0.35)
        case .soldierDeserted: return .orange
        case .outpostCaptured: return Color(red: 0.88, green: 0.35, blue: 0.60)
        case .outpostLost: return Color(red: 0.70, green: 0.55, blue: 0.40)
        }
    }
}
#endif
