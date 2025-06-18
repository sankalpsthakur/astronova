import SwiftUI
import AuthenticationServices
import CryptoKit

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
    
    @AppStorage("is_anonymous_user") var isAnonymousUser = false
    @AppStorage("has_signed_in") private var hasSignedIn = false
    
    private let apiServices = APIServices.shared
    private let keychainHelper = KeychainHelper()
    
    // Generate nonce for Apple Sign-In security
    var nonce: String {
        let data = Data(UUID().uuidString.utf8)
        return SHA256.hash(data: data).compactMap {
            String(format: "%02x", $0)
        }.joined()
    }
    
    init() {
        checkAuthState()
    }
    
    private func checkAuthState() {
        // Check API connectivity in background
        Task {
            await checkAPIConnectivity()
        }
        
        // Check for stored JWT token
        if let storedToken = keychainHelper.getJWTToken() {
            jwtToken = storedToken
            hasSignedIn = true
            
            // Verify token is still valid
            Task {
                await validateStoredToken()
            }
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
            print("API connectivity check failed: \(error)")
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
        authenticatedUser = nil
        keychainHelper.deleteJWTToken()
        
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
        isAnonymousUser = true
        hasSignedIn = true
        state = profileManager.isProfileComplete ? .signedIn : .needsProfileSetup
    }
    
    // MARK: - Apple Sign-In Integration
    
    func handleAppleSignIn(_ authorization: ASAuthorization) async {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
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
                // Store authentication data
                self.jwtToken = authResponse.jwtToken
                self.authenticatedUser = authResponse.user
                self.hasSignedIn = true
                self.isAnonymousUser = false
                
                // Store JWT token securely
                self.keychainHelper.storeJWTToken(authResponse.jwtToken)
                
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
                self.connectionError = "Authentication failed. Please try again."
            }
        }
    }
    
    private func validateStoredToken() async {
        guard let token = jwtToken else { return }
        
        // Try to use the token with a simple API call
        do {
            let _ = try await apiServices.validateToken()
            // Token is valid, user remains signed in
        } catch {
            // Token is invalid/expired, sign out user
            await MainActor.run {
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