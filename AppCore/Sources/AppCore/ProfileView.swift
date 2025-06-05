import SwiftUI
import AuthKit

/// Basic account screen with a sign-out button.
struct ProfileView: View {
    @EnvironmentObject private var auth: AuthManager

    var body: some View {
        NavigationView {
            Form {
                Button("Sign Out", role: .destructive) {
                    Task { await auth.signOut() }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#if DEBUG
#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
#endif
