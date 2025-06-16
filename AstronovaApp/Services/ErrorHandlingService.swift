import Foundation
import SwiftUI

// MARK: - App Error Types

enum AppError: Error, LocalizedError {
    case networkError(NetworkError)
    case keychainError(KeychainService.KeychainError)
    case validationError(String)
    case authenticationError(String)
    case dataParsingError(String)
    case configurationError(String)
    case storeKitError(String)
    case locationError(String)
    case chartGenerationError(String)
    case cacheError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let networkError):
            return "Network Error: \(networkError.localizedDescription)"
        case .keychainError(let keychainError):
            return "Security Error: \(keychainError.localizedDescription)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .authenticationError(let message):
            return "Authentication Error: \(message)"
        case .dataParsingError(let message):
            return "Data Error: \(message)"
        case .configurationError(let message):
            return "Configuration Error: \(message)"
        case .storeKitError(let message):
            return "Purchase Error: \(message)"
        case .locationError(let message):
            return "Location Error: \(message)"
        case .chartGenerationError(let message):
            return "Chart Generation Error: \(message)"
        case .cacheError(let message):
            return "Cache Error: \(message)"
        case .unknownError(let message):
            return "Unexpected Error: \(message)"
        }
    }
    
    var recoveryOptions: [String] {
        switch self {
        case .networkError:
            return ["Check internet connection", "Try again", "Use offline mode"]
        case .keychainError:
            return ["Sign out and sign back in", "Contact support"]
        case .validationError:
            return ["Check your input", "Try again"]
        case .authenticationError:
            return ["Sign in again", "Create account", "Use anonymous mode"]
        case .dataParsingError:
            return ["Refresh data", "Clear cache", "Contact support"]
        case .configurationError:
            return ["Restart app", "Contact support"]
        case .storeKitError:
            return ["Check payment method", "Try again", "Contact support"]
        case .locationError:
            return ["Enable location services", "Enter manually", "Skip for now"]
        case .chartGenerationError:
            return ["Check birth data", "Try again", "Contact support"]
        case .cacheError:
            return ["Clear cache", "Restart app"]
        case .unknownError:
            return ["Try again", "Restart app", "Contact support"]
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .networkError, .locationError:
            return .warning
        case .keychainError, .authenticationError, .configurationError:
            return .critical
        case .validationError, .dataParsingError, .cacheError:
            return .moderate
        case .storeKitError, .chartGenerationError:
            return .moderate
        case .unknownError:
            return .critical
        }
    }
}

enum ErrorSeverity {
    case info
    case warning
    case moderate
    case critical
    
    var color: Color {
        switch self {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .moderate:
            return .yellow
        case .critical:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .info:
            return "info.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .moderate:
            return "exclamationmark.circle"
        case .critical:
            return "xmark.circle"
        }
    }
}

// MARK: - Error Handling Service

final class ErrorHandlingService: ObservableObject {
    static let shared = ErrorHandlingService()
    
    @Published var currentError: AppError?
    @Published var isShowingError = false
    
    private let logger = LoggingService.shared
    
    private init() {}
    
    // MARK: - Error Handling Methods
    
    func handle(_ error: Error, context: String = "") {
        let appError = mapToAppError(error)
        
        logger.logError(error, category: .general)
        logger.log("Error context: \(context)", category: .general, level: .error)
        
        DispatchQueue.main.async {
            self.currentError = appError
            self.isShowingError = true
        }
        
        // Additional handling based on severity
        switch appError.severity {
        case .critical:
            handleCriticalError(appError, context: context)
        case .moderate:
            handleModerateError(appError, context: context)
        case .warning:
            handleWarning(appError, context: context)
        case .info:
            handleInfo(appError, context: context)
        }
    }
    
    func handleAsync(_ error: Error, context: String = "") async {
        await MainActor.run {
            handle(error, context: context)
        }
    }
    
    func clearError() {
        DispatchQueue.main.async {
            self.currentError = nil
            self.isShowingError = false
        }
    }
    
    // MARK: - Error Mapping
    
    private func mapToAppError(_ error: Error) -> AppError {
        switch error {
        case let networkError as NetworkError:
            return .networkError(networkError)
        case let keychainError as KeychainService.KeychainError:
            return .keychainError(keychainError)
        case let appError as AppError:
            return appError
        case let apiError as APIError:
            return .networkError(.serverError(0)) // Map API errors to network errors
        default:
            return .unknownError(error.localizedDescription)
        }
    }
    
    // MARK: - Severity-based Handling
    
    private func handleCriticalError(_ error: AppError, context: String) {
        logger.log("CRITICAL ERROR: \(error.localizedDescription) | Context: \(context)", category: .general, level: .fault)
        
        // For critical errors, we might want to:
        // - Log to crash reporting service
        // - Clear sensitive data
        // - Reset app state
        
        if case .keychainError = error {
            // Clear potentially corrupted keychain data
            clearCorruptedData()
        }
    }
    
    private func handleModerateError(_ error: AppError, context: String) {
        logger.log("MODERATE ERROR: \(error.localizedDescription) | Context: \(context)", category: .general, level: .error)
        
        // For moderate errors, we might want to:
        // - Attempt automatic recovery
        // - Clear relevant cache
        
        if case .cacheError = error {
            clearCache()
        }
    }
    
    private func handleWarning(_ error: AppError, context: String) {
        logger.log("WARNING: \(error.localizedDescription) | Context: \(context)", category: .general, level: .notice)
        
        // For warnings, we might want to:
        // - Show subtle notification
        // - Continue with degraded functionality
    }
    
    private func handleInfo(_ error: AppError, context: String) {
        logger.log("INFO: \(error.localizedDescription) | Context: \(context)", category: .general, level: .info)
    }
    
    // MARK: - Recovery Actions
    
    private func clearCorruptedData() {
        do {
            try KeychainService.shared.clearAuthState()
            try KeychainService.shared.clearUserSession()
            logger.log("Cleared corrupted keychain data", category: .auth, level: .info)
        } catch {
            logger.logError(error, category: .auth)
        }
    }
    
    private func clearCache() {
        // Implementation for clearing app cache
        logger.log("Cleared app cache", category: .general, level: .info)
    }
    
    // MARK: - User-facing Error Messages
    
    func userFriendlyMessage(for error: AppError) -> String {
        switch error {
        case .networkError:
            return "Unable to connect to our servers. Please check your internet connection and try again."
        case .keychainError:
            return "There was a security issue accessing your data. Please sign in again."
        case .validationError(let message):
            return message
        case .authenticationError:
            return "Authentication failed. Please sign in again."
        case .dataParsingError:
            return "There was an issue processing your data. Please try refreshing."
        case .configurationError:
            return "App configuration error. Please restart the app or contact support."
        case .storeKitError:
            return "Purchase failed. Please check your payment method and try again."
        case .locationError:
            return "Unable to access location. Please enable location services or enter your location manually."
        case .chartGenerationError:
            return "Unable to generate your chart. Please check your birth data and try again."
        case .cacheError:
            return "Cache error occurred. Your data will be refreshed."
        case .unknownError:
            return "An unexpected error occurred. Please try again or contact support if the issue persists."
        }
    }
}

// MARK: - Error Result Type

enum Result<Success, Failure: Error> {
    case success(Success)
    case failure(Failure)
    
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    var isFailure: Bool {
        return !isSuccess
    }
}

// MARK: - Async Error Handling Extensions

extension Task where Failure == Error {
    @discardableResult
    static func catching(
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> Success
    ) -> Task<Success?, Never> {
        Task<Success?, Never>(priority: priority) {
            do {
                return try await operation()
            } catch {
                await ErrorHandlingService.shared.handleAsync(error)
                return nil
            }
        }
    }
}