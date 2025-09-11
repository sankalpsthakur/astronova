import Foundation

/// RemoteConfig provides simple feature flags and copy variants with a bundled JSON fallback.
final class RemoteConfigService: ObservableObject {
    static let shared = RemoteConfigService()

    private var values: [String: Any] = [:]

    private init() {
        loadFromBundle()
        fetchFromServer()
    }

    private func loadFromBundle() {
        guard let url = Bundle.main.url(forResource: "remote_config", withExtension: "json") else { return }
        do {
            let data = try Data(contentsOf: url)
            if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                values = obj
            }
        } catch {
            // Silently ignore; defaults remain empty
        }
    }

    func bool(forKey key: String, default defaultValue: Bool = false) -> Bool {
        if let override = UserDefaults.standard.object(forKey: "rc_\(key)") as? Bool {
            return override
        }
        return (values[key] as? Bool) ?? defaultValue
    }

    func string(forKey key: String, default defaultValue: String = "") -> String {
        if let override = UserDefaults.standard.string(forKey: "rc_\(key)") { return override }
        return (values[key] as? String) ?? defaultValue
    }

    func number(forKey key: String, default defaultValue: Double = 0) -> Double {
        if let override = UserDefaults.standard.object(forKey: "rc_\(key)") as? Double { return override }
        if let n = values[key] as? NSNumber { return n.doubleValue }
        return defaultValue
    }
    
    // MARK: - Remote Fetch
    private func fetchFromServer() {
        // Fire-and-forget; silently ignore failures
        Task {
            do {
                let data = try await NetworkClient.shared.requestData(
                    endpoint: "/api/v1/config",
                    method: .GET,
                    body: Optional<Data>.none
                )
                if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    await MainActor.run {
                        // Overlay remote values on top of bundled
                        for (k, v) in obj { self.values[k] = v }
                    }
                }
            } catch {
                // No-op: keep bundled config
            }
        }
    }
}
