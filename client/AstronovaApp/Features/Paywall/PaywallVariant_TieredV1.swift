import SwiftUI

/// Astronova paywall — tiered_v1 variant.
///
/// Differences vs control:
///   - 12-month plan pre-selected on appear (vs picker default).
///   - 12-month row carries a "Most chosen" highlight and a price-anchor.
///   - Monthly row de-emphasised (alpha + smaller type), still selectable.
///   - Alternative IAP CTAs (report shop, chat packages) collapsed under a
///     "Other ways to unlock" disclosure so the subscription gets the focus.
///
/// Purchase flow is unchanged — we reuse `StoreKitManager` + the same product
/// IDs, this view is a *skin* over the control view's data model.
struct PaywallVariant_TieredV1: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storeKitManager = StoreKitManager.shared
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var purchaseResult: PurchaseResult?
    @State private var showingReportShop = false
    @State private var showingChatPackages = false
    @State private var showOtherOptions = false
    @State private var selectedPlanProductId = ShopCatalog.pro12MonthCommitmentProductID

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

    // MARK: - App Store Compliance URLs

    private let termsURL = URL(string: "https://astronova.onrender.com/terms")!
    private let privacyURL = URL(string: "https://astronova.onrender.com/privacy")!
    private let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    var body: some View {
        ScrollView {
            VStack(spacing: Cosmic.Spacing.xl) {
                hero
                annualHeroCard
                monthlyDemotedRow
                featureList
                otherOptionsDisclosure
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
            Analytics.shared.track(
                .paywallShown,
                properties: [
                    "variant": "tiered_v1",
                    "experiment": "astronova_paywall_v1",
                    "context": context.rawValue
                ]
            )
        }
        .task {
            await storeKitManager.loadProducts()
        }
        .alert(item: $purchaseResult) { result in
            switch result {
            case .success:
                return Alert(
                    title: Text("Welcome to Pro!"),
                    message: Text("Your subscription is now active."),
                    dismissButton: .default(Text("Continue")) { dismiss() }
                )
            case .error(let message):
                return Alert(title: Text("Purchase Failed"), message: Text(message), dismissButton: .default(Text("OK")))
            case .restored:
                return Alert(
                    title: Text("Purchases Restored"),
                    message: Text("Your Pro subscription has been restored."),
                    dismissButton: .default(Text("Continue")) { dismiss() }
                )
            case .restoredNone:
                return Alert(title: Text("No Purchases Found"),
                             message: Text("We couldn't find any previous purchases to restore."),
                             dismissButton: .default(Text("OK")))
            }
        }
    }

    private var hero: some View {
        VStack(spacing: Cosmic.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(LinearGradient.cosmicAntiqueGold)
                .padding(.bottom, Cosmic.Spacing.xs)
                .accessibilityHidden(true)
            Text("Deeper Journeys")
                .font(.cosmicDisplay)
                .foregroundStyle(Color.cosmicTextPrimary)
            Text("Unlimited chat, complete journeys, deeper guidance.")
                .font(.cosmicBody)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
        .padding(.top, Cosmic.Spacing.xl)
    }

    private var annualHeroCard: some View {
        let plan = ShopCatalog.proPlans.first { $0.productId == ShopCatalog.pro12MonthCommitmentProductID } ?? ShopCatalog.proPlans[0]
        let isSelected = selectedPlanProductId == plan.productId
        return Button {
            CosmicHaptics.light()
            selectedPlanProductId = plan.productId
        } label: {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                HStack(spacing: Cosmic.Spacing.xs) {
                    Text("MOST CHOSEN")
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(Color.cosmicVoid)
                        .padding(.horizontal, Cosmic.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(Color.cosmicGold, in: Capsule())
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? Color.cosmicGold : Color.cosmicTextTertiary)
                        .accessibilityHidden(true)
                }
                Text(plan.title)
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Text("\(billingDisplayPrice(for: plan)) \(plan.billingCaption)")
                    .font(.cosmicBodyEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
                if let commitment = commitmentDisplayPrice(for: plan) {
                    Text("\(commitment) first-year commitment")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                Text(ShopCatalog.proIntroOfferDescription)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicGold)
            }
            .padding(Cosmic.Spacing.screen)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cosmicGold.opacity(0.14), in: RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .stroke(Color.cosmicGold, lineWidth: Cosmic.Border.thick)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("proPlanOption_\(plan.productId)")
    }

    private var monthlyDemotedRow: some View {
        let plan = ShopCatalog.proPlans.first { $0.productId == ShopCatalog.proMonthlyProductID } ?? ShopCatalog.proPlans[0]
        let isSelected = selectedPlanProductId == plan.productId
        return Button {
            CosmicHaptics.light()
            selectedPlanProductId = plan.productId
        } label: {
            HStack(spacing: Cosmic.Spacing.sm) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? Color.cosmicGold : Color.cosmicTextTertiary)
                Text(plan.title)
                    .font(.cosmicCallout)
                Spacer()
                Text("\(billingDisplayPrice(for: plan)) \(plan.billingCaption)")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
            .padding(Cosmic.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .stroke(Color.cosmicGold.opacity(0.12), lineWidth: Cosmic.Border.thin)
            )
            .opacity(isSelected ? 1.0 : 0.78)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("proPlanOption_\(plan.productId)")
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            featureRow("bubble.left.and.bubble.right.fill", "Unlimited Ask (AI chat)")
            featureRow("doc.text.fill", "All journey paths included")
            featureRow("heart.fill", "Love, Career, Money, Health + more")
            featureRow("clock.fill", "Cancel anytime")
        }
        .padding(Cosmic.Spacing.screen)
        .background(Color.cosmicSurface)
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(Color.cosmicGold.opacity(0.2), lineWidth: Cosmic.Border.thin)
        )
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
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

    private var otherOptionsDisclosure: some View {
        DisclosureGroup(isExpanded: $showOtherOptions) {
            VStack(spacing: Cosmic.Spacing.sm) {
                Button { showingReportShop = true } label: {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundStyle(Color.cosmicGold)
                        Text("Open a deeper journey (from $12.99)")
                            .font(.cosmicCallout)
                        Spacer()
                        Image(systemName: "chevron.right").font(.cosmicCaption)
                    }
                    .foregroundStyle(Color.cosmicTextPrimary)
                }
                .buttonStyle(.cosmicSecondary)
                .accessibilityIdentifier(AccessibilityID.buyDetailedReportButton)

                Button { showingChatPackages = true } label: {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .foregroundStyle(Color.cosmicAmethyst)
                        Text("Get chat packages (no subscription)")
                            .font(.cosmicCallout)
                        Spacer()
                        Image(systemName: "chevron.right").font(.cosmicCaption)
                    }
                    .foregroundStyle(Color.cosmicTextPrimary)
                }
                .buttonStyle(.cosmicSecondary)
                .accessibilityIdentifier(AccessibilityID.buyChatPackagesButton)
            }
            .padding(.top, Cosmic.Spacing.sm)
        } label: {
            Text("Other ways to unlock")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
    }

    private var paywallFooter: some View {
        VStack(spacing: Cosmic.Spacing.sm) {
            Button {
                CosmicHaptics.medium()
                Task { await purchasePro() }
            } label: {
                HStack(spacing: Cosmic.Spacing.sm) {
                    if isPurchasing { ProgressView().tint(Color.cosmicVoid) }
                    Text(isPurchasing ? "Starting trial..." : "Start \(selectedPlan.title)")
                        .font(.cosmicBodyEmphasis)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
            }
            .buttonStyle(.cosmicPrimary)
            .accessibilityIdentifier(AccessibilityID.startProButton)

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

            HStack(spacing: Cosmic.Spacing.sm) {
                Link("Terms", destination: termsURL)
                Text("•").foregroundStyle(Color.cosmicTextTertiary)
                Link("Privacy", destination: privacyURL)
                Text("•").foregroundStyle(Color.cosmicTextTertiary)
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

    private func purchasePro() async {
        if await MainActor.run(body: { isPurchasing }) { return }
        await MainActor.run { isPurchasing = true }
        let plan = await MainActor.run { selectedPlan }
        defer { Task { @MainActor in isPurchasing = false } }

        let success = await storeKitManager.purchaseProduct(productId: plan.productId, billingPlan: plan.billingPlan)
        if success {
            Analytics.shared.track(
                .paywallConversion,
                properties: [
                    "product": plan.productId,
                    "context": context.rawValue,
                    "variant": "tiered_v1",
                    "experiment": "astronova_paywall_v1",
                    "source": "paywall"
                ]
            )
            Analytics.shared.track(.purchaseSuccess, properties: ["product": plan.productId])
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
        defer { Task { @MainActor in isRestoring = false } }

        let restored = await storeKitManager.restorePurchases()
        await MainActor.run {
            OracleQuotaManager.shared.checkSubscription()
            purchaseResult = restored ? .restored : .restoredNone
        }
    }
}

#Preview {
    PaywallVariant_TieredV1()
}
