#if canImport(SwiftUI)
import SwiftUI
import FollowerCrusadeCore

/// Settings window: data-source adapter picker (Instagram via Metricool or the
/// Graph API directly, plus mock mode), rendering prefs, dock corner, and the
/// competitor outpost list.
struct SettingsView: View {
    @ObservedObject var state: AppState
    @State private var s: AppSettings
    @State private var newCompName = ""
    @State private var newCompThreshold = ""

    init(state: AppState) {
        self.state = state
        _s = State(initialValue: state.store.settings)
    }

    var body: some View {
        Form {
            Section("Source of Intel") {
                Picker("Provider", selection: providerBinding) {
                    ForEach(DataProviderKind.allCases, id: \.self) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                switch s.providerKind {
                case .instagramGraph:
                    SecureField("Access token", text: binding(\.instagramAccessToken))
                    TextField("IG user id (or \"me\")", text: binding(\.instagramUserID))
                    Text("Uses Instagram Graph/Basic Display API for followers_count; engagement is estimated from recent media interactions.", comment: "")
                        .font(.caption).foregroundStyle(.secondary)
                case .metricoolInstagram:
                    SecureField("Metricool API key (X-Mc-Auth)", text: binding(\.metricoolAPIKey))
                    TextField("Metricool user ID", text: binding(\.metricoolUserID))
                    TextField("Metricool blog ID (Instagram connection)", text: binding(\.metricoolBlogID))
                    Text("Reads your Metricool-connected Instagram profile. More platforms may arrive later — Instagram is supported today.", comment: "")
                        .font(.caption).foregroundStyle(.secondary)
                case .mock:
                    LabeledContent("Mock followers") {
                        Slider(value: mockFollowersDouble, in: 0...100000, step: 25)
                        Text("\(s.mockFollowers)").monospacedDigit().frame(width: 60)
                    }
                    LabeledContent("Mock engagement") {
                        Slider(value: binding(\.mockEngagement), in: 0...1)
                        Text(String(format: "%.2f", s.mockEngagement)).monospacedDigit().frame(width: 40)
                    }
                    Toggle("Random-walk simulation", isOn: binding(\.mockRandomWalk))
                }
                if let err = state.lastError {
                    Text(err).font(.caption).foregroundStyle(.red)
                }
            }

            Section("Warband") {
                Stepper("Soldier per \(s.soldiersPerFollower) followers",
                        value: binding(\.soldiersPerFollower), in: 10...10000, step: 10)
                Stepper("Max on-screen soldiers: \(s.maxSoldiers)",
                        value: binding(\.maxSoldiers), in: 10...200, step: 10)
                Stepper("Poll every \(Int(s.pollIntervalSeconds))s",
                        value: binding(\.pollIntervalSeconds), in: 10...3600, step: 10)
                Toggle("Effects (particles, banners)", isOn: binding(\.effectsEnabled))
            }

            Section("HUD Window") {
                Picker("Position", selection: binding(\.dockCorner)) {
                    ForEach(DockCorner.allCases, id: \.self) { c in
                        Text(c.displayName).tag(c)
                    }
                }
                .help("Floating remembers where you drag it; corners dock to the screen edge.")
            }

            Section("Rival Outposts") {
                ForEach(s.competitors) { comp in
                    HStack {
                        Text(comp.captured ? "⚑" : "⚐")
                        Text(comp.name).fontWeight(.medium)
                        Spacer()
                        Text("\(comp.followerThreshold)")
                            .monospacedDigit().foregroundStyle(.secondary)
                        Button(role: .destructive) { removeCompetitor(comp) } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack {
                    TextField("Rival name", text: $newCompName)
                    TextField("Follower threshold", text: $newCompThreshold)
                        .frame(width: 110)
                    Button("Add") { addCompetitor() }
                        .disabled(newCompName.isEmpty || Int(newCompThreshold) == nil)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 520)
        .padding()
        .onDisappear { persist() }
    }

    // MARK: - Bindings

    private func binding<V>(_ kp: WritableKeyPath<AppSettings, V>) -> Binding<V> {
        Binding(get: { s[keyPath: kp] },
                set: { s[keyPath: kp] = $0; persist() })
    }

    private var providerBinding: Binding<DataProviderKind> {
        Binding(get: { s.providerKind },
                set: { s.providerKind = $0; persist(); Task { await state.tick() } })
    }

    private var mockFollowersDouble: Binding<Double> {
        Binding(get: { Double(s.mockFollowers) },
                set: { s.mockFollowers = Int($0); persist(); DataSourceFactory.mock.snapToSettings(); Task { await state.tick() } })
    }

    private func persist() {
        state.store.settings = s
    }

    // MARK: - Competitors

    private func addCompetitor() {
        guard let threshold = Int(newCompThreshold) else { return }
        s.competitors.append(Competitor(name: newCompName, handle: newCompName, followerThreshold: threshold))
        newCompName = ""
        newCompThreshold = ""
        persist()
        Task { await state.tick() }
    }

    private func removeCompetitor(_ comp: Competitor) {
        s.competitors.removeAll { $0.id == comp.id }
        persist()
        Task { await state.tick() }
    }
}
#endif
