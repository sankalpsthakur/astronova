import SwiftUI

enum PaywallContext: String {
    case general
    case chatLimit
    case report
    case home
}

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storeKitManager = StoreKitManager.shared
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var purchaseResult: PurchaseResult?
    @State private var paywallShownAt: Date?
    @State private var showingReportShop = false
    @State private var showingChatPackages = false
    @State private var selectedPlanProductId = ShopCatalog.defaultProProductID

    private let context: PaywallContext

    private enum PurchaseResult: Identifiable {
        case success
        case error(String)
        case restored
        case restoredNone

        var id: String {
            switch self {
            case .success: return "success"
            case .error(let msg): return "error-\(msg)"
            case .restored: return "restored"
            case .restoredNone: return "restoredNone"
            }
        }
    }
    
    init(context: PaywallContext = .general) {
        self.context = context
    }

    private var paywallVariant: String {
        // Wave 13 — prefer AstronovaFlags (portfolio feature flag service)
        // when it has been configured, fall back to RemoteConfigService.
        let flag = AstronovaFlags.shared.paywallVariant.rawValue
        if flag != AstronovaPaywallVariant.default.rawValue {
            return flag
        }
        return RemoteConfigService.shared.string(forKey: "paywall_variant", default: "A")
    }

    private var heroIcon: String {
        switch context {
        case .chatLimit:
            return "bubble.left.and.bubble.right.fill"
        case .report:
            return "doc.text.fill"
        case .home:
            return "sparkles"
        case .general:
            return "sparkles"
        }
    }

    private var heroTitle: String {
        switch context {
        case .chatLimit:
            return "Continue Your Journey"
        case .report:
            return "Deeper Journeys"
        case .home:
            return "Deeper Journeys"
        case .general:
            return "Deeper Journeys"
        }
    }

    private var heroSubtitle: String {
        switch (context, paywallVariant) {
        case (.chatLimit, _):
            return "You’ve hit today’s free limit. Unlock deeper journeys for unlimited guidance."
        case (.report, _):
            return "Unlock deeper journeys: complete bundles, saved progress, and unlimited guidance."
        case (.home, "B"):
            return "Your next chapter: premium guidance and unlimited chat."
        default:
            return "Unlimited chat, complete journeys, and deeper guidance."
        }
    }

    private var featureRows: [(icon: String, text: String)] {
        switch (context, paywallVariant) {
        case (.chatLimit, "C"):
            return [
                ("bubble.left.and.bubble.right.fill", "Unlimited Ask (AI chat)"),
                ("sparkles", "Priority cosmic insights"),
                ("doc.text.fill", "All journey paths included"),
                ("clock.fill", "Cancel anytime"),
            ]
        case (.chatLimit, _):
            return [
                ("bubble.left.and.bubble.right.fill", "Unlimited Ask (AI chat)"),
                ("bolt.fill", "Continue instantly — no waiting"),
                ("doc.text.fill", "All journey paths included"),
                ("clock.fill", "Cancel anytime"),
            ]
        case (.report, _):
            return [
                ("doc.text.fill", "All journey paths included"),
                ("tray.full.fill", "Saved to your library"),
                ("bubble.left.and.bubble.right.fill", "Unlimited Ask (AI chat)"),
                ("clock.fill", "Cancel anytime"),
            ]
        default:
            return [
                ("bubble.left.and.bubble.right.fill", "Unlimited Ask (AI chat)"),
                ("doc.text.fill", "All journey paths included"),
                ("heart.fill", "Love, Career, Money, Health + more"),
                ("clock.fill", "Cancel anytime"),
            ]
        }
    }
    
    private var selectedPlan: ShopCatalog.ProPlan {
        ShopCatalog.proPlan(for: selectedPlanProductId)
    }

    private func billingDisplayPrice(for plan: ShopCatalog.ProPlan) -> String {
        storeKitManager.monthlyBillingPlanPrices[plan.productId] ??
        plan.fallbackBillingDisplayPrice
    }

    private func commitmentDisplayPrice(for plan: ShopCatalog.ProPlan) -> String? {
        storeKitManager.commitmentDisplayPrices[plan.productId] ??
        plan.fallbackCommitmentDisplayPrice
    }

    private var trialOfferText: String {
        "\(ShopCatalog.proIntroOfferDescription), then \(billingDisplayPrice(for: selectedPlan)) \(selectedPlan.billingCaption)"
    }
    
    private var purchaseButtonTitle: String {
        isPurchasing ? "Starting trial..." : "Start \(selectedPlan.title)"
    }

    // MARK: - App Store Compliance URLs

    private let termsURL = URL(string: "https://astronova.onrender.com/terms")!
    private let privacyURL = URL(string: "https://astronova.onrender.com/privacy")!
    private let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    var body: some View {
        ScrollView {
            VStack(spacing: Cosmic.Spacing.xl) {
                // Hero header
                VStack(spacing: Cosmic.Spacing.sm) {
                    Image(systemName: heroIcon)
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient.cosmicAntiqueGold
                        )
                        .padding(.bottom, Cosmic.Spacing.xs)
                        .accessibilityHidden(true)

                    Text(heroTitle)
                        .font(.cosmicDisplay)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Text(heroSubtitle)
                        .font(.cosmicBody)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                .padding(.top, Cosmic.Spacing.xl)

                proPlanPicker

                // Features list
                VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
                    PaywallFeatureRow(icon: "gift.fill", text: trialOfferText)
                    ForEach(featureRows, id: \.text) { row in
                        PaywallFeatureRow(icon: row.icon, text: row.text)
                    }
                }
                .padding(Cosmic.Spacing.screen)
                .background(Color.cosmicSurface)
                .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                        .stroke(Color.cosmicGold.opacity(0.2), lineWidth: Cosmic.Border.thin)
                )

                // Divider
                HStack {
                    Rectangle()
                        .fill(Color.cosmicTextTertiary.opacity(0.3))
                        .frame(height: 1)
                    Text("OR")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                    Rectangle()
                        .fill(Color.cosmicTextTertiary.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.vertical, Cosmic.Spacing.sm)

                // Alternative CTAs
                VStack(spacing: Cosmic.Spacing.sm) {
                    Button {
                        showingReportShop = true
                    } label: {
                        HStack(spacing: Cosmic.Spacing.sm) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundStyle(Color.cosmicGold)
                            Text("Open a deeper journey (from $12.99)")
                                .font(.cosmicCallout)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.cosmicCaption)
                        }
                        .foregroundStyle(Color.cosmicTextPrimary)
                    }
                    .buttonStyle(.cosmicSecondary)
                    .accessibilityIdentifier(AccessibilityID.buyDetailedReportButton)

                    Button {
                        showingChatPackages = true
                    } label: {
                        HStack(spacing: Cosmic.Spacing.sm) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .foregroundStyle(Color.cosmicAmethyst)
                            Text("Get chat packages (no subscription)")
                                .font(.cosmicCallout)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.cosmicCaption)
                        }
                        .foregroundStyle(Color.cosmicTextPrimary)
                    }
                    .buttonStyle(.cosmicSecondary)
                    .accessibilityIdentifier(AccessibilityID.buyChatPackagesButton)
                }
            }
            .padding(.horizontal, Cosmic.Spacing.screen)
            .padding(.bottom, 220)
        }
        .background(Color.cosmicBackground)
        .safeAreaInset(edge: .bottom) {
            paywallFooter
        }
        .sheet(isPresented: $showingReportShop) {
            InlineReportsStoreSheet()
        }
        .sheet(isPresented: $showingChatPackages) {
            ChatPackagesSheet()
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.cosmicTextTertiary.opacity(0.7))
                    .padding(Cosmic.Spacing.md)
            }
            .accessibilityLabel("Close")
            .accessibilityHint("Dismisses the paywall")
            .accessibilityIdentifier("paywallCloseButton")
            .accessibleIconButton()
        }
        .accessibilityIdentifier(AccessibilityID.paywallView)
        .onAppear {
            paywallShownAt = Date()
            Analytics.shared.track(
                .paywallShown,
                properties: [
                    "variant": paywallVariant,
                    "context": context.rawValue,
                    "trigger": context.rawValue,
                    "paywall_id": "astronova_pro_\(paywallVariant)",
                    "screen": context.rawValue
                ]
            )
        }
        .onDisappear {
            // Wave 13 — paywall_dismissed (only if the user didn't convert)
            let didConvert: Bool = {
                if case .success = purchaseResult { return true }
                return false
            }()
            if !didConvert {
                let visibleSeconds = paywallShownAt.map { Int(Date().timeIntervalSince($0)) } ?? 0
                Analytics.shared.track(
                    .paywallDismissed,
                    properties: [
                        "paywall_id": "astronova_pro_\(paywallVariant)",
                        "context": context.rawValue,
                        "time_visible_s": String(visibleSeconds)
                    ]
                )
            }
        }
        .task {
            await storeKitManager.loadProducts()
        }
        .alert(item: $purchaseResult) { result in
            switch result {
            case .success:
                return Alert(
                    title: Text("Welcome to Pro!"),
                    message: Text("Your subscription is now active. Enjoy unlimited access to all features."),
                    dismissButton: .default(Text("Continue")) {
                        dismiss()
                    }
                )
            case .error(let message):
                return Alert(
                    title: Text("Purchase Failed"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            case .restored:
                return Alert(
                    title: Text("Purchases Restored"),
                    message: Text("Your Pro subscription has been restored. Welcome back!"),
                    dismissButton: .default(Text("Continue")) {
                        dismiss()
                    }
                )
            case .restoredNone:
                return Alert(
                    title: Text("No Purchases Found"),
                    message: Text("We couldn't find any previous purchases to restore."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private var paywallFooter: some View {
        VStack(spacing: Cosmic.Spacing.sm) {
            Button {
                CosmicHaptics.medium()
                Task { await purchasePro() }
            } label: {
                HStack(spacing: Cosmic.Spacing.sm) {
                    if isPurchasing {
                        ProgressView()
                            .tint(Color.cosmicVoid)
                    }
                    Text(purchaseButtonTitle)
                        .font(.cosmicBodyEmphasis)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
            }
            .buttonStyle(.cosmicPrimary)
            .accessibilityIdentifier(AccessibilityID.startProButton)
            .accessibilityHint("Starts your Pro subscription")

            Button {
                CosmicHaptics.light()
                Task { await restorePurchases() }
            } label: {
                HStack(spacing: Cosmic.Spacing.xs) {
                    if isRestoring { ProgressView() }
                    Text(isRestoring ? "Restoring..." : "Restore Purchases")
                        .font(.cosmicCallout)
                }
            }
            .foregroundStyle(Color.cosmicTextSecondary)
            .accessibilityIdentifier(AccessibilityID.restorePurchasesButton)
            .accessibilityHint("Restores previous purchases")

            Text("\(ShopCatalog.proIntroOfferDescription), \(selectedPlan.renewalCadenceDescription) at \(billingDisplayPrice(for: selectedPlan)) per month until canceled. Cancel at least 24 hours before renewal in Settings → Apple ID → Subscriptions.")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Cosmic.Spacing.sm) {
                Link("Terms", destination: termsURL)
                Text("•")
                    .foregroundStyle(Color.cosmicTextTertiary)
                Link("Privacy", destination: privacyURL)
                Text("•")
                    .foregroundStyle(Color.cosmicTextTertiary)
                Link("Manage", destination: manageSubscriptionsURL)
            }
            .font(.cosmicCaption)
            .foregroundStyle(Color.cosmicGold)
        }
        .padding(.horizontal, Cosmic.Spacing.screen)
        .padding(.top, Cosmic.Spacing.sm)
        .padding(.bottom, Cosmic.Spacing.xs)
        .background(.regularMaterial)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.paywallFooter)
    }

    private var proPlanPicker: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            Text("Choose Pro")
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)

            ForEach(ShopCatalog.proPlans) { plan in
                let isSelected = selectedPlanProductId == plan.productId
                Button {
                    CosmicHaptics.light()
                    selectedPlanProductId = plan.productId
                } label: {
                    HStack(spacing: Cosmic.Spacing.sm) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18))
                            .foregroundStyle(isSelected ? Color.cosmicGold : Color.cosmicTextTertiary)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                            HStack(spacing: Cosmic.Spacing.xs) {
                                Text(plan.title)
                                    .font(.cosmicBodyEmphasis)
                                if let badge = plan.badge {
                                    Text(badge.uppercased())
                                        .font(.cosmicCaptionEmphasis)
                                        .foregroundStyle(Color.cosmicVoid)
                                        .padding(.horizontal, Cosmic.Spacing.xs)
                                        .padding(.vertical, 2)
                                        .background(Color.cosmicGold, in: Capsule())
                                }
                            }

                            Text("\(billingDisplayPrice(for: plan)) \(plan.billingCaption)")
                                .font(.cosmicCallout)
                                .foregroundStyle(Color.cosmicTextPrimary)

                            if plan.billingPlan == .monthlyCommitment, let commitmentPrice = commitmentDisplayPrice(for: plan) {
                                Text("\(commitmentPrice) first-year commitment")
                                    .font(.cosmicCaption)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                            } else {
                                Text(plan.renewalCadenceDescription)
                                    .font(.cosmicCaption)
                                    .foregroundStyle(Color.cosmicTextSecondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(Cosmic.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(isSelected ? Color.cosmicGold.opacity(0.14) : Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                            .stroke(isSelected ? Color.cosmicGold : Color.cosmicGold.opacity(0.12), lineWidth: Cosmic.Border.thin)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("proPlanOption_\(plan.productId)")
                .accessibilityLabel("\(plan.title), \(billingDisplayPrice(for: plan)) \(plan.billingCaption)")
            }
        }
    }
    
    private func purchasePro() async {
        if await MainActor.run(body: { isPurchasing }) { return }
        await MainActor.run { isPurchasing = true }
        let plan = await MainActor.run { selectedPlan }

        defer {
            Task { @MainActor in isPurchasing = false }
        }

        #if DEBUG
        // UI tests only: bypass StoreKit dialogs using mock store
        if UserDefaults.standard.bool(forKey: "mock_purchases_enabled") {
            let success = await BasicStoreManager.shared.purchaseProduct(productId: plan.productId)
            if success {
                Analytics.shared.track(
                    .paywallConversion,
                    properties: ["product": plan.productId, "context": context.rawValue, "source": "paywall"]
                )
                Analytics.shared.track(.purchaseSuccess, properties: ["product": plan.productId])
                await MainActor.run {
                    OracleQuotaManager.shared.checkSubscription()
                    purchaseResult = .success
                }
            } else {
                await MainActor.run {
                    purchaseResult = .error("Purchase could not be completed. Please try again.")
                }
            }
            return
        }
        #endif

        // Production: Use only StoreKit for purchases
        let success = await storeKitManager.purchaseProduct(productId: plan.productId, billingPlan: plan.billingPlan)
        if success {
            Analytics.shared.track(
                .paywallConversion,
                properties: ["product": plan.productId, "context": context.rawValue, "source": "paywall"]
            )
            Analytics.shared.track(.purchaseSuccess, properties: ["product": plan.productId])
            // Wave 13 — portfolio-standard subscription_started / iap_purchased
            let isSubscription = ShopCatalog.isProProduct(plan.productId)
            if isSubscription {
                Analytics.shared.track(.subscriptionStarted, properties: [
                    "sku": plan.productId,
                    "period": plan.billingPlan == .monthlyCommitment ? "year" : "month",
                    "is_trial": "false",
                    "tier": "pro"
                ])
            } else {
                Analytics.shared.track(.iapPurchased, properties: [
                    "sku": plan.productId,
                    "is_consumable": "true"
                ])
            }
            await MainActor.run {
                OracleQuotaManager.shared.checkSubscription()
                purchaseResult = .success
            }
        } else {
            await MainActor.run {
                purchaseResult = .error("Purchase could not be completed. You were not charged.")
            }
        }
    }

    private func restorePurchases() async {
        if await MainActor.run(body: { isRestoring }) { return }
        await MainActor.run { isRestoring = true }

        defer {
            Task { @MainActor in isRestoring = false }
        }

        #if DEBUG
        if UserDefaults.standard.bool(forKey: "mock_purchases_enabled") {
            let restored = await BasicStoreManager.shared.restorePurchases()
            await MainActor.run {
                OracleQuotaManager.shared.checkSubscription()
                purchaseResult = restored ? .restored : .restoredNone
            }
            return
        }
        #endif

        let restored = await storeKitManager.restorePurchases()
        await MainActor.run {
            OracleQuotaManager.shared.checkSubscription()
            purchaseResult = restored ? .restored : .restoredNone
        }
    }
}

// MARK: - Feature Row Component

private struct PaywallFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Cosmic.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.cosmicGold)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(text)
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextPrimary)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.cosmicSuccess)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

#Preview {
    PaywallView()
}
