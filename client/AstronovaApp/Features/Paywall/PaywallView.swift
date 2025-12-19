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
    @AppStorage("trigger_show_report_shop") private var triggerShowReportShop: Bool = false
    @AppStorage("trigger_show_chat_packages") private var triggerShowChatPackages: Bool = false

    private let context: PaywallContext
    
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
            return "Keep Chatting"
        case .report:
            return "Unlock Your Report"
        case .home:
            return "Unlock Everything"
        case .general:
            return "Unlock Everything"
        }
    }

    private var heroSubtitle: String {
        switch (context, paywallVariant) {
        case (.chatLimit, _):
            return "You’ve hit today’s free limit. Go Pro for unlimited Ask."
        case (.report, _):
            return "Go Pro to access all detailed reports — saved to your library."
        case (.home, "B"):
            return "Premium guidance + unlimited chat, every day."
        default:
            return "Unlimited chat + all detailed reports"
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
        isPurchasing ? "Purchasing..." : "Start Pro for \(subscriptionPrice) per month"
    }
    
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
                        NotificationCenter.default.post(name: .switchToTab, object: 3)
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
    }
    
    private func purchasePro() async {
        if await MainActor.run(body: { isPurchasing }) { return }
        await MainActor.run { isPurchasing = true }
        
        defer {
            Task { @MainActor in isPurchasing = false }
        }

        // UI tests / local debug: bypass StoreKit dialogs and use the in-app mock store.
        if UserDefaults.standard.bool(forKey: "mock_purchases_enabled") {
            let success = await BasicStoreManager.shared.purchaseProduct(productId: subscriptionProductId)
            if success {
                Analytics.shared.track(.purchaseSuccess, properties: ["product": subscriptionProductId])
                await MainActor.run { dismiss() }
            }
            return
        }
        
        if await storeKitManager.purchaseProduct(productId: subscriptionProductId) {
            Analytics.shared.track(.purchaseSuccess, properties: ["product": subscriptionProductId])
            await MainActor.run { dismiss() }
            return
        }
        
        let success = await BasicStoreManager.shared.purchaseProduct(productId: subscriptionProductId)
        if success {
            Analytics.shared.track(.purchaseSuccess, properties: ["product": subscriptionProductId])
            await MainActor.run { dismiss() }
        }
    }
    
    private func restorePurchases() async {
        if await MainActor.run(body: { isRestoring }) { return }
        await MainActor.run { isRestoring = true }
        
        defer {
            Task { @MainActor in isRestoring = false }
        }

        if UserDefaults.standard.bool(forKey: "mock_purchases_enabled") {
            await BasicStoreManager.shared.restorePurchases()
            return
        }

        await storeKitManager.restorePurchases()
        await BasicStoreManager.shared.restorePurchases()
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

            Text(text)
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextPrimary)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.cosmicSuccess)
        }
    }
}

#Preview {
    PaywallView()
}
