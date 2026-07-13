import Foundation

/// Mirror of the JSON returned by `GET /api/v1/ephemeris/topo-substitutions`.
/// Field names match the server contract verbatim so `JSONDecoder` works out
/// of the box.
struct TopoSubstitutions: Codable, Equatable {
    let voidEndTimeIso: String
    let voidEndTime: String
    let aspectPartner: String
    let aspectType: String
    let aspectAngle: String
    let aspectOrbDegrees: Double
    let eclipseDistanceDays: Int
    let computedAtIso: String

    enum CodingKeys: String, CodingKey {
        case voidEndTimeIso = "void_end_time_iso"
        case voidEndTime = "void_end_time"
        case aspectPartner = "aspect_partner"
        case aspectType = "aspect_type"
        case aspectAngle = "aspect_angle"
        case aspectOrbDegrees = "aspect_orb_degrees"
        case eclipseDistanceDays = "eclipse_distance_days"
        case computedAtIso = "computed_at_iso"
    }
}

/// Fetches Swiss-Ephemeris-derived substitution values from the backend
/// once per UTC day, caches them to UserDefaults, and surfaces them to
/// `TerrainComputer.substitute` so the Today screen reads transit-true.
///
/// The synchronous `substitute()` path consults `current` for live values.
/// When the cache is missing/stale a background refresh is kicked off via
/// `refreshIfStale()` — never blocking the UI — and the next render picks
/// up the fresh values. On network failure the caller falls back to the
/// deterministic stubs in TerrainComputer.
final class TopoSubstitutionsService: @unchecked Sendable {
    static let shared = TopoSubstitutionsService()

    private let cacheKey = "topo.substitutions.cache.v1"
    private let dateKeyKey = "topo.substitutions.dateKey.v1"
    private let isoDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private let queue = DispatchQueue(label: "TopoSubstitutionsService", qos: .utility)

    // Access is serialized through `queue`; async fetch tasks only cross the
    // boundary to persist the result and clear this flag back on the queue.
    private var inFlight: Bool = false

    private init() {
        // Trigger a refresh on first access so a freshly-launched app warms
        // the cache without forcing the first Today render to wait.
        refreshIfStale()
    }

    /// Snapshot for today (UTC), or nil if the cache is empty or for a
    /// different UTC day. Callers MUST handle nil by falling back to their
    /// deterministic stubs.
    var current: TopoSubstitutions? {
        let defaults = UserDefaults.standard
        guard
            let cachedKey = defaults.string(forKey: dateKeyKey),
            cachedKey == todayUTCKey,
            let data = defaults.data(forKey: cacheKey),
            let decoded = try? JSONDecoder().decode(TopoSubstitutions.self, from: data)
        else {
            return nil
        }
        return decoded
    }

    /// Kick off a background fetch if today's cache slot is empty.
    /// Idempotent — multiple calls during a single launch coalesce into one
    /// HTTP request via the `inFlight` flag.
    func refreshIfStale(force: Bool = false) {
        queue.async { [weak self] in
            guard let self else { return }
            if !force, self.current != nil { return }
            if self.inFlight { return }
            self.inFlight = true

            Task.detached(priority: .utility) { [weak self] in
                defer { self?.queue.async { self?.inFlight = false } }
                do {
                    let result: TopoSubstitutions = try await NetworkClient.shared.request(
                        endpoint: "/api/v1/ephemeris/topo-substitutions",
                        responseType: TopoSubstitutions.self
                    )
                    self?.persist(result)
                } catch {
                    #if DEBUG
                    debugPrint("[TopoSubstitutions] refresh failed: \(error)")
                    #endif
                    // Swallow — the deterministic stubs in TerrainComputer
                    // remain the fallback and the UI is never blocked.
                }
            }
        }
    }

    /// Synchronous version: returns cached current OR a freshly-fetched value
    /// if available within `timeout` seconds. Used by callers that can afford
    /// a tiny wait on first render (e.g. an explicit pull-to-refresh).
    func awaitCurrent(timeout: TimeInterval = 1.5) -> TopoSubstitutions? {
        if let cached = current { return cached }
        refreshIfStale(force: true)
        // Poll the cache briefly so a fast network catches the first render.
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let cached = current { return cached }
            Thread.sleep(forTimeInterval: 0.05)
        }
        return current
    }

    private var todayUTCKey: String {
        isoDayFormatter.string(from: Date())
    }

    private func persist(_ subs: TopoSubstitutions) {
        guard let data = try? JSONEncoder().encode(subs) else { return }
        let defaults = UserDefaults.standard
        defaults.set(data, forKey: cacheKey)
        defaults.set(todayUTCKey, forKey: dateKeyKey)
    }
}
