import Foundation
import SwiftUI

final class BasicStoreManager: ObservableObject {
    static let shared = BasicStoreManager()

    @AppStorage("hasAstronovaPro") var hasProSubscription: Bool = false
    @AppStorage("chat_credits") var chatCredits: Int = 0
    @Published var products: [String: String] = ShopCatalog.fallbackPrices

    func loadProducts() { /* no-op for basic manager */ }

    func purchaseProduct(productId: String) async -> Bool {
        await MainActor.run {
            if ShopCatalog.isProProduct(productId) {
                hasProSubscription = true
            }
            if productId.hasPrefix("chat_credits_") {
                if let credits = ShopCatalog.chatCreditAmounts[productId] {
                    chatCredits += credits
                }
            }
            let purchaseKey = "purchased_\(productId)"
            UserDefaults.standard.set(true, forKey: purchaseKey)
        }
        return true
    }

    func hasProduct(_ productId: String) -> Bool {
        if ShopCatalog.isProProduct(productId) { return hasProSubscription }
        let purchaseKey = "purchased_\(productId)"
        return UserDefaults.standard.bool(forKey: purchaseKey)
    }

    @discardableResult
    func restorePurchases() async -> Bool {
        // In mock mode, simulate a successful restore if user has Pro
        return await MainActor.run { hasProSubscription }
    }
}
