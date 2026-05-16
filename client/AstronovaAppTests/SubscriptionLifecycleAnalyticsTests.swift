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
}
