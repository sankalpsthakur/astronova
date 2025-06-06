import SwiftUI
import AuthKit

/// Main tab bar hosting the five core verticals for the MVP release.
struct TabBarView: View {
    @State private var selection: Int = 0
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(0)

            MatchView()
                .tabItem { Label("Match", systemImage: "heart.circle") }
                .tag(1)

            ChatView(authManager: authManager)
                .tabItem { Label("Chat", systemImage: "message") }
                .tag(2)

            ShopView()
                .tabItem { Label("Shop", systemImage: "bag") }
                .tag(3)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(4)
        }
    }
}
