import Foundation
import Combine

@MainActor
final class JournalStore: ObservableObject {
    static let shared = JournalStore()

    @Published private(set) var entries: [JournalEntry] = []

    private let storageKey = "topo.journal.entries.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func add(_ entry: JournalEntry) {
        entries.append(entry)
        persist()
    }

    func update(_ entry: JournalEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[idx] = entry
        persist()
    }

    func delete(_ id: UUID) {
        entries.removeAll { $0.id == id }
        persist()
    }

    func entries(forPatternId patternId: String) -> [JournalEntry] {
        entries.filter { $0.patternId == patternId }
    }

    func recent(limit: Int = 30) -> [JournalEntry] {
        Array(entries.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([JournalEntry].self, from: data) {
            self.entries = decoded
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(entries) {
            defaults.set(data, forKey: storageKey)
        }
    }
}

@MainActor
final class DecisionStore: ObservableObject {
    static let shared = DecisionStore()

    @Published private(set) var decisions: [Decision] = []

    private let storageKey = "topo.decisions.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func add(_ decision: Decision) {
        decisions.append(decision)
        persist()
    }

    func update(_ decision: Decision) {
        guard let idx = decisions.firstIndex(where: { $0.id == decision.id }) else { return }
        decisions[idx] = decision
        persist()
    }

    func recent(limit: Int = 10) -> [Decision] {
        Array(decisions.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Decision].self, from: data) {
            self.decisions = decoded
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(decisions) {
            defaults.set(data, forKey: storageKey)
        }
    }
}

@MainActor
final class NavigationRuleStore: ObservableObject {
    static let shared = NavigationRuleStore()

    @Published private(set) var rules: [NavigationRule] = []

    private let storageKey = "topo.nav.rules.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func add(_ rule: NavigationRule) {
        rules.append(rule)
        persist()
    }

    func update(_ rule: NavigationRule) {
        guard let idx = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[idx] = rule
        persist()
    }

    func delete(_ id: UUID) {
        rules.removeAll { $0.id == id }
        persist()
    }

    func toggleActive(_ id: UUID) {
        guard let idx = rules.firstIndex(where: { $0.id == id }) else { return }
        rules[idx].active.toggle()
        persist()
    }

    var activeRules: [NavigationRule] { rules.filter(\.active) }

    func rules(forContext context: NavigationRule.TriggerContext) -> [NavigationRule] {
        activeRules.filter { $0.triggerContext == context || $0.triggerContext == .generic }
    }

    func rules(forPatternId patternId: String) -> [NavigationRule] {
        activeRules.filter { $0.triggerPatternId == patternId }
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([NavigationRule].self, from: data) {
            self.rules = decoded
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(rules) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
