import SwiftUI

struct ChatPackagesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("chat_credits") private var chatCredits: Int = 0
    @State private var isPurchasing: String? = nil
    @State private var showPurchaseSuccess = false
    @State private var purchasedCredits: Int = 0

    private let packs: [ShopCatalog.ChatPack] = ShopCatalog.chatPacks

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Cosmic.Spacing.lg) {
                    // Header
                    VStack(spacing: Cosmic.Spacing.sm) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient.cosmicAntiqueGold
                            )

                        Text("Ask Packages")
                            .font(.cosmicTitle1)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        Text("Buy reply credits to use anytime. No subscription.")
                            .font(.cosmicBody)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                    .padding(.top, Cosmic.Spacing.xl)

                    // Credits display
                    HStack(spacing: Cosmic.Spacing.sm) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.cosmicGold)
                        Text("Available credits: \(chatCredits)")
                            .font(.cosmicBodyEmphasis)
                            .foregroundStyle(Color.cosmicTextPrimary)
                            .accessibilityIdentifier(AccessibilityID.chatCreditsLabel)
                    }
                    .padding(Cosmic.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Color.cosmicSurface)
                    .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                            .stroke(Color.cosmicGold.opacity(0.3), lineWidth: Cosmic.Border.thin)
                    )

                    // Package list
                    VStack(spacing: Cosmic.Spacing.sm) {
                        ForEach(packs) { pack in
                            ChatPackRow(
                                pack: pack,
                                isPurchasing: isPurchasing == pack.productId,
                                onPurchase: { Task { await buy(pack) } }
                            )
                            .disabled(isPurchasing != nil)
                        }
                    }
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
                .padding(.bottom, Cosmic.Spacing.xl)
            }
            .background(Color.cosmicBackground)
            .navigationTitle("Chat Packages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        CosmicHaptics.light()
                        dismiss()
                    }
                    .font(.cosmicBodyEmphasis)
                    .foregroundStyle(Color.cosmicGold)
                    .accessibilityIdentifier(AccessibilityID.doneButton)
                }
            }
            .overlay {
                if showPurchaseSuccess {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        PurchaseSuccessOverlay(credits: purchasedCredits)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .accessibilityIdentifier(AccessibilityID.chatPackagesSheet)
    }

    private func buy(_ pack: ShopCatalog.ChatPack) async {
        guard isPurchasing == nil else { return }
        CosmicHaptics.medium()
        isPurchasing = pack.productId
        defer { isPurchasing = nil }
        let ok = await BasicStoreManager.shared.purchaseProduct(productId: pack.productId)
        if ok {
            CosmicHaptics.success()
            purchasedCredits = pack.credits
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showPurchaseSuccess = true
            }
            // Auto-dismiss after showing success
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showPurchaseSuccess = false
                }
            }
        }
    }
}

// MARK: - Purchase Success Overlay

private struct PurchaseSuccessOverlay: View {
    let credits: Int

    var body: some View {
        VStack(spacing: Cosmic.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.green)
                .symbolEffect(.bounce, value: true)

            Text("Purchase Complete!")
                .font(.cosmicTitle2)
                .foregroundStyle(Color.cosmicTextPrimary)

            Text("+\(credits) credits added")
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
        .padding(Cosmic.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.modal, style: .continuous)
                .fill(Color.cosmicSurface)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .accessibilityIdentifier("purchaseSuccessOverlay")
    }
}

// MARK: - Chat Pack Row

private struct ChatPackRow: View {
    let pack: ShopCatalog.ChatPack
    let isPurchasing: Bool
    let onPurchase: () -> Void

    var body: some View {
        HStack(spacing: Cosmic.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.cosmicAmethyst.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.cosmicAmethyst)
            }

            // Details
            VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                Text(pack.title)
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Text(pack.subtitle)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }

            Spacer()

            // Buy button
            Button(action: onPurchase) {
                HStack(spacing: Cosmic.Spacing.xxs) {
                    if isPurchasing {
                        ProgressView()
                            .tint(Color.cosmicVoid)
                            .scaleEffect(0.8)
                    }
                    Text(isPurchasing ? "..." : ShopCatalog.price(for: pack.productId))
                        .font(.cosmicCalloutEmphasis)
                }
                .padding(.horizontal, Cosmic.Spacing.md)
                .padding(.vertical, Cosmic.Spacing.sm)
                .background(
                    LinearGradient.cosmicAntiqueGold
                )
                .foregroundStyle(Color.cosmicVoid)
                .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous))
            }
            .accessibilityIdentifier(AccessibilityID.chatPackBuyButton(pack.productId))
        }
        .padding(Cosmic.Spacing.md)
        .background(Color.cosmicSurface)
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(Color.white.opacity(Cosmic.Opacity.subtle), lineWidth: Cosmic.Border.hairline)
        )
        .cosmicElevation(.low)
    }
}
