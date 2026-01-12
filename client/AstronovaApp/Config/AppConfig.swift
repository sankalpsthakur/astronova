import Foundation

/// Centralized app configuration for environment-specific values
final class AppConfig {
    static let shared = AppConfig()

    /// Base URL for the backend API
    let apiBaseURL: String

    private init() {
        if let fromPlist = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           !fromPlist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            apiBaseURL = fromPlist
            return
        }

        #if DEBUG
        // Debug + Simulator: use localhost
        #if targetEnvironment(simulator)
        apiBaseURL = "http://127.0.0.1:8080"
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
