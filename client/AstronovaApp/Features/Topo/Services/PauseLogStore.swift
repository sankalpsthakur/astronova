import Foundation

struct PauseLogEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let protocolId: String
    let emotion: String
    let planet: String
    let moodBefore: Int
    let moodAfter: Int?
    let bodyLocation: String?
    let routeCondition: String?
    let routeAction: String?
    let committedAction: String?
    let abandonedAtStep: Int?

    var moodDelta: Int? {
        guard let after = moodAfter else { return nil }
        return moodBefore - after
    }
}

@MainActor
final class PauseLogStore: ObservableObject {
    static let shared = PauseLogStore()

    @Published private(set) var entries: [PauseLogEntry] = []

    private let storageKey = "topo.pause.log.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func append(_ entry: PauseLogEntry) {
        entries.append(entry)
        persist()
    }

    func recentCount(emotion: String, within: TimeInterval = 60 * 60 * 24 * 7) -> Int {
        let cutoff = Date().addingTimeInterval(-within)
        return entries.filter { $0.emotion == emotion && $0.timestamp >= cutoff }.count
    }

    func recentEntries(limit: Int = 5) -> [PauseLogEntry] {
        Array(entries.suffix(limit).reversed())
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([PauseLogEntry].self, from: data) {
            self.entries = decoded
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
