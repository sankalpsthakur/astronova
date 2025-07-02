import SwiftUI
import AuthenticationServices
import CryptoKit
import Foundation
import Security

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
    @Published var jwtToken: String?
    @Published var authenticatedUser: AuthenticatedUser?
    @Published var authError: String?
    @Published var isRetryingConnection = false
    
    @AppStorage("is_anonymous_user") var isAnonymousUser = false
    @AppStorage("has_signed_in") private var hasSignedIn = false
    @AppStorage("is_quick_start_user") var isQuickStartUser = false
    
    private let apiServices = APIServices.shared
    private let jwtTokenKey = "com.sankalp.AstronovaApp.jwtToken"
    
    // MARK: - Keychain Helper Methods
    
    private func storeJWTToken(_ token: String) {
        let data = Data(token.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: jwtTokenKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Failed to store JWT token in Keychain: \(status)")
        }
    }
    
    private func getJWTToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: jwtTokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    private func deleteJWTToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: jwtTokenKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Failed to delete JWT token from Keychain: \(status)")
        }
    }
    
    // Generate nonce for Apple Sign-In security
    private(set) var nonce: String = {
        let uuid = UUID().uuidString
        let data = Data(uuid.utf8)
        return SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }()
    
    init() {
        // Set up token expiry callback
        apiServices.onTokenExpired = { [weak self] in
            await self?.handleTokenExpiry()
        }
        
        // Initialize state immediately for fast boot
        initializeStateImmediately()
        
        // Perform background checks without blocking UI
        Task {
            await performBackgroundInitialization()
        }
    }
    
    private func initializeStateImmediately() {
        // Quick local state determination - no network calls
        if let storedToken = getJWTToken() {
            jwtToken = storedToken
            hasSignedIn = true
        }
        
        // Set initial state based on stored data only
        if hasSignedIn {
            if profileManager.isProfileComplete {
                state = .signedIn
            } else {
                if isAnonymousUser || isQuickStartUser || profileManager.hasMinimalProfileData {
                    state = .signedIn
                } else {
                    state = .needsProfileSetup
                }
            }
        } else {
            state = .signedOut
        }
    }
    
    private func performBackgroundInitialization() async {
        // Perform network operations in background
        await checkAPIConnectivity()
        
        // Validate stored token if we have one
        if jwtToken != nil {
            await validateStoredToken()
        }
    }
    
    /// Check API connectivity and update status
    func checkAPIConnectivity() async {
        do {
            let health = try await apiServices.healthCheck()
            await MainActor.run {
                self.isAPIConnected = health.status == "ok"
                self.connectionError = nil
                self.isRetryingConnection = false
            }
        } catch {
            await MainActor.run {
                self.isAPIConnected = false
                self.isRetryingConnection = false
                
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .offline:
                        self.connectionError = "Offline mode - some features may be limited"
                    case .timeout:
                        self.connectionError = "Connection timeout - check your internet"
                    case .serverError(let code, _):
                        self.connectionError = "Server issue (\(code)) - please try again later"
                    default:
                        self.connectionError = networkError.localizedDescription
                    }
                } else {
                    self.connectionError = error.localizedDescription
                }
            }
            print("API connectivity check failed: \(error)")
        }
    }
    
    /// Retry API connection with exponential backoff
    func retryConnection() async {
        guard !isRetryingConnection else { return }
        
        await MainActor.run {
            self.isRetryingConnection = true
        }
        
        // Simple retry with delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        await checkAPIConnectivity()
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
            print("API not connected, proceeding with offline mode")
        }
        
        // Simulate sign-in process - in production this would integrate with authentication provider
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await MainActor.run {
            hasSignedIn = true
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
            print("Failed to save profile during setup completion: \(error)")
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
        // Clear stored authentication
        jwtToken = nil
        authenticatedUser = nil as AuthenticatedUser?
        deleteJWTToken()
        
        hasSignedIn = false
        isAnonymousUser = false
        profileManager = UserProfileManager() // Reset profile
        isAPIConnected = false
        connectionError = nil
        state = .signedOut
        
        // Notify backend of logout
        Task {
            try? await apiServices.logout()
        }
    }
    
    func continueAsGuest() {
        // Clear any auth errors
        authError = nil
        
        isAnonymousUser = true
        hasSignedIn = true
        
        // Check API connectivity for guest users
        Task {
            await checkAPIConnectivity()
        }
        
        state = (profileManager.isProfileComplete || profileManager.hasMinimalProfileData) ? .signedIn : .needsProfileSetup
    }
    
    func startQuickStart() {
        // Clear any auth errors
        authError = nil
        
        isQuickStartUser = true
        hasSignedIn = true
        
        // Check API connectivity for quick start users
        Task {
            await checkAPIConnectivity()
        }
        
        state = .needsProfileSetup
    }
    
    /// Get feature availability for current user type
    var featureAvailability: FeatureAvailability {
        if isAnonymousUser {
            return FeatureAvailability(
                canGenerateCharts: isAPIConnected,
                canSaveData: false,
                canAccessPremiumFeatures: false,
                canSyncAcrossDevices: false,
                hasUnlimitedAccess: false,
                maxChartsPerDay: isAPIConnected ? 3 : 1
            )
        } else if isQuickStartUser {
            return FeatureAvailability(
                canGenerateCharts: isAPIConnected,
                canSaveData: false,
                canAccessPremiumFeatures: false,
                canSyncAcrossDevices: false,
                hasUnlimitedAccess: false,
                maxChartsPerDay: isAPIConnected ? 5 : 2
            )
        } else if hasSignedIn && jwtToken != nil {
            return FeatureAvailability(
                canGenerateCharts: isAPIConnected,
                canSaveData: isAPIConnected,
                canAccessPremiumFeatures: isAPIConnected,
                canSyncAcrossDevices: isAPIConnected,
                hasUnlimitedAccess: true,
                maxChartsPerDay: nil
            )
        } else {
            return FeatureAvailability(
                canGenerateCharts: false,
                canSaveData: false,
                canAccessPremiumFeatures: false,
                canSyncAcrossDevices: false,
                hasUnlimitedAccess: false,
                maxChartsPerDay: 0
            )
        }
    }
}

/// Feature availability for different user types
struct FeatureAvailability {
    let canGenerateCharts: Bool
    let canSaveData: Bool
    let canAccessPremiumFeatures: Bool
    let canSyncAcrossDevices: Bool
    let hasUnlimitedAccess: Bool
    let maxChartsPerDay: Int?
    
    var statusMessage: String {
        if !canGenerateCharts {
            return "Sign in or connect to internet to access features"
        } else if !canSaveData {
            return "Guest mode - data won't be saved across devices"
        } else if !canAccessPremiumFeatures {
            return "Limited connectivity - some features unavailable"
        } else {
            return "Full access available"
        }
    }
}

// MARK: - Apple Sign-In Integration
extension AuthState {
    func handleAppleSignIn(_ authorization: ASAuthorization) async {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            await MainActor.run {
                self.authError = "Failed to get Apple ID token"
            }
            print("Failed to get Apple ID token")
            return
        }
        
        do {
            let authResponse = try await apiServices.authenticateWithApple(
                idToken: tokenString,
                userIdentifier: appleIDCredential.user,
                email: appleIDCredential.email,
                firstName: appleIDCredential.fullName?.givenName,
                lastName: appleIDCredential.fullName?.familyName
            )
            
            await MainActor.run {
                // Clear any previous errors
                self.authError = nil
                self.connectionError = nil
                
                // Store authentication data
                self.jwtToken = authResponse.jwtToken
                self.authenticatedUser = authResponse.user
                self.hasSignedIn = true
                self.isAnonymousUser = false
                
                // Store JWT token securely
                self.storeJWTToken(authResponse.jwtToken)
                
                // Update API services with token
                self.apiServices.jwtToken = authResponse.jwtToken
                
                // Update state
                if self.profileManager.isProfileComplete {
                    self.state = .signedIn
                } else {
                    self.state = .needsProfileSetup
                }
            }
            
        } catch {
            print("Apple authentication failed: \(error)")
            await MainActor.run {
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .offline:
                        self.authError = "No internet connection. Please check your network and try again."
                    case .timeout:
                        self.authError = "Authentication timed out. Please try again."
                    case .authenticationFailed(let message):
                        self.authError = message ?? "Authentication failed. Please try again."
                    case .serverError(let code, let message):
                        if code >= 500 {
                            self.authError = "Server temporarily unavailable. Please try again later."
                        } else {
                            self.authError = message ?? "Authentication failed. Please try again."
                        }
                    default:
                        self.authError = "Authentication failed. Please try again."
                    }
                } else {
                    self.authError = "Authentication failed. Please try again."
                }
            }
        }
    }
    
    private func validateStoredToken() async {
        guard let token = jwtToken else { return }
        
        // Set the token in API services first
        apiServices.jwtToken = token
        
        // Try to use the token with a simple API call
        do {
            let _ = try await apiServices.validateToken()
            // Token is valid, user remains signed in
            await MainActor.run {
                self.authError = nil
            }
        } catch {
            // Handle token validation failure
            if let networkError = error as? NetworkError {
                switch networkError {
                case .tokenExpired, .authenticationFailed:
                    // Token is expired/invalid, sign out user
                    await MainActor.run {
                        self.signOut()
                    }
                case .offline, .timeout:
                    // Network issues, keep user signed in but show warning
                    await MainActor.run {
                        self.connectionError = "Unable to verify authentication. Some features may be limited."
                    }
                default:
                    // Other errors, keep user signed in
                    break
                }
            } else {
                // Unknown error, keep user signed in but log
                print("Token validation failed with unknown error: \(error)")
            }
        }
    }
    
    /// Handle automatic token refresh when token expires
    func handleTokenExpiry() async {
        guard jwtToken != nil else { return }
        
        do {
            // Try to refresh the token
            let authResponse = try await apiServices.refreshToken()
            
            await MainActor.run {
                self.jwtToken = authResponse.jwtToken
                self.authenticatedUser = authResponse.user
                self.storeJWTToken(authResponse.jwtToken)
                self.apiServices.jwtToken = authResponse.jwtToken
                self.authError = nil
            }
            
        } catch {
            // Refresh failed, sign out user
            await MainActor.run {
                self.authError = "Your session has expired. Please sign in again."
                self.signOut()
            }
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