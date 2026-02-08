import SwiftUI

struct ChatPackagesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storeKitManager = StoreKitManager.shared
    @AppStorage("chat_credits") private var chatCredits: Int = 0
    @State private var isPurchasing: String? = nil
    @State private var showPurchaseSuccess = false
    @State private var showPurchaseError = false
    @State private var purchasedCredits: Int = 0

    private let packs: [ShopCatalog.ChatPack] = ShopCatalog.chatPacks

    // App Store compliance URLs
    private let termsURL = URL(string: "https://astronova.onrender.com/terms")!
    private let privacyURL = URL(string: "https://astronova.onrender.com/privacy")!

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

                    // App Store compliance: Terms and Privacy links
                    VStack(spacing: Cosmic.Spacing.xs) {
                        Text("One-time purchase. Credits never expire.")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextTertiary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: Cosmic.Spacing.md) {
                            Link("Terms of Use", destination: termsURL)
                            Text("•")
                                .foregroundStyle(Color.cosmicTextTertiary)
                            Link("Privacy Policy", destination: privacyURL)
                        }
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicGold)
                    }
                    .padding(.top, Cosmic.Spacing.md)
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
        .alert("Purchase Failed", isPresented: $showPurchaseError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The purchase could not be completed. You were not charged.")
        }
    }

    private func buy(_ pack: ShopCatalog.ChatPack) async {
        guard isPurchasing == nil else { return }
        CosmicHaptics.medium()
        isPurchasing = pack.productId
        defer { isPurchasing = nil }

        #if DEBUG
        // UI tests only: use mock store
        if UserDefaults.standard.bool(forKey: "mock_purchases_enabled") {
            let ok = await BasicStoreManager.shared.purchaseProduct(productId: pack.productId)
            if ok {
                handlePurchaseSuccess(credits: pack.credits)
            } else {
                await MainActor.run { showPurchaseError = true }
            }
            return
        }
        #endif

        // Production: Use StoreKit
        let ok = await storeKitManager.purchaseProduct(productId: pack.productId)
        if ok {
            // Credits are updated by StoreKitManager.handleSuccessfulPurchase via AppStorage.
            handlePurchaseSuccess(credits: pack.credits)
        } else {
            await MainActor.run { showPurchaseError = true }
        }
    }

    private func handlePurchaseSuccess(credits: Int) {
        CosmicHaptics.success()
        purchasedCredits = credits
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

// MARK: - Purchase Success Overlay

private struct PurchaseSuccessOverlay: View {
    let credits: Int

    var body: some View {
        VStack(spacing: Cosmic.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.cosmicSuccess)
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
