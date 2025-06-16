import Foundation

protocol ConfigurationProtocol {
    var baseURL: String { get }
    var timeout: TimeInterval { get }
    var environment: AppEnvironment { get }
    var isDebugMode: Bool { get }
}

enum AppEnvironment: String, CaseIterable {
    case development = "development"
    case staging = "staging"
    case production = "production"
    
    var displayName: String {
        switch self {
        case .development:
            return "Development"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        }
    }
}

final class ConfigurationService: ConfigurationProtocol {
    static let shared = ConfigurationService()
    
    let environment: AppEnvironment
    let isDebugMode: Bool
    
    private init() {
        #if DEBUG
        self.environment = .development
        self.isDebugMode = true
        #else
        self.environment = .production
        self.isDebugMode = false
        #endif
        
        LoggingService.shared.log("Initialized configuration for \(environment.displayName) environment", category: .general, level: .info)
    }
    
    var baseURL: String {
        switch environment {
        case .development:
            return "http://127.0.0.1:8080"
        case .staging:
            return "https://staging-api.astronova.app"
        case .production:
            return "https://api.astronova.app"
        }
    }
    
    var timeout: TimeInterval {
        switch environment {
        case .development:
            return 30.0
        case .staging:
            return 30.0
        case .production:
            return 15.0
        }
    }
    
    // MARK: - Feature Flags
    
    var isAnalyticsEnabled: Bool {
        switch environment {
        case .development:
            return false
        case .staging:
            return true
        case .production:
            return true
        }
    }
    
    var isCrashReportingEnabled: Bool {
        switch environment {
        case .development:
            return false
        case .staging:
            return true
        case .production:
            return true
        }
    }
    
    var isLoggingEnabled: Bool {
        return true // Always enabled for debugging
    }
    
    var maxRetryAttempts: Int {
        switch environment {
        case .development:
            return 3
        case .staging:
            return 3
        case .production:
            return 2
        }
    }
    
    // MARK: - API Configuration
    
    var apiVersion: String {
        return "v1"
    }
    
    var maxCacheSize: Int {
        switch environment {
        case .development:
            return 50 * 1024 * 1024 // 50MB
        case .staging:
            return 100 * 1024 * 1024 // 100MB
        case .production:
            return 100 * 1024 * 1024 // 100MB
        }
    }
    
    // MARK: - App Store Configuration
    
    var storeKitProductIDs: [String] {
        switch environment {
        case .development:
            return ["dev.astronova.premium.monthly", "dev.astronova.premium.yearly"]
        case .staging:
            return ["staging.astronova.premium.monthly", "staging.astronova.premium.yearly"]
        case .production:
            return ["astronova.premium.monthly", "astronova.premium.yearly"]
        }
    }
    
    // MARK: - Debugging Configuration
    
    var shouldLogNetworkRequests: Bool {
        return isDebugMode
    }
    
    var shouldMockNetworkRequests: Bool {
        return false // Can be overridden for testing
    }
    
    // MARK: - UI Configuration
    
    var animationDuration: TimeInterval {
        return isDebugMode ? 0.1 : 0.3 // Faster animations in debug
    }
    
    var shouldShowDebugInfo: Bool {
        return isDebugMode
    }
}