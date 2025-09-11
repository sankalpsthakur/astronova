import SwiftUI

// Central source of truth for shop SKUs and report metadata
struct ShopCatalog {
    struct Report: Identifiable {
        let id: String
        let productId: String
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
    }
    
    struct ChatPack: Identifiable {
        let id: String
        let productId: String
        let title: String
        let subtitle: String
        let credits: Int
    }

    // One canonical list for all report SKUs used across the app
    static let reports: [Report] = [
        .init(
            id: "general",
            productId: "report_general",
            title: "Personal Blueprint",
            subtitle: "Core strengths & timing",
            icon: "sparkles",
            color: .purple
        ),
        .init(
            id: "love",
            productId: "report_love",
            title: "Love Forecast",
            subtitle: "Romance & chemistry",
            icon: "heart.fill",
            color: .pink
        ),
        .init(
            id: "career",
            productId: "report_career",
            title: "Career Roadmap",
            subtitle: "Work & purpose windows",
            icon: "briefcase.fill",
            color: .blue
        ),
        .init(
            id: "money",
            productId: "report_money",
            title: "Wealth & Money",
            subtitle: "Income & risk cycles",
            icon: "dollarsign.circle.fill",
            color: .green
        ),
        .init(
            id: "health",
            productId: "report_health",
            title: "Health & Vitality",
            subtitle: "Energy & recovery",
            icon: "cross.case.fill",
            color: .teal
        ),
        .init(
            id: "family",
            productId: "report_family",
            title: "Family & Friends",
            subtitle: "Home dynamics",
            icon: "person.2.fill",
            color: .orange
        ),
        .init(
            id: "spiritual",
            productId: "report_spiritual",
            title: "Spiritual & Karma",
            subtitle: "Soul themes",
            icon: "sparkle.magnifyingglass",
            color: .indigo
        )
    ]
    
    // Central list of chat credit packs
    static let chatPacks: [ChatPack] = [
        .init(id: "c5", productId: "chat_credits_5", title: "5 Replies", subtitle: "Quick clarity", credits: 5),
        .init(id: "c15", productId: "chat_credits_15", title: "15 Replies", subtitle: "Deeper guidance", credits: 15),
        .init(id: "c50", productId: "chat_credits_50", title: "50 Replies", subtitle: "Best value", credits: 50)
    ]

    // Price helper sourced from BasicStoreManager so prices don't drift
    static func price(for productId: String) -> String {
        BasicStoreManager.shared.products[productId] ?? "$12.99"
    }
}
