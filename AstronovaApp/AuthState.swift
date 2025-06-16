import SwiftUI
import OSLog
import Security

// MARK: - Simple Services for AuthState

private let authLogger = Logger(subsystem: "com.astronova.app", category: "authentication")

// Simple KeychainService for AuthState
class KeychainService {
    static let shared = KeychainService()
    private init() {}
    
    private let serviceName = "com.astronova.app"
    
    enum KeychainError: Error {
        case noData
        case unhandledError(status: OSStatus)
        case encodingError
        case decodingError
    }
    
    struct AuthState: Codable {
        let isSignedIn: Bool
        let isAnonymousUser: Bool
    }
    
    func saveAuthState(isSignedIn: Bool, isAnonymousUser: Bool) throws {
        let authState = AuthState(isSignedIn: isSignedIn, isAnonymousUser: isAnonymousUser)
        let data = try JSONEncoder().encode(authState)
        
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: "auth_state",
            kSecAttrService: serviceName,
            kSecValueData: data
        ] as CFDictionary
        
        SecItemDelete(query)
        let status = SecItemAdd(query, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func loadAuthState() -> AuthState? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: "auth_state",
            kSecAttrService: serviceName,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let authState = try? JSONDecoder().decode(AuthState.self, from: data) else {
            return nil
        }
        
        return authState
    }
    
    func clearAuthState() throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: "auth_state",
            kSecAttrService: serviceName
        ] as CFDictionary
        
        let status = SecItemDelete(query)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func clearUserSession() throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: "user_session",
            kSecAttrService: serviceName
        ] as CFDictionary
        
        let status = SecItemDelete(query)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}

enum AuthenticationState {
    case loading
    case signedOut
    case needsProfileSetup
    case signedIn
}

class AuthState: ObservableObject {
    @Published var state: AuthenticationState = .loading
    @Published var profileManager = UserProfileManager()
    @Published var isAPIConnected = false
    @Published var connectionError: String?
    @Published var isAnonymousUser = false
    @Published private var hasSignedIn = false
    
    private let keychainService = KeychainService.shared
    
    private let apiServices = APIServices.shared
    
    init() {
        loadAuthStateFromKeychain()
        checkAuthState()
    }
    
    private func loadAuthStateFromKeychain() {
        if let authState = keychainService.loadAuthState() {
            hasSignedIn = authState.isSignedIn
            isAnonymousUser = authState.isAnonymousUser
            authLogger.info("Loaded auth state from keychain - signed in: \(self.hasSignedIn), anonymous: \(self.isAnonymousUser)")
        } else {
            authLogger.info("No auth state found in keychain, using defaults")
        }
    }
    
    private func saveAuthStateToKeychain() {
        do {
            try keychainService.saveAuthState(isSignedIn: hasSignedIn, isAnonymousUser: isAnonymousUser)
            authLogger.info("Saved auth state to keychain")
        } catch {
            authLogger.error("Auth keychain save error: \(error.localizedDescription)")
        }
    }
    
    private func checkAuthState() {
        // Check if user is signed in and has complete profile
        
        // Check API connectivity in background
        Task {
            await checkAPIConnectivity()
        }
        
        if hasSignedIn {
            if profileManager.isProfileComplete {
                state = .signedIn
            } else {
                // For anonymous users, allow them to use the app even without complete profile
                if isAnonymousUser {
                    state = .signedIn
                } else {
                    state = .needsProfileSetup
                }
            }
        } else {
            state = .signedOut
        }
    }
    
    /// Check API connectivity and update status
    func checkAPIConnectivity() async {
        do {
            let health = try await apiServices.healthCheck()
            await MainActor.run {
                self.isAPIConnected = health.status == "ok"
                self.connectionError = nil
            }
        } catch {
            await MainActor.run {
                self.isAPIConnected = false
                self.connectionError = error.localizedDescription
            }
            authLogger.error("Network error: \(error.localizedDescription)")
        }
    }
    
    func requestSignIn() async {
        await MainActor.run {
            state = .loading
        }
        
        // Check API connectivity first
        await checkAPIConnectivity()
        
        let apiConnected = await MainActor.run { self.isAPIConnected }
        if !apiConnected {
            // Still allow offline functionality
            authLogger.notice("API not connected, proceeding with offline mode")
        }
        
        // Simulate sign-in process - in production this would integrate with authentication provider
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await MainActor.run {
            hasSignedIn = true
            saveAuthStateToKeychain()
            if profileManager.isProfileComplete {
                state = .signedIn
                
                // Generate chart if connected to API and no cached chart exists
                if isAPIConnected && profileManager.lastChart == nil {
                    Task {
                        await profileManager.generateChart()
                    }
                }
            } else {
                state = .needsProfileSetup
            }
        }
    }
    
    func completeProfileSetup() async {
        do {
            try profileManager.saveProfile()
            
            // Generate initial chart if API is connected
            if isAPIConnected {
                await profileManager.generateChart()
            }
            
            await MainActor.run {
                state = .signedIn
            }
        } catch {
            authLogger.error("Auth keychain save error: \(error.localizedDescription)")
            await MainActor.run {
                // Still transition to signedIn state as profile data is in memory
                state = .signedIn
            }
        }
    }
    
    /// Complete profile setup synchronously (for SwiftUI binding)
    func completeProfileSetup() {
        Task {
            await completeProfileSetup()
        }
    }
    
    func signOut() {
        hasSignedIn = false
        isAnonymousUser = false
        profileManager = UserProfileManager() // Reset profile
        isAPIConnected = false
        connectionError = nil
        state = .signedOut
        
        // Clear keychain data
        do {
            try keychainService.clearAuthState()
            try keychainService.clearUserSession()
            authLogger.info("Cleared auth data from keychain on sign out")
        } catch {
            authLogger.error("Auth keychain save error: \(error.localizedDescription)")
        }
    }
    
    /// Refresh user data and chart from API
    func refreshUserData() async {
        guard isAPIConnected else { return }
        
        await profileManager.generateChart()
    }
    
    /// Get status message for UI display
    var statusMessage: String {
        if isAPIConnected {
            return "Connected to AstroNova services"
        } else if let error = connectionError {
            return "Offline mode: \(error)"
        } else {
            return "Checking connection..."
        }
    }
    
    /// Whether the app can provide full functionality
    var hasFullFunctionality: Bool {
        return isAPIConnected && profileManager.isProfileComplete && profileManager.hasCompleteLocationData
    }
    
    /// Whether user has premium features (signed-in users only)
    var hasPremiumFeatures: Bool {
        return !isAnonymousUser && hasFullFunctionality
    }
    
    /// Whether user can access basic features
    var hasBasicFeatures: Bool {
        return profileManager.isProfileComplete
    }
}