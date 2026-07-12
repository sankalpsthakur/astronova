import XCTest
@testable import AstronovaApp

final class SubscriptionLifecycleAnalyticsTests: XCTestCase {

    override func setUpWithError() throws {
        PortfolioAnalytics.shared._resetForTests()
    }

    override func tearDownWithError() throws {
        PortfolioAnalytics.shared._resetForTests()
    }

    func testProPurchaseBuildsSubscriptionStartedEvent() {
        let emissions = StoreKitManager.purchaseAnalyticsEvents(
            for: ShopCatalog.proMonthlyProductID,
            source: .purchaseFlow
        )

        XCTAssertEqual(emissions.count, 1)
        XCTAssertEqual(emissions.first?.event, .subscriptionStarted)
        XCTAssertEqual(emissions.first?.properties["sku"], ShopCatalog.proMonthlyProductID)
        XCTAssertEqual(emissions.first?.properties["product_type"], "subscription")
        XCTAssertEqual(emissions.first?.properties["tier"], "pro")
        XCTAssertEqual(emissions.first?.properties["period"], "month")
        XCTAssertEqual(emissions.first?.properties["billing_plan"], "standard")
        XCTAssertEqual(emissions.first?.properties["is_trial"], "false")
        XCTAssertEqual(emissions.first?.properties["source"], "purchase_flow")
    }

    func testConsumablePurchaseBuildsIAPPurchasedEventWithCredits() {
        let emissions = StoreKitManager.purchaseAnalyticsEvents(
            for: "chat_credits_15",
            source: .purchaseFlow
        )

        XCTAssertEqual(emissions.count, 1)
        XCTAssertEqual(emissions.first?.event, .iapPurchased)
        XCTAssertEqual(emissions.first?.properties["sku"], "chat_credits_15")
        XCTAssertEqual(emissions.first?.properties["product_type"], "consumable")
        XCTAssertEqual(emissions.first?.properties["is_consumable"], "true")
        XCTAssertEqual(emissions.first?.properties["credits"], "150")
    }

    func testPurchaseDeliveryTimingOnlyCompletesAfterServerDelivery() {
        XCTAssertTrue(PurchaseDeliveryOutcome.delivered.shouldFinishTransaction)
        XCTAssertTrue(PurchaseDeliveryOutcome.delivered.shouldGrantLocalAccess)
        XCTAssertTrue(PurchaseDeliveryOutcome.delivered.shouldEmitCompletion)

        let incompleteOutcomes: [PurchaseDeliveryOutcome] = [
            .userCancelled,
            .pending,
            .storeKitFailure,
            .serverDeliveryFailure
        ]
        for outcome in incompleteOutcomes {
            XCTAssertFalse(outcome.shouldFinishTransaction)
            XCTAssertFalse(outcome.shouldGrantLocalAccess)
            XCTAssertFalse(outcome.shouldEmitCompletion)
        }
    }

    func testRestoreUsesTheSameServerDeliveredCompletionBoundary() {
        let restoredVerifiedEntitlement = PurchaseDeliveryOutcome.delivered
        XCTAssertTrue(restoredVerifiedEntitlement.shouldGrantLocalAccess)

        let restoreServerFailure = PurchaseDeliveryOutcome.serverDeliveryFailure
        XCTAssertFalse(restoreServerFailure.shouldGrantLocalAccess)
        XCTAssertFalse(restoreServerFailure.shouldEmitCompletion)
    }

    func testReportPurchaseBuildsNonConsumableIAPPurchasedEvent() {
        let emissions = StoreKitManager.purchaseAnalyticsEvents(
            for: "report_love",
            source: .purchaseFlow
        )

        XCTAssertEqual(emissions.count, 1)
        XCTAssertEqual(emissions.first?.event, .iapPurchased)
        XCTAssertEqual(emissions.first?.properties["sku"], "report_love")
        XCTAssertEqual(emissions.first?.properties["product_type"], "non_consumable")
        XCTAssertEqual(emissions.first?.properties["is_consumable"], "false")
    }

    func testLegacyPurchaseSuccessDoesNotFanOutAsIAP() {
        var captured: [PortfolioEvent] = []
        PortfolioAnalytics.shared.testEventSink = { event, _ in
            captured.append(event)
        }

        Analytics.shared.track(.purchaseSuccess, properties: ["product": ShopCatalog.proMonthlyProductID])

        XCTAssertTrue(captured.isEmpty, "Legacy purchase_success lacks product type and must not be treated as iap_purchased")
    }

    func testTypedPurchaseEventsFanOutToPortfolioAnalytics() {
        var captured: [(PortfolioEvent, [String: String])] = []
        PortfolioAnalytics.shared.testEventSink = { event, properties in
            captured.append((event, properties))
        }

        Analytics.shared.track(.subscriptionStarted, properties: ["sku": ShopCatalog.proMonthlyProductID])
        Analytics.shared.track(.iapPurchased, properties: ["sku": "chat_credits_5"])

        XCTAssertEqual(captured.map(\.0), [.subscriptionStarted, .iapPurchased])
        XCTAssertEqual(captured.first?.1["sku"], ShopCatalog.proMonthlyProductID)
        XCTAssertEqual(captured.last?.1["sku"], "chat_credits_5")
    }

    func testLifecyclePhasesEmitAllowListedEvents() {
        var captured: [PortfolioEvent] = []
        PortfolioAnalytics.shared.testEventSink = { event, _ in
            captured.append(event)
        }

        SubscriptionLifecycleAnalytics.emit(.renewed, sku: ShopCatalog.proMonthlyProductID)
        SubscriptionLifecycleAnalytics.emit(.cancelled, sku: ShopCatalog.proMonthlyProductID)
        SubscriptionLifecycleAnalytics.emit(.grace, sku: ShopCatalog.proMonthlyProductID)
        SubscriptionLifecycleAnalytics.emit(.billingRetry, sku: ShopCatalog.proMonthlyProductID)
        SubscriptionLifecycleAnalytics.emit(.lapsed, sku: ShopCatalog.proMonthlyProductID)
        SubscriptionLifecycleAnalytics.emit(.refunded, sku: ShopCatalog.proMonthlyProductID)
        SubscriptionLifecycleAnalytics.emit(.trialStarted, sku: ShopCatalog.proMonthlyProductID)

        XCTAssertEqual(captured, [
            .subscriptionRenewed,
            .subscriptionCancelled,
            .subscriptionGrace,
            .subscriptionBillingRetry,
            .subscriptionLapsed,
            .subscriptionRefunded,
            .trialStarted
        ])
    }

    func testSubscribedStatusDoesNotImplyRenewalAndRevokedMapsToRefund() {
        XCTAssertNil(SubscriptionLifecycleAnalytics.phase(fromRenewalState: "subscribed"))
        XCTAssertNil(SubscriptionLifecycleAnalytics.phase(fromRenewalState: "RenewalState.subscribed"))
        XCTAssertEqual(SubscriptionLifecycleAnalytics.phase(fromRenewalState: "expired"), .lapsed)
        XCTAssertEqual(SubscriptionLifecycleAnalytics.phase(fromRenewalState: "RenewalState.revoked"), .refunded)
    }

    func testStatusDecisionDetectsTransitionsWithoutTreatingSubscribedAsRenewal() {
        let sku = ShopCatalog.proMonthlyProductID

        XCTAssertEqual(
            SubscriptionStatusDecisionEngine.phases(for: .init(sku: sku, state: .subscribed, willAutoRenew: true)),
            []
        )
        XCTAssertEqual(
            SubscriptionStatusDecisionEngine.phases(for: .init(sku: sku, state: .subscribed, willAutoRenew: false)),
            [.cancelled]
        )
        XCTAssertEqual(
            SubscriptionStatusDecisionEngine.phases(for: .init(sku: sku, state: .gracePeriod, willAutoRenew: true)),
            [.grace]
        )
        XCTAssertEqual(
            SubscriptionStatusDecisionEngine.phases(for: .init(sku: sku, state: .billingRetry, willAutoRenew: true)),
            [.billingRetry]
        )
        XCTAssertEqual(
            SubscriptionStatusDecisionEngine.phases(for: .init(sku: sku, state: .expired, willAutoRenew: nil)),
            [.lapsed]
        )
        XCTAssertEqual(
            SubscriptionStatusDecisionEngine.phases(for: .init(sku: sku, state: .revoked, willAutoRenew: nil)),
            [.refunded]
        )
    }

    func testStatusStateEmitsOnceUntilARealTransitionOccurs() throws {
        let suiteName = "SubscriptionLifecycleStateTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = SubscriptionLifecycleStateStore(defaults: defaults, keyPrefix: "test.observer.")
        let sku = ShopCatalog.proMonthlyProductID

        XCTAssertEqual(store.phasesToEmit(for: .init(sku: sku, state: .gracePeriod, willAutoRenew: true)), [.grace])
        XCTAssertEqual(store.phasesToEmit(for: .init(sku: sku, state: .gracePeriod, willAutoRenew: true)), [])
        XCTAssertEqual(store.phasesToEmit(for: .init(sku: sku, state: .subscribed, willAutoRenew: true)), [])
        XCTAssertEqual(store.phasesToEmit(for: .init(sku: sku, state: .gracePeriod, willAutoRenew: true)), [.grace])

        XCTAssertEqual(store.phasesToEmit(for: .init(sku: sku, state: .subscribed, willAutoRenew: false)), [.cancelled])
        XCTAssertEqual(store.phasesToEmit(for: .init(sku: sku, state: .subscribed, willAutoRenew: false)), [])
        XCTAssertEqual(store.phasesToEmit(for: .init(sku: sku, state: .subscribed, willAutoRenew: true)), [])
        XCTAssertEqual(store.phasesToEmit(for: .init(sku: sku, state: .subscribed, willAutoRenew: false)), [.cancelled])
    }

    @MainActor
    func testObserverStartsOnceAndCancelsCleanly() async {
        var continuation: AsyncStream<SubscriptionStatusSnapshot>.Continuation?
        let stream = AsyncStream<SubscriptionStatusSnapshot> { continuation = $0 }
        let observer = SubscriptionStatusObserver { emit in
            for await snapshot in stream {
                guard !Task.isCancelled else { break }
                await emit(snapshot)
            }
        }
        var received: [SubscriptionStatusSnapshot] = []
        let first = SubscriptionStatusSnapshot(
            sku: ShopCatalog.proMonthlyProductID,
            state: .gracePeriod,
            willAutoRenew: true
        )

        XCTAssertTrue(observer.start { received.append($0) })
        XCTAssertFalse(observer.start { received.append($0) })
        continuation?.yield(first)
        for _ in 0..<20 where received.isEmpty {
            await Task.yield()
        }
        XCTAssertEqual(received, [first])

        XCTAssertTrue(observer.cancel())
        XCTAssertFalse(observer.cancel())
        XCTAssertFalse(observer.isRunning)
        continuation?.yield(.init(sku: first.sku, state: .expired, willAutoRenew: false))
        continuation?.finish()
        for _ in 0..<5 {
            await Task.yield()
        }
        XCTAssertEqual(received, [first])
    }

    func testLifecycleStateStoreDeduplicatesTransactionAndStatusReplays() throws {
        let suiteName = "SubscriptionLifecycleAnalyticsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = SubscriptionLifecycleStateStore(defaults: defaults, keyPrefix: "test.lifecycle.")
        let sku = ShopCatalog.proMonthlyProductID

        XCTAssertTrue(store.shouldEmitTransaction(.renewed, sku: sku, transactionID: 200))
        XCTAssertFalse(store.shouldEmitTransaction(.renewed, sku: sku, transactionID: 200))
        XCTAssertTrue(store.shouldEmitTransaction(.renewed, sku: sku, transactionID: 201))

        XCTAssertTrue(store.shouldEmitStatus(.grace, sku: sku))
        XCTAssertFalse(store.shouldEmitStatus(.grace, sku: sku))
        store.markSubscribed(sku: sku)
        XCTAssertTrue(store.shouldEmitStatus(.grace, sku: sku))
        XCTAssertTrue(store.shouldEmitStatus(.cancelled, sku: sku, channel: "auto_renew"))
        XCTAssertFalse(store.shouldEmitStatus(.cancelled, sku: sku, channel: "auto_renew"))

        store.markAutoRenewEnabled(sku: sku)
        XCTAssertTrue(store.shouldEmitStatus(.cancelled, sku: sku, channel: "auto_renew"))
    }

    func testRequestIdGeneratorIsNonEmptyAndUnique() {
        let a = NetworkClient.makeRequestId()
        let b = NetworkClient.makeRequestId()
        XCTAssertFalse(a.isEmpty)
        XCTAssertFalse(b.isEmpty)
        XCTAssertNotEqual(a, b)
    }

    func testNetworkAnalyticsRouteDropsQueriesAndIdentifiers() {
        XCTAssertEqual(
            NetworkClient.analyticsRoute(for: "/api/v1/location/search?q=private-place"),
            "/api/v1/location/search"
        )
        XCTAssertEqual(
            NetworkClient.analyticsRoute(for: "/api/v1/reports/12345"),
            "/api/v1/reports/:id"
        )
        XCTAssertEqual(
            NetworkClient.analyticsRoute(for: "/api/v1/reports/18D4AF04-FA01-4F2A-82D6-B900D47D4E0A"),
            "/api/v1/reports/:id"
        )
    }
}
