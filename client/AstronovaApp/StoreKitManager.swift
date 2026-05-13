import Foundation
import StoreKit
import SwiftUI

// MARK: - StoreKit Error Handling

enum StoreError: Error {
    case failedVerification
}

// MARK: - StoreKit 2 Manager

class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @AppStorage("hasAstronovaPro") var hasProSubscription = false
    @Published var products: [String: String] = [:]  // Product ID to localized price
    @Published var monthlyBillingPlanPrices: [String: String] = [:]
    @Published var commitmentDisplayPrices: [String: String] = [:]
    
    private var storeKitProducts: [Product] = []
    private var updateListenerTask: Task<Void, Error>?
    
    // Product IDs defined in App Store Connect
    private var productIDs: [String] {
        if let ids = Bundle.main.object(forInfoDictionaryKey: "AppStoreProductIDs") as? [String] {
            let configured = ids.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if !configured.isEmpty { return configured }
        }
        return Array(ShopCatalog.allProductIDs)
    }
    
    init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load products on initialization
        Task {
            await loadProducts()
            await checkCurrentEntitlements()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func loadProducts() async {
        do {
            // Use StoreKit 2's Product.products(for:) to load real products
            storeKitProducts = try await Product.products(for: productIDs)
            
            // Update products dictionary with real localized prices
            await MainActor.run {
                var newProducts: [String: String] = [:]
                var newMonthlyBillingPlanPrices: [String: String] = [:]
                var newCommitmentDisplayPrices: [String: String] = [:]
                for product in storeKitProducts {
                    newProducts[product.id] = product.displayPrice
                    if #available(iOS 26.4, *),
                       let pricingTerms = Self.monthlyPricingTerms(for: product) {
                        newMonthlyBillingPlanPrices[product.id] = pricingTerms.billingDisplayPrice
                        newCommitmentDisplayPrices[product.id] = pricingTerms.commitmentInfo.displayPrice
                    }
                }
                self.products = newProducts
                self.monthlyBillingPlanPrices = newMonthlyBillingPlanPrices
                self.commitmentDisplayPrices = newCommitmentDisplayPrices
                if newProducts.isEmpty {
                    debugPrint("[StoreKit] App Store Connect returned no Astronova products for: \(self.productIDs.joined(separator: ", "))")
                }
            }
        } catch {
            #if DEBUG
            debugPrint("[StoreKit] Failed to load products for \(productIDs.joined(separator: ", ")): \(error.localizedDescription)")
            #endif
            // Fallback to hardcoded prices (must match BasicStoreManager)
            await MainActor.run {
                self.products = ShopCatalog.fallbackPrices
                self.monthlyBillingPlanPrices = [:]
                self.commitmentDisplayPrices = [:]
            }
        }
    }
    
    // Synchronous version for protocol compatibility
    func loadProducts() {
        Task {
            await loadProducts()
        }
    }
    
    func purchaseProduct(productId: String, billingPlan: ShopCatalog.ProBillingPlan = .standard) async -> Bool {
        guard let product = storeKitProducts.first(where: { $0.id == productId }) else {
            #if DEBUG
            debugPrint("[StoreKit] Product not found: \(productId)")
            #endif
            return false
        }
        
        do {
            let result = try await purchase(product, billingPlan: billingPlan)
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // Handle successful purchase
                await handleSuccessfulPurchase(transaction: transaction)
                
                // Finish the transaction
                await transaction.finish()
                
                return true
                
            case .userCancelled:
                #if DEBUG
                debugPrint("[StoreKit] User cancelled purchase")
                #endif
                return false

            case .pending:
                #if DEBUG
                debugPrint("[StoreKit] Purchase is pending")
                #endif
                return false

            @unknown default:
                #if DEBUG
                debugPrint("[StoreKit] Unknown purchase result")
                #endif
                return false
            }
        } catch {
            #if DEBUG
            debugPrint("[StoreKit] Purchase failed: \(error.localizedDescription)")
            #endif
            return false
        }
    }
    
    // MARK: - Public Utility Methods
    
    /// Check if a specific product has been purchased
    func hasProduct(_ productId: String) -> Bool {
        if ShopCatalog.isProProduct(productId) {
            return hasProSubscription
        }
        
        let purchaseKey = "purchased_\(productId)"
        return UserDefaults.standard.bool(forKey: purchaseKey)
    }
    
    /// Restore purchases (useful for family sharing and device transfers)
    /// Returns true if any purchases were restored
    @discardableResult
    func restorePurchases() async -> Bool {
        let hadProBefore = hasProSubscription
        do {
            try await AppStore.sync()
        } catch {
            #if DEBUG
            debugPrint("[StoreKit] AppStore sync failed: \(error.localizedDescription)")
            #endif
        }
        await checkCurrentEntitlements()
        return hasProSubscription || hadProBefore
    }

    /// Refresh entitlement state without triggering a restore flow
    @discardableResult
    func refreshEntitlements() async -> Bool {
        await checkCurrentEntitlements()
        return hasProSubscription
    }
    
    // MARK: - Private Methods
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Listen for transaction updates using StoreKit 2's Transaction.updates
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.handleSuccessfulPurchase(transaction: transaction)
                    await transaction.finish()
                } catch {
                    #if DEBUG
                    debugPrint("[StoreKit] Transaction verification failed: \(error.localizedDescription)")
                    #endif
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: StoreKit.VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    @MainActor
    private func purchase(_ product: Product, billingPlan: ShopCatalog.ProBillingPlan) async throws -> Product.PurchaseResult {
        switch billingPlan {
        case .standard:
            return try await product.purchase()
        case .monthlyCommitment:
            if #available(iOS 26.4, *), Self.monthlyPricingTerms(for: product) != nil {
                return try await product.purchase(options: [.billingPlanType(.monthly)])
            }
            return try await product.purchase()
        }
    }

    @available(iOS 26.4, *)
    private static func monthlyPricingTerms(for product: Product) -> Product.SubscriptionInfo.PricingTerms? {
        guard let subscription = product.subscription else { return nil }
        let monthlyTerms = subscription.pricingTerms.filter { $0.billingPlanType == .monthly }
        return monthlyTerms.first { isTwelveMonthCommitment($0.commitmentInfo.period) } ?? monthlyTerms.first
    }

    private static func isTwelveMonthCommitment(_ period: Product.SubscriptionPeriod) -> Bool {
        switch period.unit {
        case .month:
            return period.value == 12
        case .year:
            return period.value == 1
        default:
            return false
        }
    }
    
    private func handleSuccessfulPurchase(transaction: StoreKit.Transaction) async {
        await MainActor.run {
            if ShopCatalog.isProProduct(transaction.productID) {
                self.hasProSubscription = true
            }

            // Handle chat credit purchases (consumable)
            if transaction.productID.hasPrefix("chat_credits_") {
                // Map Product ID to actual credit amounts
                // Note: Product IDs can't be changed in App Store Connect,
                // so we use an explicit mapping instead of parsing the ID
                if let credits = ShopCatalog.chatCreditAmounts[transaction.productID] {
                    let currentCredits = UserDefaults.standard.integer(forKey: "chat_credits")
                    UserDefaults.standard.set(currentCredits + credits, forKey: "chat_credits")
                }
            }

            // Handle other product purchases (individual reports, non-consumable)
            // Store purchase history or enable access to specific reports
            let purchaseKey = "purchased_\(transaction.productID)"
            UserDefaults.standard.set(true, forKey: purchaseKey)

            // Post notification for UI updates
            NotificationCenter.default.post(
                name: .purchaseCompleted,
                object: transaction.productID
            )
        }
    }
    
    private func checkCurrentEntitlements() async {
        var hasPro = false
        var purchasedProductIds: [String] = []

        // Check for current subscription entitlements
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if ShopCatalog.isProProduct(transaction.productID) {
                    hasPro = true
                }

                // Mark individual products as purchased if they're current entitlements
                purchasedProductIds.append(transaction.productID)
            } catch {
                #if DEBUG
                debugPrint("[StoreKit] Failed to verify current entitlement: \(error.localizedDescription)")
                #endif
            }
        }

        // Capture values before MainActor context
        let finalHasPro = hasPro
        let finalPurchasedProductIds = purchasedProductIds

        await MainActor.run {
            self.hasProSubscription = finalHasPro
            for productId in finalPurchasedProductIds {
                let purchaseKey = "purchased_\(productId)"
                UserDefaults.standard.set(true, forKey: purchaseKey)
            }
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let purchaseCompleted = Notification.Name("purchaseCompleted")
    static let reportPurchased = Notification.Name("reportPurchased")
}
