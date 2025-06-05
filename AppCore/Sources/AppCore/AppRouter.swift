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

    public func view(for route: AppRoute) -> AnyView {
        switch route {
        case .today:
            AnyView(TodayView())
        case .match:
            AnyView(MatchView())
        case .chat:
            AnyView(ChatView())
        case .shop:
            AnyView(ShopView())
        case .profile:
            AnyView(ProfileView())
        }
    }
}