import SwiftUI
import AuthenticationServices

/// First-run screen with a single "Sign in with Apple" button.
struct OnboardingView: View {
    @EnvironmentObject private var auth: AuthState
    @State private var inProgress = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "sparkles")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(Color.accentColor)

            Text("Welcome to Astronova")
                .font(.largeTitle.weight(.semibold))

            Spacer()

            VStack(spacing: 16) {
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = auth.nonce
                    },
                    onCompletion: { result in
                        Task {
                            await handleSignInResult(result)
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .frame(maxWidth: 375) // Respect Apple's HIG for max width
                .disabled(inProgress)
                .overlay(
                    Group {
                        if inProgress {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                    }
                )
                
                Button("Continue without signing in") {
                    handleSkipSignIn()
                }
                .foregroundColor(.secondary)
                .disabled(inProgress)
            }

            Spacer(minLength: 32)
        }
        .padding()
    }
    
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) async {
        inProgress = true
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Extract user information
                let userID = appleIDCredential.user
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                
                // Store user information
                if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                    let displayName = "\(givenName) \(familyName)"
                    UserDefaults.standard.set(displayName, forKey: "user_full_name")
                    
                    // Pre-populate profile with user's name
                    await MainActor.run {
                        auth.profileManager.profile.fullName = displayName
                    }
                }
                
                if let email = email {
                    UserDefaults.standard.set(email, forKey: "user_email")
                }
                
                UserDefaults.standard.set(userID, forKey: "apple_user_id")
                
                // Complete sign in
                await auth.requestSignIn()
            }
        case .failure(let error):
            print("Sign in with Apple failed: \(error)")
            // Handle error appropriately
        }
        
        inProgress = false
    }
    
    private func handleSkipSignIn() {
        inProgress = true
        
        // Set anonymous user flag
        UserDefaults.standard.set(true, forKey: "is_anonymous_user")
        
        // Complete sign in without Apple ID
        auth.continueAsGuest()
        
        inProgress = false
    }
}