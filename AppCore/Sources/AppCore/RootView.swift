import SwiftUI
import AuthKit

/// Decides which high-level screen to show based on authentication state.
public struct RootView: View {
    @EnvironmentObject private var auth: AuthManager

    public init() {}

    public var body: some View {
        Group {
            switch auth.state {
            case .loading:
                LoadingView()
            case .signedOut:
                OnboardingView()
            case .needsProfileSetup:
                ProfileSetupView()
            case .signedIn:
                TabBarView()
            }
        }

    }
}
