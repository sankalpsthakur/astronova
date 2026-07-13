import Foundation
import StoreKit
import SwiftUI

// MARK: - StoreKit Error Handling

enum StoreError: Error {
    case failedVerification
}

enum PurchaseDeliveryOutcome: Equatable {
    case delivered
    case userCancelled
    case pending
    case storeKitFailure
    case serverDeliveryFailure

    var shouldFinishTransaction: Bool { self == .delivered }
    var shouldGrantLocalAccess: Bool { self == .delivered }
    var shouldEmitCompletion: Bool { self == .delivered }
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
    @MainActor private lazy var subscriptionStatusObserver = SubscriptionStatusObserver { emit in
        for await status in Product.SubscriptionInfo.Status.updates {
            guard !Task.isCancelled else { break }
            guard let snapshot = Self.subscriptionStatusSnapshot(from: status) else { continue }
            await emit(snapshot)
        }
    }

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
        let hasServerCreditBalance: Bool

        var hasAnyEntitlement: Bool {
            !productIds.isEmpty || hasServerCreditBalance
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
            await refreshSubscriptionStatusObservation()
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
                    #if DEBUG
                    debugPrint("[StoreKit] App Store Connect returned no Astronova products for: \(self.productIDs.joined(separator: ", "))")
                    #endif
                    Analytics.shared.track(.apiError, properties: [
                        "error_type": "storekit_no_products"
                    ])
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

                // Server delivery is performed inside handleSuccessfulPurchase;
                // access is granted and the transaction finished only after it
                // succeeds.
                let delivered = await handleSuccessfulPurchase(
                    transaction: transaction,
                    signedTransactionJWS: verification.jwsRepresentation,
                    analyticsSource: .purchaseFlow
                )
                let deliveryOutcome: PurchaseDeliveryOutcome = delivered ? .delivered : .serverDeliveryFailure
                guard deliveryOutcome.shouldFinishTransaction else { return false }

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

    /// Refresh entitlement state without triggering a restore flow.
    /// Reconciles local StoreKit entitlements first, then defers to the server
    /// (the source of truth) so a refunded/expired subscription is correctly
    /// revoked even if a stale local flag remains.
    @discardableResult
    func refreshEntitlements() async -> Bool {
        let result = await checkCurrentEntitlements()
        return result.hasProSubscription
    }

    /// Starts one StoreKit status listener for the current foreground session.
    /// Repeated lifecycle callbacks are intentionally idempotent.
    @MainActor
    @discardableResult
    func startSubscriptionStatusObservation() -> Bool {
        subscriptionStatusObserver.start { [weak self] snapshot in
            self?.handleSubscriptionStatusSnapshot(snapshot)
        }
    }

    /// Cancels the status listener when the app leaves foreground execution.
    @MainActor
    @discardableResult
    func stopSubscriptionStatusObservation() -> Bool {
        subscriptionStatusObserver.cancel()
    }

    /// Reads current statuses on launch/foreground to cover transitions that
    /// occurred while the process was suspended or terminated.
    @MainActor
    func refreshSubscriptionStatusObservation() async {
        for product in storeKitProducts where ShopCatalog.isProProduct(product.id) {
            guard let subscription = product.subscription else { continue }
            do {
                for status in try await subscription.status {
                    guard let snapshot = Self.subscriptionStatusSnapshot(from: status) else { continue }
                    handleSubscriptionStatusSnapshot(snapshot)
                }
            } catch {
                #if DEBUG
                debugPrint("[StoreKit] subscription status read failed: \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Listen for transaction updates using StoreKit 2's Transaction.updates
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    let delivered = await self.handleSuccessfulPurchase(
                        transaction: transaction,
                        signedTransactionJWS: result.jwsRepresentation,
                        analyticsSource: .transactionUpdate
                    )
                    let deliveryOutcome: PurchaseDeliveryOutcome = delivered ? .delivered : .serverDeliveryFailure
                    if deliveryOutcome.shouldEmitCompletion {
                        // Lifecycle events follow durable server delivery too.
                        await self.emitLifecycleFromTransaction(transaction)
                        await transaction.finish()
                    }
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
        await refreshSubscriptionStatusObservation()
    }

    @MainActor
    private func handleSubscriptionStatusSnapshot(_ snapshot: SubscriptionStatusSnapshot) {
        for phase in lifecycleStateStore.phasesToEmit(for: snapshot) {
            SubscriptionLifecycleAnalytics.emit(phase, sku: snapshot.sku)
        }
    }

    private static func subscriptionStatusSnapshot(
        from status: Product.SubscriptionInfo.Status
    ) -> SubscriptionStatusSnapshot? {
        guard case .verified(let transaction) = status.transaction,
              ShopCatalog.isProProduct(transaction.productID) else { return nil }

        let state: SubscriptionStatusSnapshot.State
        switch status.state {
        case .subscribed:
            state = .subscribed
        case .expired:
            state = .expired
        case .revoked:
            state = .revoked
        case .inGracePeriod:
            state = .gracePeriod
        case .inBillingRetryPeriod:
            state = .billingRetry
        default:
            state = .unknown
        }

        let willAutoRenew: Bool?
        if case .verified(let renewalInfo) = status.renewalInfo {
            willAutoRenew = renewalInfo.willAutoRenew
        } else {
            willAutoRenew = nil
        }

        return SubscriptionStatusSnapshot(
            sku: transaction.productID,
            state: state,
            willAutoRenew: willAutoRenew
        )
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
    ) async -> Bool {
        let shouldSyncProEntitlement = ShopCatalog.isProProduct(transaction.productID)
        let shouldSyncReportEntitlement = ShopCatalog.reportProductIDs.contains(transaction.productID)
        let shouldSyncOracleCredits = ShopCatalog.chatCreditAmounts[transaction.productID] != nil

        var authoritativeCreditBalance: Int?
        if shouldSyncProEntitlement {
            guard await syncProEntitlement(transaction: transaction, signedTransactionJWS: signedTransactionJWS) else {
                return false
            }
        } else if shouldSyncReportEntitlement {
            guard await syncReportEntitlement(transaction: transaction, signedTransactionJWS: signedTransactionJWS) else {
                return false
            }
        } else if shouldSyncOracleCredits {
            guard let balance = await syncOracleCredits(transaction: transaction, signedTransactionJWS: signedTransactionJWS) else {
                return false
            }
            authoritativeCreditBalance = balance
        } else {
            return false
        }

        let deliveredCreditBalance = authoritativeCreditBalance
        await MainActor.run {
            if shouldSyncProEntitlement {
                self.hasProSubscription = true
            }

            if let deliveredCreditBalance {
                UserDefaults.standard.set(deliveredCreditBalance, forKey: "chat_credits")
            }

            if !shouldSyncOracleCredits {
                let purchaseKey = "purchased_\(transaction.productID)"
                UserDefaults.standard.set(true, forKey: purchaseKey)
            }

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

        return true
    }
    
    private func checkCurrentEntitlements() async -> EntitlementRefreshResult {
        var sawProEntitlement = false
        var deliveredProEntitlement = false
        var deliveredProductIds: [String] = []
        var proTransactions: [(transaction: StoreKit.Transaction, signedTransactionJWS: String)] = []
        var reportTransactions: [(transaction: StoreKit.Transaction, signedTransactionJWS: String)] = []

        // Check for current subscription entitlements
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if ShopCatalog.isProProduct(transaction.productID) {
                    sawProEntitlement = true
                    proTransactions.append((transaction, result.jwsRepresentation))
                }
                if ShopCatalog.reportProductIDs.contains(transaction.productID) {
                    reportTransactions.append((transaction, result.jwsRepresentation))
                }

            } catch {
                #if DEBUG
                debugPrint("[StoreKit] Failed to verify current entitlement: \(error.localizedDescription)")
                #endif
            }
        }

        for item in proTransactions {
            if await handleSuccessfulPurchase(
                transaction: item.transaction,
                signedTransactionJWS: item.signedTransactionJWS
            ) {
                deliveredProEntitlement = true
                deliveredProductIds.append(item.transaction.productID)
            }
        }
        for item in reportTransactions {
            if await handleSuccessfulPurchase(
                transaction: item.transaction,
                signedTransactionJWS: item.signedTransactionJWS
            ) {
                deliveredProductIds.append(item.transaction.productID)
            }
        }

        var hasServerCreditBalance = false
        if let balance = try? await APIServices.shared.getOracleCreditBalance() {
            hasServerCreditBalance = balance > 0
            await MainActor.run {
                UserDefaults.standard.set(balance, forKey: "chat_credits")
            }
        }

        let finalHasPro = sawProEntitlement && deliveredProEntitlement
        await MainActor.run { self.hasProSubscription = finalHasPro }

        return EntitlementRefreshResult(
            hasProSubscription: finalHasPro,
            productIds: deliveredProductIds,
            hasServerCreditBalance: hasServerCreditBalance
        )
    }

    private func syncProEntitlement(transaction: StoreKit.Transaction, signedTransactionJWS: String) async -> Bool {
        guard ShopCatalog.isProProduct(transaction.productID) else { return false }

        do {
            let response = try await APIServices.shared.syncSubscriptionEntitlement(
                productId: transaction.productID,
                transactionId: String(transaction.id),
                originalTransactionId: String(transaction.originalID),
                environment: String(describing: transaction.environment),
                signedTransactionJWS: signedTransactionJWS
            )
            return response.isActive && response.productId == transaction.productID
        } catch {
            #if DEBUG
            debugPrint("[StoreKit] Server subscription sync failed: \(error.localizedDescription)")
            #endif
            return false
        }
    }

    private func syncReportEntitlement(transaction: StoreKit.Transaction, signedTransactionJWS: String) async -> Bool {
        guard ShopCatalog.reportProductIDs.contains(transaction.productID) else { return false }

        do {
            let response = try await APIServices.shared.syncReportEntitlement(
                productId: transaction.productID,
                transactionId: String(transaction.id),
                originalTransactionId: String(transaction.originalID),
                environment: String(describing: transaction.environment),
                signedTransactionJWS: signedTransactionJWS
            )
            return response.productId == transaction.productID && response.transactionId == String(transaction.id)
        } catch {
            #if DEBUG
            debugPrint("[StoreKit] Server report entitlement sync failed: \(error.localizedDescription)")
            #endif
            return false
        }
    }

    private func syncOracleCredits(transaction: StoreKit.Transaction, signedTransactionJWS: String) async -> Int? {
        guard ShopCatalog.chatCreditAmounts[transaction.productID] != nil else { return nil }
        do {
            let response = try await APIServices.shared.syncOracleCredits(
                productId: transaction.productID,
                transactionId: String(transaction.id),
                originalTransactionId: String(transaction.originalID),
                environment: String(describing: transaction.environment),
                signedTransactionJWS: signedTransactionJWS
            )
            guard response.productId == transaction.productID else { return nil }
            return response.balance
        } catch {
            #if DEBUG
            debugPrint("[StoreKit] Server Oracle credit delivery failed: \(error.localizedDescription)")
            #endif
            return nil
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let purchaseCompleted = Notification.Name("purchaseCompleted")
    static let reportPurchased = Notification.Name("reportPurchased")
}
