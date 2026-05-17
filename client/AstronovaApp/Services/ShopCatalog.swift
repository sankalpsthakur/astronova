import SwiftUI

// Central source of truth for shop SKUs and report metadata
struct ShopCatalog {
    enum ProBillingPlan: Equatable, Sendable {
        case standard
        case monthlyCommitment
    }

    struct ProPlan: Identifiable, Sendable {
        let id: String
        let productId: String
        let title: String
        let badge: String?
        let fallbackBillingDisplayPrice: String
        let fallbackCommitmentDisplayPrice: String?
        let billingCaption: String
        let renewalCadenceDescription: String
        let billingPlan: ProBillingPlan
    }

    struct Report: Identifiable {
        let id: String
        let productId: String
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
    }

    static let proMonthlyProductID = "astronova_pro_monthly"
    static let pro12MonthCommitmentProductID = "astronova_pro_12_month_commitment"
    static let proIntroOfferDescription = "14-day free trial"
    static let proRenewalCadenceDescription = "then monthly auto-renewal"
    static let pro12MonthRenewalCadenceDescription = "12 monthly payments, then monthly auto-renewal"
    static let defaultProProductID = pro12MonthCommitmentProductID

    static let proPlans: [ProPlan] = [
        .init(
            id: "twelve_month_commitment",
            productId: pro12MonthCommitmentProductID,
            title: "12-month plan",
            badge: "Best first year",
            fallbackBillingDisplayPrice: "$9.99",
            fallbackCommitmentDisplayPrice: "$119.88",
            billingCaption: "per month for 12 months",
            renewalCadenceDescription: pro12MonthRenewalCadenceDescription,
            billingPlan: .monthlyCommitment
        ),
        .init(
            id: "monthly",
            productId: proMonthlyProductID,
            title: "Monthly",
            badge: nil,
            fallbackBillingDisplayPrice: "$9.99",
            fallbackCommitmentDisplayPrice: nil,
            billingCaption: "per month",
            renewalCadenceDescription: proRenewalCadenceDescription,
            billingPlan: .standard
        )
    ]

    static var proProductIDs: [String] {
        proPlans.map(\.productId)
    }

    static func isProProduct(_ productId: String) -> Bool {
        proProductIDs.contains(productId)
    }

    static func proPlan(for productId: String) -> ProPlan {
        proPlans.first { $0.productId == productId } ?? proPlans[0]
    }

    static let reportProductIDs = [
        "report_general",
        "report_love",
        "report_career",
        "report_money",
        "report_health",
        "report_family",
        "report_spiritual"
    ]

    static let chatCreditAmounts: [String: Int] = [
        "chat_credits_5": 50,
        "chat_credits_15": 150,
        "chat_credits_50": 500
    ]

    static let fallbackPrices: [String: String] = [
        proMonthlyProductID: "$9.99",
        pro12MonthCommitmentProductID: "$119.88",
        "report_general": "$12.99",
        "report_love": "$12.99",
        "report_career": "$12.99",
        "report_money": "$12.99",
        "report_health": "$12.99",
        "report_family": "$12.99",
        "report_spiritual": "$12.99",
        "chat_credits_5": "$14.99",
        "chat_credits_15": "$34.99",
        "chat_credits_50": "$89.99"
    ]

    static var allProductIDs: Set<String> {
        Set(proProductIDs + reportProductIDs + Array(chatCreditAmounts.keys))
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
            productId: reportProductIDs[0],
            title: "Personal Blueprint",
            subtitle: "Core strengths & timing",
            icon: "sparkles",
            color: .purple
        ),
        .init(
            id: "love",
            productId: reportProductIDs[1],
            title: "Love Forecast",
            subtitle: "Romance & chemistry",
            icon: "heart.fill",
            color: .pink
        ),
        .init(
            id: "career",
            productId: reportProductIDs[2],
            title: "Career Roadmap",
            subtitle: "Work & purpose windows",
            icon: "briefcase.fill",
            color: .blue
        ),
        .init(
            id: "money",
            productId: reportProductIDs[3],
            title: "Resource Cycles",
            subtitle: "Timing themes & capacity patterns",
            icon: "chart.line.uptrend.xyaxis",
            color: .green
        ),
        .init(
            id: "health",
            productId: reportProductIDs[4],
            title: "Energy Patterns",
            subtitle: "Personal rhythms & restorative timing",
            icon: "sun.max.fill",
            color: .teal
        ),
        .init(
            id: "family",
            productId: reportProductIDs[5],
            title: "Family & Friends",
            subtitle: "Home dynamics",
            icon: "person.2.fill",
            color: .orange
        ),
        .init(
            id: "spiritual",
            productId: reportProductIDs[6],
            title: "Spiritual & Karma",
            subtitle: "Soul themes",
            icon: "sparkle.magnifyingglass",
            color: .indigo
        )
    ]
    
    // Central list of chat credit packs
    static let chatPacks: [ChatPack] = [
        .init(id: "c5", productId: "chat_credits_5", title: "50 Credits", subtitle: "Regular use", credits: chatCreditAmounts["chat_credits_5", default: 50]),
        .init(id: "c15", productId: "chat_credits_15", title: "150 Credits", subtitle: "Extended sessions", credits: chatCreditAmounts["chat_credits_15", default: 150]),
        .init(id: "c50", productId: "chat_credits_50", title: "500 Credits", subtitle: "Best value", credits: chatCreditAmounts["chat_credits_50", default: 500])
    ]

    static func report(forReportType reportType: String) -> Report? {
        let reportId: String
        switch reportType {
        case "birth_chart":
            reportId = "general"
        case "love_forecast":
            reportId = "love"
        case "career_forecast":
            reportId = "career"
        case "money_forecast":
            reportId = "money"
        case "health_forecast":
            reportId = "health"
        case "family_forecast":
            reportId = "family"
        case "spiritual_forecast":
            reportId = "spiritual"
        case "year_ahead":
            return nil
        default:
            reportId = reportType
        }

        return reports.first { $0.id == reportId }
    }

    static func reportType(for report: Report) -> String {
        switch report.id {
        case "general":
            return "birth_chart"
        case "love":
            return "love_forecast"
        case "career":
            return "career_forecast"
        case "money":
            return "money_forecast"
        case "health":
            return "health_forecast"
        case "family":
            return "family_forecast"
        case "spiritual":
            return "spiritual_forecast"
        default:
            return report.id
        }
    }

    // Price helper - prefer StoreKitManager (real prices), fallback to BasicStoreManager for tests
    static func price(for productId: String) -> String {
        // Try StoreKitManager first (real App Store prices)
        if let storeKitPrice = StoreKitManager.shared.products[productId], !storeKitPrice.isEmpty {
            return storeKitPrice
        }
        // Fallback to mock prices (for testing/development only)
        return BasicStoreManager.shared.products[productId] ?? fallbackPrices[productId] ?? "$12.99"
    }
}
