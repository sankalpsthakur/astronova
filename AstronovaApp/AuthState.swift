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
    
    init() {
        checkAuthState()
    }
    
    private func checkAuthState() {
        // Check if user is signed in and has complete profile
        let hasSignedIn = UserDefaults.standard.bool(forKey: "has_signed_in")
        
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
    
    func requestSignIn() async {
        await MainActor.run {
            state = .loading
        }
        
        // Simulate sign-in process
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await MainActor.run {
            UserDefaults.standard.set(true, forKey: "has_signed_in")
            if profileManager.isProfileComplete {
                state = .signedIn
            } else {
                state = .needsProfileSetup
            }
        }
    }
    
    func completeProfileSetup() {
        profileManager.saveProfile()
        state = .signedIn
    }
    
    func signOut() {
        UserDefaults.standard.set(false, forKey: "has_signed_in")
        profileManager = UserProfileManager() // Reset profile
        state = .signedOut
    }
}