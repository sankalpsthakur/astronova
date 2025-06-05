import SwiftUI

/// Enum for top‑level navigation routes in the app.
public enum AppRoute {
    case today
    case match
    case chat
    case shop
    case profile
}

/// Responsible for mapping routes to SwiftUI views.
public struct AppRouter {
    public init() {}

    public func view(for route: AppRoute) -> some View {
        switch route {
        case .today:
            TodayView()
        case .match:
            MatchView()
        case .chat:
            Text("Chat View Placeholder") // Deferred feature
        case .shop:
            ShopView()
        case .profile:
            Text("Profile View Placeholder")
        }
    }
}