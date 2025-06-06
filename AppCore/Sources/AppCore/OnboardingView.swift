import SwiftUI
import AuthKit

/// Welcome screen with enhanced onboarding flow and skip option.
struct OnboardingView: View {
    @EnvironmentObject private var auth: AuthManager
    @State private var inProgress = false
    @State private var currentPage = 0
    
    private let onboardingPages = [
        OnboardingPage(
            icon: "sparkles",
            title: "Welcome to Astronova",
            subtitle: "Discover your cosmic journey with personalized astrology insights"
        ),
        OnboardingPage(
            icon: "heart.circle",
            title: "Find Your Match",
            subtitle: "Explore compatibility with others based on astrological harmony"
        ),
        OnboardingPage(
            icon: "message.circle",
            title: "Chat with AI Astrologer",
            subtitle: "Get personalized guidance from our intelligent cosmic advisor"
        ),
        OnboardingPage(
            icon: "calendar.circle",
            title: "Daily Insights",
            subtitle: "Receive tailored horoscopes and planetary guidance every day"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            if currentPage < onboardingPages.count - 1 {
                HStack {
                    Spacer()
                    Button("Skip") {
                        withAnimation {
                            currentPage = onboardingPages.count - 1
                        }
                    }
                    .foregroundStyle(.secondary)
                    .padding()
                }
            }
            
            TabView(selection: $currentPage) {
                ForEach(Array(onboardingPages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page, isLastPage: index == onboardingPages.count - 1) {
                        if index == onboardingPages.count - 1 {
                            // Sign in action
                            Task {
                                await auth.requestSignIn()
                            }
                        } else {
                            withAnimation {
                                currentPage = index + 1
                            }
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .disabled(inProgress)
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isLastPage: Bool
    let action: () -> Void
    @EnvironmentObject private var auth: AuthManager
    @State private var inProgress = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: page.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(.tint)

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle.weight(.semibold))
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
            
            if isLastPage {
                SignInWithAppleButton()
                    .frame(height: 50)
                    .disabled(inProgress)
                    .taskProgress($inProgress) {
                        await auth.requestSignIn()
                    }
                    .padding(.horizontal, 40)
            } else {
                Button("Continue") {
                    action()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.tint)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 40)
            }

            Spacer(minLength: 50)
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