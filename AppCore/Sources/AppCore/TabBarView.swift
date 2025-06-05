import SwiftUI

/// Main tab bar hosting the three core verticals for the MVP release.
struct TabBarView: View {
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(0)

            MatchView()
                .tabItem { Label("Match", systemImage: "heart.circle") }
                .tag(1)

            ShopView()
                .tabItem { Label("Shop", systemImage: "bag") }
                .tag(2)
        }
    }
}
