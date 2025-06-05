import SwiftUI
import AuthKit

/// First-run screen with a single “Sign in with Apple” button.
struct OnboardingView: View {
    @EnvironmentObject private var auth: AuthManager
    @State private var inProgress = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "sparkles")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(.tint)

            Text("Welcome to CosmoChat")
                .font(.largeTitle.weight(.semibold))

            Spacer()

            SignInWithAppleButton()
                .frame(height: 45)
                .disabled(inProgress)
                .taskProgress($inProgress) {
                    await auth.requestSignIn()
                }

            Spacer(minLength: 32)
        }
        .padding()
    }
}

#if canImport(AuthenticationServices)
import AuthenticationServices

private struct SignInWithAppleButton: View {
    var body: some View {
        SignInWithAppleButtonInternal()
            .signInWithAppleButtonStyle(.black)
            .frame(maxWidth: .infinity)
    }
}

/// Wrapper for ASAuthorizationAppleIDButton so it works inside SwiftUI previews too.
private struct SignInWithAppleButtonInternal: UIViewRepresentable {
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        ASAuthorizationAppleIDButton(type: .signIn, style: .black)
    }
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
}
#endif

// MARK: – Utility modifier

private extension View {
    /// Runs the given async task when tapped, toggling a boolean while it is in progress.
    func taskProgress(_ flag: Binding<Bool>, action: @escaping () async -> Void) -> some View {
        self.modifier(TaskProgressModifier(flag: flag, action: action))
    }
}

private struct TaskProgressModifier: ViewModifier {
    @Binding var flag: Bool
    var action: () async -> Void

    func body(content: Content) -> some View {
        Button(action: start) {
            content
                .overlay(
                    Group {
                        if flag { LoadingView() }
                    }
                )
        }
    }

    private func start() {
        guard !flag else { return }
        flag = true
        Task {
            await action()
            await MainActor.run { flag = false }
        }
    }
}
