import Foundation
import os

// MARK: - AstronovaFlags
//
// Local feature-flag service. Wraps the planned `IOSAppsFlags` SPM package
// (Wave 13 agent 7) so callsites can be wired now and only the internals swap
// out when the package lands.
//
// Defaults are shipped in-app for offline / first-launch fallback. The
// resolver fetches the live config on launch (best-effort, non-blocking) and
// caches it for subsequent reads. Persistent cache survives app restart so
// even the very first read after kill returns the last known good value.
//
// Flags are READ-ONLY from the app side. The remote source of truth is the
// `iosapps-flags` service planned to live alongside the analytics server.

public enum AstronovaPaywallVariant: String, CaseIterable {
    case `default` = "default"
    case tieredV1 = "tiered_v1"
    case tieredV2 = "tiered_v2"
}

public enum AstronovaOracleModel: String, CaseIterable {
    case haiku = "haiku"
    case sonnet = "sonnet"
    case sonnetThinking = "sonnet-thinking"
}

/// Singleton flag registry. Same API the IOSAppsFlags package will expose.
public final class AstronovaFlags: ObservableObject {
    public static let shared = AstronovaFlags()

    private let logger = Logger(subsystem: "com.astronova.app", category: "flags")
    private let cacheKey = "astronova_flags_cache_v1"
    private let queue = DispatchQueue(label: "com.astronova.flags", qos: .utility)

    /// Cached values. Default values must always be safe to ship offline.
    @Published private(set) var paywallVariant: AstronovaPaywallVariant = .default
    @Published private(set) var oracleModel: AstronovaOracleModel = .sonnet
    @Published private(set) var cosmicDiaryEnabled: Bool = false
    @Published private(set) var giftAReadingEnabled: Bool = false

    /// Endpoint set on configure(). When nil, only baked-in defaults are used.
    private var endpoint: URL?

    private init() {
        loadCachedFlags()
    }

    public func configure(endpoint: URL?) {
        self.endpoint = endpoint
        refresh()
    }

    /// Re-fetch flags from remote. Best-effort, never blocks the caller.
    /// In DEBUG builds this is a no-op so dev work is deterministic.
    public func refresh(completion: ((Bool) -> Void)? = nil) {
        #if DEBUG
        completion?(false)
        return
        #else
        guard let endpoint = endpoint else {
            completion?(false)
            return
        }
        URLSession.shared.dataTask(with: endpoint) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else {
                completion?(false)
                return
            }
            guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion?(false)
                return
            }
            DispatchQueue.main.async {
                self.apply(dict)
                self.persist(dict)
                completion?(true)
            }
        }.resume()
        #endif
    }

    // MARK: - Test seam

    func _overrideForTests(
        paywallVariant: AstronovaPaywallVariant? = nil,
        oracleModel: AstronovaOracleModel? = nil,
        cosmicDiaryEnabled: Bool? = nil,
        giftAReadingEnabled: Bool? = nil
    ) {
        if let v = paywallVariant { self.paywallVariant = v }
        if let m = oracleModel { self.oracleModel = m }
        if let c = cosmicDiaryEnabled { self.cosmicDiaryEnabled = c }
        if let g = giftAReadingEnabled { self.giftAReadingEnabled = g }
    }

    /// Reset to defaults — for tests.
    func _resetForTests() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        paywallVariant = .default
        oracleModel = .sonnet
        cosmicDiaryEnabled = false
        giftAReadingEnabled = false
    }

    // MARK: - Internal

    private func apply(_ dict: [String: Any]) {
        if let raw = dict["paywall_variant"] as? String,
           let v = AstronovaPaywallVariant(rawValue: raw) {
            paywallVariant = v
        }
        if let raw = dict["oracle_model"] as? String,
           let m = AstronovaOracleModel(rawValue: raw) {
            oracleModel = m
        }
        if let v = dict["cosmic_diary_enabled"] as? Bool {
            cosmicDiaryEnabled = v
        }
        if let v = dict["gift_a_reading_enabled"] as? Bool {
            giftAReadingEnabled = v
        }
    }

    private func persist(_ dict: [String: Any]) {
        UserDefaults.standard.set(dict, forKey: cacheKey)
    }

    private func loadCachedFlags() {
        guard let dict = UserDefaults.standard.dictionary(forKey: cacheKey) else { return }
        apply(dict)
    }
}
