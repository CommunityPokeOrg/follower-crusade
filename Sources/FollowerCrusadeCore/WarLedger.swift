import Foundation

/// One recorded campaign event for the War Ledger — joins, losses,
/// desertions and outpost captures, each timestamped.
public struct LedgerEntry: Codable, Equatable, Sendable, Identifiable {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        /// Followers gained — recruits mustered into the warband.
        case recruitsJoined
        /// Followers lost — soldiers downed by arrows from the fog.
        case soldiersLost
        /// A soldier walked off while morale was low.
        case soldierDeserted
        /// A competitor outpost was stormed and the banner raised.
        case outpostCaptured
        /// A previously captured outpost was retaken by the rival.
        case outpostLost
    }

    public var id: UUID
    public var at: Date
    public var kind: Kind
    /// Headcount where relevant (recruits/fallen/deserted), else 1.
    public var amount: Int
    /// Ready-to-render line, e.g. "+25 recruits arrived" or "Rival Keep captured".
    public var detail: String

    public init(id: UUID = UUID(), at: Date, kind: Kind, amount: Int, detail: String) {
        self.id = id
        self.at = at
        self.kind = kind
        self.amount = amount
        self.detail = detail
    }
}

/// Totals over a window of the ledger, e.g. "while you were away".
public struct LedgerSummary: Equatable, Sendable {
    public var joined = 0
    public var lost = 0
    public var deserted = 0
    public var captured = 0
    public var outpostsLost = 0

    public init() {}

    public var isEmpty: Bool {
        joined == 0 && lost == 0 && deserted == 0 && captured == 0 && outpostsLost == 0
    }

    /// "+5 recruits arrived, 2 fallen in battle, 1 outpost captured"
    public var text: String {
        var parts: [String] = []
        if joined > 0 { parts.append("+\(joined) recruits arrived") }
        if lost > 0 { parts.append("\(lost) fallen in battle") }
        if deserted > 0 { parts.append("\(deserted) deserted") }
        if captured > 0 { parts.append("\(captured) outpost\(captured == 1 ? "" : "s") captured") }
        if outpostsLost > 0 { parts.append("\(outpostsLost) outpost\(outpostsLost == 1 ? "" : "s") lost") }
        return parts.joined(separator: ", ")
    }
}

/// Rolling, capped, Codable event log persisted with the app settings.
public struct WarLedger: Codable, Equatable, Sendable {
    public private(set) var entries: [LedgerEntry]
    /// Hard cap so the UserDefaults blob stays small; oldest drop off.
    public var limit: Int

    public init(entries: [LedgerEntry] = [], limit: Int = 300) {
        self.entries = entries
        self.limit = max(1, limit)
        trim()
    }

    public mutating func record(kind: LedgerEntry.Kind, amount: Int, detail: String, at: Date = Date()) {
        entries.append(LedgerEntry(at: at, kind: kind, amount: amount, detail: detail))
        trim()
    }

    /// Record a MetricEvent. `name` resolves a competitor id to a display name.
    /// Engagement updates are not ledger-worthy — too noisy.
    public mutating func record(_ event: MetricEvent, at: Date = Date(), name: (UUID) -> String?) {
        switch event {
        case .followersChanged(let delta) where delta > 0:
            record(kind: .recruitsJoined, amount: delta,
                   detail: "+\(delta) recruits arrived", at: at)
        case .followersChanged(let delta):
            record(kind: .soldiersLost, amount: -delta,
                   detail: "\(-delta) lost to arrows", at: at)
        case .competitorSurpassed(let id):
            let who = name(id) ?? "An outpost"
            record(kind: .outpostCaptured, amount: 1,
                   detail: "\(who) captured", at: at)
        case .competitorRepassed(let id):
            let who = name(id) ?? "An outpost"
            record(kind: .outpostLost, amount: 1,
                   detail: "\(who) retaken by rivals", at: at)
        case .engagementUpdated:
            break
        }
    }

    public mutating func recordDesertion(at: Date = Date()) {
        record(kind: .soldierDeserted, amount: 1,
               detail: "A soldier deserted the camp", at: at)
    }

    /// Aggregate everything at or after `since` into headline counts.
    public func summary(since: Date) -> LedgerSummary {
        var s = LedgerSummary()
        for e in entries where e.at >= since {
            switch e.kind {
            case .recruitsJoined: s.joined += e.amount
            case .soldiersLost: s.lost += e.amount
            case .soldierDeserted: s.deserted += e.amount
            case .outpostCaptured: s.captured += e.amount
            case .outpostLost: s.outpostsLost += e.amount
            }
        }
        return s
    }

    /// Newest-first view of the log.
    public func recent(_ n: Int = 60) -> [LedgerEntry] {
        Array(entries.suffix(n).reversed())
    }

    private mutating func trim() {
        if entries.count > limit {
            entries.removeFirst(entries.count - limit)
        }
    }
}
