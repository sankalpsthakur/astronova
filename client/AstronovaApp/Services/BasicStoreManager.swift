import Foundation
import SwiftUI

final class BasicStoreManager: ObservableObject {
    static let shared = BasicStoreManager()

    @AppStorage("hasAstronovaPro") var hasProSubscription: Bool = false
    @AppStorage("chat_credits") var chatCredits: Int = 0
    @Published var products: [String: String] = [
        // Subscription
        "astronova_pro_monthly": "$9.99",
        // Reports (Non-Consumable)
        "report_general": "$12.99",
        "report_love": "$12.99",
        "report_career": "$12.99",
        "report_money": "$12.99",
        "report_health": "$12.99",
        "report_family": "$12.99",
        "report_spiritual": "$12.99",
        // Chat Credits (Consumable)
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
                // Map Product ID to actual credit amounts
                // Note: Product IDs can't be changed in App Store Connect,
                // so we use an explicit mapping instead of parsing the ID
                let creditAmounts: [String: Int] = [
                    "chat_credits_5": 50,
                    "chat_credits_15": 150,
                    "chat_credits_50": 500
                ]

                if let credits = creditAmounts[productId] {
                    chatCredits += credits
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
