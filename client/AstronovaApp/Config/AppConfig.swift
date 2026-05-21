import Foundation

/// Centralized app configuration for environment-specific values
final class AppConfig {
    static let shared = AppConfig()

    /// Base URL for the backend API
    let apiBaseURL: String
    let secureEnvelopeAlgorithm: String
    let secureEnvelopeVersion: Int

    private init() {
        secureEnvelopeAlgorithm = Bundle.main.object(forInfoDictionaryKey: "SECURE_ENVELOPE_ALGORITHM") as? String
            ?? SecureEnvelope.currentAlgorithm
        secureEnvelopeVersion = Bundle.main.object(forInfoDictionaryKey: "SECURE_ENVELOPE_VERSION") as? Int
            ?? SecureEnvelope.currentVersion

        if let fromPlist = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           !fromPlist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            apiBaseURL = fromPlist
            return
        }

        #if DEBUG
        // Debug + Simulator: opt in to local backend by setting
        // ASTRONOVA_LOCAL_BACKEND=1 (or =http://host:port) in the scheme env.
        // Defaults to production so TestFlight-style audits Just Work.
        #if targetEnvironment(simulator)
        let env = ProcessInfo.processInfo.environment["ASTRONOVA_LOCAL_BACKEND"]
        if let env, !env.isEmpty {
            if env.lowercased().hasPrefix("http") {
                apiBaseURL = env
            } else {
                // 1/true/yes → default localhost on port 8081 (8080 frequently
                // taken by other dev services).
                apiBaseURL = "http://127.0.0.1:8081"
            }
        } else {
            apiBaseURL = "https://astronova-ghcr.onrender.com"
        }
        #else
        // Debug + Real device: use production (for testing)
        apiBaseURL = "https://astronova-ghcr.onrender.com"
        #endif
        #else
        // Release: always use production
        apiBaseURL = "https://astronova-ghcr.onrender.com"
        #endif
    }
}
