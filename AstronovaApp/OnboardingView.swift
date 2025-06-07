import SwiftUI

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

            Button("Sign In with Apple") {
                Task {
                    await signIn()
                }
            }
            .frame(height: 45)
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
            .disabled(inProgress)
            .overlay(
                Group {
                    if inProgress { 
                        ProgressView()
                            .foregroundStyle(Color.white)
                    }
                }
            )

            Spacer(minLength: 32)
        }
        .padding()
    }
    
    private func signIn() async {
        inProgress = true
        await auth.requestSignIn()
        inProgress = false
    }
}