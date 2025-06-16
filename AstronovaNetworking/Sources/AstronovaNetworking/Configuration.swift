import Foundation

/// Configuration service for reading app settings from Environment.plist
public struct Configuration {
    private static nonisolated(unsafe) let environmentPlist: [String: Any] = {
        guard let path = Bundle.main.path(forResource: "Environment", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("Warning: Environment.plist not found, using fallback values")
            return [:]
        }
        return plist
    }()
    
    /// API Base URL for network requests
    public static var apiBaseURL: String {
        if let urlString = environmentPlist["API_BASE_URL"] as? String, !urlString.isEmpty {
            return urlString
        }
        
        // Fallback based on bundle identifier
        if let bundleId = Bundle.main.bundleIdentifier, bundleId.contains(".dev") {
            return "http://127.0.0.1:8080"
        } else {
            return "https://api.astronova.app"
        }
    }
    
    /// Current environment (Debug/Release)
    public static var environment: String {
        return environmentPlist["ENVIRONMENT"] as? String ?? "Unknown"
    }
    
    /// App version
    public static var appVersion: String {
        return environmentPlist["APP_VERSION"] as? String ?? "Unknown"
    }
    
    /// Build number
    public static var buildNumber: String {
        return environmentPlist["BUILD_NUMBER"] as? String ?? "Unknown"
    }
    
    /// Is this a development/debug build?
    public static var isDevelopment: Bool {
        return environment.lowercased() == "debug" || 
               Bundle.main.bundleIdentifier?.contains(".dev") == true
    }
}