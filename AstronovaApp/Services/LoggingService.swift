import Foundation
import OSLog

final class LoggingService {
    static let shared = LoggingService()
    
    private let networkLogger = Logger(subsystem: "com.astronova.app", category: "networking")
    private let authLogger = Logger(subsystem: "com.astronova.app", category: "authentication")
    private let uiLogger = Logger(subsystem: "com.astronova.app", category: "ui")
    private let storeKitLogger = Logger(subsystem: "com.astronova.app", category: "storekit")
    private let generalLogger = Logger(subsystem: "com.astronova.app", category: "general")
    
    private init() {}
    
    enum Category {
        case network
        case auth
        case ui
        case storeKit
        case general
    }
    
    enum Level {
        case debug
        case info
        case notice
        case error
        case fault
    }
    
    func log(_ message: String, category: Category = .general, level: Level = .info) {
        let logger = self.logger(for: category)
        
        switch level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .notice:
            logger.notice("\(message)")
        case .error:
            logger.error("\(message)")
        case .fault:
            logger.fault("\(message)")
        }
    }
    
    private func logger(for category: Category) -> Logger {
        switch category {
        case .network:
            return networkLogger
        case .auth:
            return authLogger
        case .ui:
            return uiLogger
        case .storeKit:
            return storeKitLogger
        case .general:
            return generalLogger
        }
    }
}

extension LoggingService {
    func logNetworkRequest(_ request: URLRequest) {
        log("Network Request: \(request.httpMethod ?? "Unknown") \(request.url?.absoluteString ?? "Unknown URL")", category: .network, level: .debug)
    }
    
    func logNetworkResponse(_ response: URLResponse?, data: Data?) {
        if let httpResponse = response as? HTTPURLResponse {
            log("Network Response: \(httpResponse.statusCode) - \(data?.count ?? 0) bytes", category: .network, level: .debug)
        }
    }
    
    func logError(_ error: Error, category: Category = .general) {
        log("Error: \(error.localizedDescription)", category: category, level: .error)
    }
    
    func logAuthEvent(_ event: String) {
        log("Auth Event: \(event)", category: .auth, level: .info)
    }
    
    func logStoreKitEvent(_ event: String) {
        log("StoreKit Event: \(event)", category: .storeKit, level: .info)
    }
}