import Foundation
import SwiftUI

final class BasicStoreManager: ObservableObject {
    static let shared = BasicStoreManager()

    @AppStorage("hasAstronovaPro") var hasProSubscription: Bool = false
    @AppStorage("chat_credits") var chatCredits: Int = 0
    @Published var products: [String: String] = [
        "love_forecast": "$4.99",
        "birth_chart": "$7.99",
        "career_forecast": "$5.99",
        "year_ahead": "$9.99",
        "astronova_pro_monthly": "$9.99",
        // New detailed report SKUs (7 types, $10+)
        "report_general": "$12.99",
        "report_love": "$12.99",
        "report_career": "$12.99",
        "report_money": "$12.99",
        "report_health": "$12.99",
        "report_family": "$12.99",
        "report_spiritual": "$12.99",
        // Chat credit packages
        "chat_credits_5": "$14.99",
        "chat_credits_15": "$34.99",
        "chat_credits_50": "$89.99"
    ]

    func loadProducts() { /* no-op for basic manager */ }

    func purchaseProduct(productId: String) async -> Bool {
        await MainActor.run {
            if productId == "astronova_pro_monthly" {
                hasProSubscription = true
            }
            if productId.hasPrefix("chat_credits_") {
                // Extract count from productId and add to chat credits
                let parts = productId.split(separator: "_")
                if let last = parts.last, let count = Int(last) {
                    chatCredits += count
                }
            }
            let purchaseKey = "purchased_\(productId)"
            UserDefaults.standard.set(true, forKey: purchaseKey)
        }
        return true
    }

    func hasProduct(_ productId: String) -> Bool {
        if productId == "astronova_pro_monthly" { return hasProSubscription }
        let purchaseKey = "purchased_\(productId)"
        return UserDefaults.standard.bool(forKey: purchaseKey)
    }

    @discardableResult
    func restorePurchases() async -> Bool {
        // In mock mode, simulate a successful restore if user has Pro
        return await MainActor.run { hasProSubscription }
    }
}
