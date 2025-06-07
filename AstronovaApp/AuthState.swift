import SwiftUI

enum AuthenticationState {
    case loading
    case signedOut
    case needsProfileSetup
    case signedIn
}

class AuthState: ObservableObject {
    @Published var state: AuthenticationState = .signedOut
    
    func requestSignIn() async {
        await MainActor.run {
            state = .loading
        }
        
        // Simulate sign-in process
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await MainActor.run {
            state = .needsProfileSetup
        }
    }
    
    func completeProfileSetup() {
        state = .signedIn
    }
    
    func signOut() {
        state = .signedOut
    }
}