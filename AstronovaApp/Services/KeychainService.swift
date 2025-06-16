import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    private let serviceName = "com.astronova.app"
    
    enum KeychainError: Error, LocalizedError {
        case noData
        case unhandledError(status: OSStatus)
        case encodingError
        case decodingError
        
        var errorDescription: String? {
            switch self {
            case .noData:
                return "No data found in keychain"
            case .unhandledError(let status):
                return "Keychain error: \(status)"
            case .encodingError:
                return "Failed to encode data for keychain"
            case .decodingError:
                return "Failed to decode data from keychain"
            }
        }
    }
    
    // MARK: - Generic Methods
    
    func save<T: Codable>(_ item: T, for key: String) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(item)
        } catch {
            LoggingService.shared.logError(error, category: .auth)
            throw KeychainError.encodingError
        }
        
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecAttrService: serviceName,
            kSecValueData: data
        ] as CFDictionary
        
        // Delete any existing item
        SecItemDelete(query)
        
        // Add new item
        let status = SecItemAdd(query, nil)
        guard status == errSecSuccess else {
            LoggingService.shared.log("Keychain save failed for key: \(key), status: \(status)", category: .auth, level: .error)
            throw KeychainError.unhandledError(status: status)
        }
        
        LoggingService.shared.log("Successfully saved item to keychain for key: \(key)", category: .auth, level: .debug)
    }
    
    func load<T: Codable>(_ type: T.Type, for key: String) throws -> T {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecAttrService: serviceName,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query, &dataTypeRef)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.noData
            } else {
                LoggingService.shared.log("Keychain load failed for key: \(key), status: \(status)", category: .auth, level: .error)
                throw KeychainError.unhandledError(status: status)
            }
        }
        
        guard let data = dataTypeRef as? Data else {
            throw KeychainError.noData
        }
        
        do {
            let item = try JSONDecoder().decode(type, from: data)
            LoggingService.shared.log("Successfully loaded item from keychain for key: \(key)", category: .auth, level: .debug)
            return item
        } catch {
            LoggingService.shared.logError(error, category: .auth)
            throw KeychainError.decodingError
        }
    }
    
    func delete(for key: String) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecAttrService: serviceName
        ] as CFDictionary
        
        let status = SecItemDelete(query)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            LoggingService.shared.log("Keychain delete failed for key: \(key), status: \(status)", category: .auth, level: .error)
            throw KeychainError.unhandledError(status: status)
        }
        
        LoggingService.shared.log("Successfully deleted item from keychain for key: \(key)", category: .auth, level: .debug)
    }
    
    func exists(for key: String) -> Bool {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecAttrService: serviceName,
            kSecReturnData: false,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        
        let status = SecItemCopyMatching(query, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Convenience Methods for App-Specific Data
    
    private enum Keys {
        static let authState = "auth_state"
        static let userSession = "user_session"
        static let apiTokens = "api_tokens"
        static let userCredentials = "user_credentials"
    }
    
    func saveAuthState(isSignedIn: Bool, isAnonymousUser: Bool) throws {
        let authData = AuthKeychainData(
            isSignedIn: isSignedIn,
            isAnonymousUser: isAnonymousUser,
            lastUpdated: Date()
        )
        try save(authData, for: Keys.authState)
    }
    
    func loadAuthState() -> (isSignedIn: Bool, isAnonymousUser: Bool)? {
        do {
            let authData = try load(AuthKeychainData.self, for: Keys.authState)
            return (authData.isSignedIn, authData.isAnonymousUser)
        } catch {
            LoggingService.shared.log("No auth state found in keychain: \(error)", category: .auth, level: .debug)
            return nil
        }
    }
    
    func clearAuthState() throws {
        try delete(for: Keys.authState)
    }
    
    func saveUserSession(_ sessionData: Data) throws {
        try save(sessionData, for: Keys.userSession)
    }
    
    func loadUserSession() -> Data? {
        do {
            return try load(Data.self, for: Keys.userSession)
        } catch {
            LoggingService.shared.log("No user session found in keychain: \(error)", category: .auth, level: .debug)
            return nil
        }
    }
    
    func clearUserSession() throws {
        try delete(for: Keys.userSession)
    }
}

// MARK: - Data Models for Keychain Storage

private struct AuthKeychainData: Codable {
    let isSignedIn: Bool
    let isAnonymousUser: Bool
    let lastUpdated: Date
}