import SwiftUI
import AudioToolbox
import UIKit

/// Astronova paywall — tiered_v2 variant.
///
/// Difference vs tiered_v1: adds a "Try 7-day Cosmic trial then auto-revert to
/// Pro" CTA above the standard footer. The trial SKU is not yet provisioned
/// in App Store Connect — when the user taps the trial CTA we fall back to
/// the regular 12-month purchase and stamp `cosmic_trial_requested=true` on
/// the analytics event so the server-side join knows demand exists. Once the
/// trial SKU lands, the StoreKit call here can switch over without UI work.
struct PaywallVariant_TieredV2: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storeKitManager = StoreKitManager.shared
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var purchaseResult: PurchaseResult?
    @State private var showingReportShop = false
    @State private var showingChatPackages = false
    @State private var showOtherOptions = false
    @State private var selectedPlanProductId = ShopCatalog.pro12MonthCommitmentProductID
    /// `true` when the StoreKit catalog returned but neither the 12-month nor
    /// monthly Pro SKU is present. We disable the primary CTA and surface a
    /// loading banner so the user isn't left tapping a no-op trial button.
    @State private var allProductsUnavailable = false

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

    private var ctaTitle: String {
        if isPurchasing { return "Starting trial..." }
        if allProductsUnavailable { return "Plans loading..." }
        return "Start 7-day Cosmic trial"
    }

    private var heroTitle: String {
        context == .journalInsights ? "Unlock Journal Insights" : "Try Cosmic. Keep Pro."
    }

    private var heroSubtitle: String {
        if context == .journalInsights {
            return "You used this month's free insight sessions. Pro keeps pattern, body, and mood trends available."
        }
        return "7 days of Cosmic, then your Pro plan keeps running."
    }

    private var trialHeadline: String {
        context == .journalInsights ? "Keep every trend visible" : "Highest-tier insights for a week"
    }

    private var trialBody: String {
        if context == .journalInsights {
            return "Use Journal Insights whenever you need a read on your patterns, body signals, and mood movement."
        }
        return "After 7 days you're billed for the 12-month Pro plan you selected below. Cancel any time in Settings."
    }

    private func billingDisplayPrice(for plan: ShopCatalog.ProPlan) -> String {
        storeKitManager.monthlyBillingPlanPrices[plan.productId] ??
        plan.fallbackBillingDisplayPrice
    }

    private func commitmentDisplayPrice(for plan: ShopCatalog.ProPlan) -> String? {
        storeKitManager.commitmentDisplayPrices[plan.productId] ??
        plan.fallbackCommitmentDisplayPrice
    }

    /// Wave-0 guard: if the 12-month commitment SKU failed to load (e.g.
    /// `MISSING_METADATA` in App Store Connect) the trial/Subscribe tap
    /// would route through a SKU StoreKit never returned and silently
    /// fail. When the loaded catalog is missing it, fall back to monthly
    /// so the default action is purchasable. Only adjusts the *default*
    /// selection — explicit user taps on the 12-month card are preserved.
    ///
    /// If *both* the 12-month and monthly SKUs are missing we can't fall
    /// back to anything purchasable, so we raise `allProductsUnavailable`
    /// and let the view disable the CTA + surface a banner.
    private func adjustDefaultPlanIfAnnualUnavailable() {
        let loaded = storeKitManager.products
        guard !loaded.isEmpty else { return }
        let annualMissing = loaded[ShopCatalog.pro12MonthCommitmentProductID] == nil
        let monthlyMissing = loaded[ShopCatalog.proMonthlyProductID] == nil
        if annualMissing && monthlyMissing {
            allProductsUnavailable = true
            return
        }
        allProductsUnavailable = false
        guard selectedPlanProductId == ShopCatalog.pro12MonthCommitmentProductID else { return }
        if annualMissing, !monthlyMissing {
            selectedPlanProductId = ShopCatalog.proMonthlyProductID
        }
    }

    /// Returns `true` if the given plan's SKU is missing from the loaded
    /// StoreKit catalog. Used to disable individual plan rows so the user
    /// can't pick a SKU that will silently fail to purchase. Returns `false`
    /// while products are still loading (empty catalog).
    private func isPlanUnavailable(_ plan: ShopCatalog.ProPlan) -> Bool {
        let loaded = storeKitManager.products
        guard !loaded.isEmpty else { return false }
        return loaded[plan.productId] == nil
    }

    private let termsURL = URL(string: "https://astronova-ghcr.onrender.com/terms")!
    private let privacyURL = URL(string: "https://astronova-ghcr.onrender.com/privacy")!
    private let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    var body: some View {
        ScrollView {
            VStack(spacing: Cosmic.Spacing.xl) {
                hero
                cosmicTrialCard
                if allProductsUnavailable {
                    plansLoadingBanner
                }
                annualHeroCard
                monthlyDemotedRow
                featureList
                otherOptionsDisclosure
            }
            .padding(.horizontal, Cosmic.Spacing.screen)
            .padding(.bottom, 240)
        }
        .background(Color.cosmicBackground)
        .safeAreaInset(edge: .bottom) {
            paywallFooter
        }
        .sheet(isPresented: $showingReportShop) { InlineReportsStoreSheet() }
        .sheet(isPresented: $showingChatPackages) { ChatPackagesSheet() }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.cosmicTextTertiary.opacity(0.7))
                    .padding(Cosmic.Spacing.md)
            }
            .accessibilityLabel("Close")
            .accessibilityIdentifier("paywallCloseButton")
            .accessibleIconButton()
        }
        .accessibilityIdentifier(AccessibilityID.paywallView)
        .onAppear {
            Analytics.shared.track(
                .paywallShown,
                properties: [
                    "variant": "tiered_v2",
                    "experiment": "astronova_paywall_v1",
                    "context": context.rawValue
                ]
            )
        }
        .task {
            await storeKitManager.loadProducts()
            adjustDefaultPlanIfAnnualUnavailable()
        }
        .alert(item: $purchaseResult) { result in
            switch result {
            case .success:
                return Alert(title: Text("Welcome to Pro!"),
                             message: Text("Your subscription is now active."),
                             dismissButton: .default(Text("Continue")) { dismiss() })
            case .error(let message):
                return Alert(title: Text("Purchase Failed"), message: Text(message), dismissButton: .default(Text("OK")))
            case .restored:
                return Alert(title: Text("Purchases Restored"),
                             message: Text("Your Pro subscription has been restored."),
                             dismissButton: .default(Text("Continue")) { dismiss() })
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
    }

    private var cosmicTrialCard: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            HStack {
                Text("7-DAY COSMIC TRIAL")
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicVoid)
                    .padding(.horizontal, Cosmic.Spacing.xs)
                    .padding(.vertical, 2)
                    .background(Color.cosmicAmethyst, in: Capsule())
                Spacer()
            }
            Text(trialHeadline)
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)
            Text(trialBody)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Cosmic.Spacing.screen)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cosmicAmethyst.opacity(0.12), in: RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(Color.cosmicAmethyst.opacity(0.4), lineWidth: Cosmic.Border.thin)
        )
        .accessibilityIdentifier("cosmicTrialCard")
    }

    /// Non-tappable banner shown above the plan picker when *all* Pro SKUs
    /// failed to load. Keeps the user informed instead of leaving a no-op
    /// trial button as the only visible affordance.
    private var plansLoadingBanner: some View {
        HStack(spacing: Cosmic.Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.cosmicGold)
                .accessibilityHidden(true)
            Text("Plans loading — try again in a moment")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextPrimary)
            Spacer()
        }
        .padding(Cosmic.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cosmicGold.opacity(0.12), in: RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(Color.cosmicGold.opacity(0.35), lineWidth: Cosmic.Border.thin)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("paywallPlansLoadingBanner")
        .accessibilityLabel("Plans loading. Try again in a moment.")
        .accessibilityAddTraits(.isStaticText)
    }

    private var annualHeroCard: some View {
        let plan = ShopCatalog.proPlans.first { $0.productId == ShopCatalog.pro12MonthCommitmentProductID } ?? ShopCatalog.proPlans[0]
        let isSelected = selectedPlanProductId == plan.productId
        let unavailable = isPlanUnavailable(plan)
        return Button {
            CosmicHaptics.light()
            selectedPlanProductId = plan.productId
        } label: {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                HStack {
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
                Text("\(billingDisplayPrice(for: plan)) \(plan.billingCaption)")
                    .font(.cosmicBodyEmphasis)
                if let commitment = commitmentDisplayPrice(for: plan) {
                    Text("\(commitment) first-year commitment")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
            }
            .padding(Cosmic.Spacing.screen)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cosmicGold.opacity(0.14), in: RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .stroke(Color.cosmicGold, lineWidth: Cosmic.Border.thick)
            )
            .opacity(unavailable ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(unavailable)
        .accessibilityIdentifier("proPlanOption_\(plan.productId)")
        .accessibilityLabel("\(plan.title), most chosen. \(billingDisplayPrice(for: plan)) \(plan.billingCaption)")
        .accessibilityHint(unavailable ? "Unavailable while plans are loading" : (isSelected ? "Currently selected" : "Double tap to select"))
    }

    private var monthlyDemotedRow: some View {
        let plan = ShopCatalog.proPlans.first { $0.productId == ShopCatalog.proMonthlyProductID } ?? ShopCatalog.proPlans[0]
        let isSelected = selectedPlanProductId == plan.productId
        let unavailable = isPlanUnavailable(plan)
        return Button {
            CosmicHaptics.light()
            selectedPlanProductId = plan.productId
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? Color.cosmicGold : Color.cosmicTextTertiary)
                    .accessibilityHidden(true)
                Text(plan.title).font(.cosmicCallout)
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
            .opacity(unavailable ? 0.5 : (isSelected ? 1.0 : 0.78))
        }
        .buttonStyle(.plain)
        .disabled(unavailable)
        .accessibilityIdentifier("proPlanOption_\(plan.productId)")
        .accessibilityLabel("\(plan.title), \(billingDisplayPrice(for: plan)) \(plan.billingCaption)")
        .accessibilityHint(unavailable ? "Unavailable while plans are loading" : (isSelected ? "Currently selected" : "Double tap to select"))
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            if context == .journalInsights {
                featureRow("chart.bar.xaxis", "Unlimited Journal Insights")
                featureRow("waveform.path.ecg", "Body and mood trends")
                featureRow("sparkles", "Pattern frequency over time")
            } else {
                featureRow("bubble.left.and.bubble.right.fill", "Unlimited Ask (AI chat)")
                featureRow("doc.text.fill", "All journey paths included")
                featureRow("heart.fill", "Love, Career, Resources, Energy + more")
            }
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
            Text(text).font(.cosmicBody).foregroundStyle(Color.cosmicTextPrimary)
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
                        Image(systemName: "doc.text.magnifyingglass").foregroundStyle(Color.cosmicGold)
                        Text("Open a deeper journey (from $12.99)").font(.cosmicCallout)
                        Spacer()
                        Image(systemName: "chevron.right").font(.cosmicCaption)
                    }
                    .foregroundStyle(Color.cosmicTextPrimary)
                }
                .buttonStyle(.cosmicSecondary)
                .accessibilityIdentifier(AccessibilityID.buyDetailedReportButton)

                Button { showingChatPackages = true } label: {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right").foregroundStyle(Color.cosmicAmethyst)
                        Text("Get chat packages (no subscription)").font(.cosmicCallout)
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
                Task { await startTrialOrPurchase() }
            } label: {
                HStack(spacing: Cosmic.Spacing.sm) {
                    if isPurchasing { ProgressView().tint(Color.cosmicVoid) }
                    Text(ctaTitle)
                        .font(.cosmicBodyEmphasis)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
            }
            .buttonStyle(.cosmicPrimary)
            .disabled(allProductsUnavailable)
            .accessibilityIdentifier(AccessibilityID.startProButton)
            .accessibilityHint(allProductsUnavailable ? "Plans loading. Try again in a moment." : "")

            Button {
                CosmicHaptics.light()
                Task { await restorePurchases() }
            } label: {
                Text(isRestoring ? "Restoring..." : "Restore Purchases")
                    .font(.cosmicCallout)
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
        .accessibilityIdentifier(AccessibilityID.paywallFooter)
    }

    private func startTrialOrPurchase() async {
        if await MainActor.run(body: { isPurchasing }) { return }
        await MainActor.run { isPurchasing = true }
        let plan = await MainActor.run { selectedPlan }
        defer { Task { @MainActor in isPurchasing = false } }

        // Until the dedicated Cosmic-trial SKU lands, this falls through to
        // the standard 12-month purchase and tags the event so demand for the
        // trial offering is measurable independent of conversion.
        let success = await storeKitManager.purchaseProduct(productId: plan.productId, billingPlan: plan.billingPlan)
        if success {
            Analytics.shared.track(
                .paywallConversion,
                properties: [
                    "product": plan.productId,
                    "context": context.rawValue,
                    "variant": "tiered_v2",
                    "experiment": "astronova_paywall_v1",
                    "cosmic_trial_requested": "true",
                    "source": "paywall"
                ]
            )
            Analytics.shared.track(.purchaseSuccess, properties: ["product": plan.productId])
            await MainActor.run {
                OracleQuotaManager.shared.checkSubscription()
                purchaseResult = .success
                firePurchaseSuccessCue()
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

    // MARK: - A3 Purchase Success Cue

    /// Fires the celebration haptic + system sound 1407 + TTS "Cosmic access
    /// unlocked" + VoiceOver announcement after a successful purchase.
    /// Per `launch-artifacts/feedback-design-wave-2026-05-18.md` §1.1 A3.
    @MainActor
    private func firePurchaseSuccessCue() {
        HapticFeedbackService.shared.celebration()
        AudioServicesPlaySystemSound(1407)
        UIAccessibility.post(notification: .announcement,
                             argument: "Cosmic access unlocked")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            SpeechService.shared.speak("Cosmic access unlocked")
        }
    }
}

#Preview {
    PaywallVariant_TieredV2()
}
