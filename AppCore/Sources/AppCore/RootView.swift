import SwiftUI
import AuthKit

/// Decides which high-level screen to show based on authentication state.
struct RootView: View {
    @EnvironmentObject private var auth: AuthManager

    var body: some View {
        Group {
            switch auth.state {
            case .loading:
                LoadingView()
            case .signedOut:
                OnboardingView()
            case .signedIn:
                TabBarView()
            }
        }

    }
}
