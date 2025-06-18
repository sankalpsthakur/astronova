import SwiftUI
import AuthenticationServices
import CryptoKit

struct SignInWithAppleView: View {
    @EnvironmentObject var authState: AuthState
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            // App branding
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.cosmicPrimary)
                
                Text("Welcome to AstroNova")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.cosmicTextPrimary)
                
                Text("Unlock the secrets of the cosmos with personalized astrological insights")
                    .font(.body)
                    .foregroundColor(.cosmicTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Sign in section
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .frame(height: 50)
                } else {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = authState.nonce
                    } onCompletion: { result in
                        handleSignInResult(result)
                    }
                    .frame(height: 50)
                    .cornerRadius(8)
                    .signInWithAppleButtonStyle(.black)
                }
                
                // Show auth errors
                if let authError = authState.authError {
                    VStack(spacing: 8) {
                        Text(authError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Retry button for recoverable errors
                        if authError.contains("network") || authError.contains("timeout") || authError.contains("temporarily") {
                            Button("Retry") {
                                Task {
                                    await authState.retryConnection()
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.cosmicAccent)
                        }
                    }
                }
                
                // Show local error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Show connection status
                if let connectionError = authState.connectionError {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.orange)
                        Text(connectionError)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal)
                }
                
                Button("Continue as Guest") {
                    authState.continueAsGuest()
                }
                .foregroundColor(.cosmicTextSecondary)
                .font(.body)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Terms and privacy
            Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                .font(.caption)
                .foregroundColor(.cosmicTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(Color.cosmicSurface)
    }
    
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .success(let authorization):
            Task {
                await authState.handleAppleSignIn(authorization)
                await MainActor.run {
                    isLoading = false
                }
            }
        case .failure(let error):
            errorMessage = "Sign-in failed. Please try again."
            isLoading = false
            print("Apple Sign-In failed: \(error)")
        }
    }
}

#Preview {
    SignInWithAppleView()
        .environmentObject(AuthState())
}