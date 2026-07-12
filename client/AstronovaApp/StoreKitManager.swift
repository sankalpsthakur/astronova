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
    @Published private(set) var availableProductIDs: Set<String> = []
    @Published private(set) var productLoadCompleted = false
    
    private var storeKitProducts: [Product] = []
    private var updateListenerTask: Task<Void, Error>?
    private let lifecycleStateStore = SubscriptionLifecycleStateStore()

    enum PurchaseAnalyticsSource: String {
        case purchaseFlow = "purchase_flow"
        case transactionUpdate = "transaction_update"
    }

    struct PurchaseAnalyticsEmission: Equatable {
        let event: AnalyticsEvent
        let properties: [String: String]
    }

    private struct EntitlementRefreshResult {
        let hasProSubscription: Bool
        let productIds: [String]

        var hasAnyEntitlement: Bool {
            !productIds.isEmpty
        }
    }
    
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
            await refreshEntitlements()
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
                    #if STOREKIT_PRICING_TERMS_AVAILABLE
                    if #available(iOS 26.4, *),
                       let pricingTerms = Self.monthlyPricingTerms(for: product) {
                        newMonthlyBillingPlanPrices[product.id] = pricingTerms.billingDisplayPrice
                        newCommitmentDisplayPrices[product.id] = pricingTerms.commitmentInfo.displayPrice
                    }
                    #endif
                }
                self.products = newProducts
                self.monthlyBillingPlanPrices = newMonthlyBillingPlanPrices
                self.commitmentDisplayPrices = newCommitmentDisplayPrices
                self.availableProductIDs = Set(self.storeKitProducts.map(\.id))
                self.productLoadCompleted = true
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
                self.availableProductIDs = []
                self.productLoadCompleted = true
            }
        }
    }

    func isProductAvailableForPurchase(_ productId: String) -> Bool {
        availableProductIDs.contains(productId)
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
                await handleSuccessfulPurchase(
                    transaction: transaction,
                    signedTransactionJWS: verification.jwsRepresentation,
                    analyticsSource: .purchaseFlow
                )
                
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
        do {
            try await AppStore.sync()
        } catch {
            #if DEBUG
            debugPrint("[StoreKit] AppStore sync failed: \(error.localizedDescription)")
            #endif
        }
        let result = await checkCurrentEntitlements()
        return result.hasAnyEntitlement
    }

    /// Refresh entitlement state without triggering a restore flow
    @discardableResult
    func refreshEntitlements() async -> Bool {
        let result = await checkCurrentEntitlements()
        return result.hasProSubscription
    }
    
    // MARK: - Private Methods
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Listen for transaction updates using StoreKit 2's Transaction.updates
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.handleSuccessfulPurchase(
                        transaction: transaction,
                        signedTransactionJWS: result.jwsRepresentation,
                        analyticsSource: .transactionUpdate
                    )
                    // Lifecycle analytics for renewals / revokes (story 41 follow-up).
                    await self.emitLifecycleFromTransaction(transaction)
                    await transaction.finish()
                } catch {
                    #if DEBUG
                    debugPrint("[StoreKit] Transaction verification failed: \(error.localizedDescription)")
                    #endif
                }
            }
        }
    }

    /// Map verified transaction fields to allow-listed lifecycle phases.
    @MainActor
    private func emitLifecycleFromTransaction(_ transaction: StoreKit.Transaction) async {
        guard ShopCatalog.isProProduct(transaction.productID) else { return }
        let sku = transaction.productID
        if transaction.revocationDate != nil {
            if lifecycleStateStore.shouldEmitTransaction(.refunded, sku: sku, transactionID: transaction.id) {
                SubscriptionLifecycleAnalytics.emit(.refunded, sku: sku)
            }
            return
        }

        if transaction.offerType == .introductory {
            if lifecycleStateStore.shouldEmitTransaction(.trialStarted, sku: sku, transactionID: transaction.id) {
                SubscriptionLifecycleAnalytics.emit(.trialStarted, sku: sku)
            }
        } else if transaction.originalID != transaction.id,
                  lifecycleStateStore.shouldEmitTransaction(.renewed, sku: sku, transactionID: transaction.id) {
            // Transaction.updates also carries ask-to-buy approvals and other
            // out-of-band transactions. A distinct original/current ID is the
            // bounded signal that this is a renewal rather than a first buy.
            SubscriptionLifecycleAnalytics.emit(.renewed, sku: sku)
        }
        await emitLifecycleFromSubscriptionStatuses(for: sku)
    }

    @MainActor
    private func emitLifecycleFromSubscriptionStatuses(for productID: String) async {
        guard let product = storeKitProducts.first(where: { $0.id == productID }),
              let subscription = product.subscription else { return }
        do {
            let statuses = try await subscription.status
            for status in statuses {
                // Product.SubscriptionInfo.Status.state is the renewal state enum.
                let raw = String(describing: status.state)
                if let phase = SubscriptionLifecycleAnalytics.phase(fromRenewalState: raw),
                   lifecycleStateStore.shouldEmitStatus(phase, sku: productID) {
                    SubscriptionLifecycleAnalytics.emit(phase, sku: productID)
                }
                if case .verified(let renewal) = status.renewalInfo {
                    if renewal.willAutoRenew == false {
                        if lifecycleStateStore.shouldEmitStatus(.cancelled, sku: productID, channel: "auto_renew") {
                            SubscriptionLifecycleAnalytics.emit(.cancelled, sku: productID)
                        }
                    } else {
                        lifecycleStateStore.markAutoRenewEnabled(sku: productID)
                    }
                }
                if raw.lowercased() == "subscribed" || raw.lowercased().hasSuffix(".subscribed") {
                    lifecycleStateStore.markSubscribed(sku: productID)
                }
            }
        } catch {
            #if DEBUG
            debugPrint("[StoreKit] subscription status read failed: \(error.localizedDescription)")
            #endif
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
            #if STOREKIT_PRICING_TERMS_AVAILABLE
            if #available(iOS 26.4, *), Self.monthlyPricingTerms(for: product) != nil {
                return try await product.purchase(options: [.billingPlanType(.monthly)])
            }
            #endif
            return try await product.purchase()
        }
    }

    #if STOREKIT_PRICING_TERMS_AVAILABLE
    @available(iOS 26.4, *)
    private static func monthlyPricingTerms(for product: Product) -> Product.SubscriptionInfo.PricingTerms? {
        guard let subscription = product.subscription else { return nil }
        let monthlyTerms = subscription.pricingTerms.filter { $0.billingPlanType == .monthly }
        return monthlyTerms.first { isTwelveMonthCommitment($0.commitmentInfo.period) } ?? monthlyTerms.first
    }
    #endif

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
    
    static func purchaseAnalyticsEvents(
        for productID: String,
        source: PurchaseAnalyticsSource
    ) -> [PurchaseAnalyticsEmission] {
        var properties = [
            "sku": productID,
            "product": productID,
            "source": source.rawValue
        ]

        if ShopCatalog.isProProduct(productID) {
            let plan = ShopCatalog.proPlan(for: productID)
            properties["product_type"] = "subscription"
            properties["tier"] = "pro"
            properties["period"] = plan.billingPlan == .monthlyCommitment ? "year" : "month"
            properties["billing_plan"] = plan.billingPlan == .monthlyCommitment ? "monthly_commitment" : "standard"
            properties["is_trial"] = "false"
            return [.init(event: .subscriptionStarted, properties: properties)]
        }

        if let credits = ShopCatalog.chatCreditAmounts[productID] {
            properties["product_type"] = "consumable"
            properties["is_consumable"] = "true"
            properties["credits"] = String(credits)
            return [.init(event: .iapPurchased, properties: properties)]
        }

        if ShopCatalog.reportProductIDs.contains(productID) {
            properties["product_type"] = "non_consumable"
            properties["is_consumable"] = "false"
            return [.init(event: .iapPurchased, properties: properties)]
        }

        return []
    }

    private func handleSuccessfulPurchase(
        transaction: StoreKit.Transaction,
        signedTransactionJWS: String,
        analyticsSource: PurchaseAnalyticsSource? = nil
    ) async {
        let shouldSyncProEntitlement = ShopCatalog.isProProduct(transaction.productID)
        let shouldSyncReportEntitlement = ShopCatalog.reportProductIDs.contains(transaction.productID)

        await MainActor.run {
            if shouldSyncProEntitlement {
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

        if let analyticsSource {
            for emission in Self.purchaseAnalyticsEvents(for: transaction.productID, source: analyticsSource) {
                Analytics.shared.track(emission.event, properties: emission.properties)
            }
        }

        if shouldSyncProEntitlement {
            await syncProEntitlement(transaction: transaction, signedTransactionJWS: signedTransactionJWS)
        }
        if shouldSyncReportEntitlement {
            await syncReportEntitlement(transaction: transaction, signedTransactionJWS: signedTransactionJWS)
        }
    }
    
    private func checkCurrentEntitlements() async -> EntitlementRefreshResult {
        var hasPro = false
        var purchasedProductIds: [String] = []
        var proTransactions: [(transaction: StoreKit.Transaction, signedTransactionJWS: String)] = []
        var reportTransactions: [(transaction: StoreKit.Transaction, signedTransactionJWS: String)] = []

        // Check for current subscription entitlements
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if ShopCatalog.isProProduct(transaction.productID) {
                    hasPro = true
                    proTransactions.append((transaction, result.jwsRepresentation))
                }
                if ShopCatalog.reportProductIDs.contains(transaction.productID) {
                    reportTransactions.append((transaction, result.jwsRepresentation))
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

        for item in proTransactions {
            await syncProEntitlement(transaction: item.transaction, signedTransactionJWS: item.signedTransactionJWS)
        }
        for item in reportTransactions {
            await syncReportEntitlement(transaction: item.transaction, signedTransactionJWS: item.signedTransactionJWS)
        }

        return EntitlementRefreshResult(
            hasProSubscription: finalHasPro,
            productIds: finalPurchasedProductIds
        )
    }

    private func syncProEntitlement(transaction: StoreKit.Transaction, signedTransactionJWS: String) async {
        guard ShopCatalog.isProProduct(transaction.productID) else { return }

        do {
            _ = try await APIServices.shared.syncSubscriptionEntitlement(
                productId: transaction.productID,
                transactionId: String(transaction.id),
                originalTransactionId: String(transaction.originalID),
                environment: String(describing: transaction.environment),
                signedTransactionJWS: signedTransactionJWS
            )
        } catch {
            #if DEBUG
            debugPrint("[StoreKit] Server subscription sync failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func syncReportEntitlement(transaction: StoreKit.Transaction, signedTransactionJWS: String) async {
        guard ShopCatalog.reportProductIDs.contains(transaction.productID) else { return }

        do {
            _ = try await APIServices.shared.syncReportEntitlement(
                productId: transaction.productID,
                transactionId: String(transaction.id),
                originalTransactionId: String(transaction.originalID),
                environment: String(describing: transaction.environment),
                signedTransactionJWS: signedTransactionJWS
            )
        } catch {
            #if DEBUG
            debugPrint("[StoreKit] Server report entitlement sync failed: \(error.localizedDescription)")
            #endif
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let purchaseCompleted = Notification.Name("purchaseCompleted")
    static let reportPurchased = Notification.Name("reportPurchased")
}
