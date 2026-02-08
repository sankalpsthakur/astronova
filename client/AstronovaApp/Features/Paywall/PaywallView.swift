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
    @AppStorage("trigger_show_report_shop") private var triggerShowReportShop: Bool = false
    @AppStorage("trigger_show_chat_packages") private var triggerShowChatPackages: Bool = false

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
    
    private let subscriptionProductId = "astronova_pro_monthly"

    init(context: PaywallContext = .general) {
        self.context = context
    }

    private var paywallVariant: String {
        RemoteConfigService.shared.string(forKey: "paywall_variant", default: "A")
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
            return "Unlock deeper journeys: full reports, saved chapters, and unlimited guidance."
        case (.home, "B"):
            return "Your next chapter: premium guidance and unlimited chat."
        default:
            return "Unlimited chat, full reports, and deeper journeys."
        }
    }

    private var featureRows: [(icon: String, text: String)] {
        switch (context, paywallVariant) {
        case (.chatLimit, "C"):
            return [
                ("bubble.left.and.bubble.right.fill", "Unlimited Ask (AI chat)"),
                ("sparkles", "Priority cosmic insights"),
                ("doc.text.fill", "All detailed reports included"),
                ("clock.fill", "Cancel anytime"),
            ]
        case (.chatLimit, _):
            return [
                ("bubble.left.and.bubble.right.fill", "Unlimited Ask (AI chat)"),
                ("bolt.fill", "Continue instantly — no waiting"),
                ("doc.text.fill", "All detailed reports included"),
                ("clock.fill", "Cancel anytime"),
            ]
        case (.report, _):
            return [
                ("doc.text.fill", "All detailed reports included"),
                ("tray.full.fill", "Saved to your library"),
                ("bubble.left.and.bubble.right.fill", "Unlimited Ask (AI chat)"),
                ("clock.fill", "Cancel anytime"),
            ]
        default:
            return [
                ("bubble.left.and.bubble.right.fill", "Unlimited Ask (AI chat)"),
                ("doc.text.fill", "All detailed reports included"),
                ("heart.fill", "Love, Career, Money, Health + more"),
                ("clock.fill", "Cancel anytime"),
            ]
        }
    }
    
    private var subscriptionPrice: String {
        storeKitManager.products[subscriptionProductId] ??
        BasicStoreManager.shared.products[subscriptionProductId] ??
        "$9.99"
    }
    
    private var purchaseButtonTitle: String {
        isPurchasing ? "Purchasing..." : "Begin deeper journeys for \(subscriptionPrice)/month"
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

                // Features list
                VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
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

                // Primary CTA
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
                    }
                }
                .buttonStyle(.cosmicPrimary)
                .accessibilityIdentifier(AccessibilityID.startProButton)
                .accessibilityHint("Starts your Pro subscription")

                // Restore purchases
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

                // MARK: - Subscription Disclosure (App Store Guideline 3.1.2)
                VStack(spacing: Cosmic.Spacing.xs) {
                    Text("Subscription auto-renews monthly at \(subscriptionPrice)/month until canceled. Cancel anytime in Settings → Apple ID → Subscriptions.")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: Cosmic.Spacing.md) {
                        Link("Terms of Use", destination: termsURL)
                        Text("•")
                            .foregroundStyle(Color.cosmicTextTertiary)
                        Link("Privacy Policy", destination: privacyURL)
                        Text("•")
                            .foregroundStyle(Color.cosmicTextTertiary)
                        Link("Manage", destination: manageSubscriptionsURL)
                    }
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicGold)
                }
                .padding(.top, Cosmic.Spacing.sm)

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
                        triggerShowReportShop = true
                        NotificationCenter.default.post(name: .switchToTab, object: 0)
                        dismiss()
                    } label: {
                        HStack(spacing: Cosmic.Spacing.sm) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundStyle(Color.cosmicGold)
                            Text("Buy a detailed report (from $12.99)")
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
                        triggerShowChatPackages = true
                        NotificationCenter.default.post(name: .switchToTab, object: 2)
                        dismiss()
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
            .padding(.bottom, Cosmic.Spacing.xl)
        }
        .background(Color.cosmicBackground)
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
                properties: ["variant": paywallVariant, "context": context.rawValue]
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
    
    private func purchasePro() async {
        if await MainActor.run(body: { isPurchasing }) { return }
        await MainActor.run { isPurchasing = true }

        defer {
            Task { @MainActor in isPurchasing = false }
        }

        #if DEBUG
        // UI tests only: bypass StoreKit dialogs using mock store
        if UserDefaults.standard.bool(forKey: "mock_purchases_enabled") {
            let success = await BasicStoreManager.shared.purchaseProduct(productId: subscriptionProductId)
            if success {
                Analytics.shared.track(.purchaseSuccess, properties: ["product": subscriptionProductId])
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
        let success = await storeKitManager.purchaseProduct(productId: subscriptionProductId)
        if success {
            Analytics.shared.track(.purchaseSuccess, properties: ["product": subscriptionProductId])
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
