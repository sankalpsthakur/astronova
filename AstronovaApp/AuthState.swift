import SwiftUI

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
    
    private let apiServices = APIServices.shared
    
    init() {
        checkAuthState()
    }
    
    private func checkAuthState() {
        // Check if user is signed in and has complete profile
        let hasSignedIn = UserDefaults.standard.bool(forKey: "has_signed_in")
        
        // Check API connectivity in background
        Task {
            await checkAPIConnectivity()
        }
        
        if hasSignedIn {
            if profileManager.isProfileComplete {
                state = .signedIn
            } else {
                state = .needsProfileSetup
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
            UserDefaults.standard.set(true, forKey: "has_signed_in")
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
        UserDefaults.standard.set(false, forKey: "has_signed_in")
        profileManager = UserProfileManager() // Reset profile
        isAPIConnected = false
        connectionError = nil
        state = .signedOut
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
        return isAPIConnected && profileManager.isProfileComplete
    }
}