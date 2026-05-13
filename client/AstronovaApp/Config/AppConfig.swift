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
        // Debug + Simulator: use production (local server not running)
        #if targetEnvironment(simulator)
        apiBaseURL = "https://astronova.onrender.com"
        #else
        // Debug + Real device: use production (for testing)
        apiBaseURL = "https://astronova.onrender.com"
        #endif
        #else
        // Release: always use production
        apiBaseURL = "https://astronova.onrender.com"
        #endif
    }
}
