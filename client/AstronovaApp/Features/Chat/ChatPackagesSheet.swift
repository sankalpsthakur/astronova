import SwiftUI

struct ChatPackagesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthState
    @ObservedObject private var storeKitManager = StoreKitManager.shared
    @AppStorage("chat_credits") private var chatCredits: Int = 0
    @State private var isPurchasing: String? = nil
    @State private var showPurchaseSuccess = false
    @State private var showPurchaseError = false
    @State private var purchaseErrorMessage = "This package is unavailable right now. You were not charged."
    @State private var purchasedCredits: Int = 0

    private let packs: [ShopCatalog.ChatPack] = ShopCatalog.chatPacks

    // App Store compliance URLs
    private let termsURL = URL(string: "https://astronova-ghcr.onrender.com/terms")!
    private let privacyURL = URL(string: "https://astronova-ghcr.onrender.com/privacy")!

    private var mockPurchasesEnabled: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "mock_purchases_enabled") ||
        TestEnvironment.shared.hasArgument(.mockPurchases)
        #else
        return false
        #endif
    }

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
                            let unavailable = isPackUnavailable(pack)
                            ChatPackRow(
                                pack: pack,
                                isPurchasing: isPurchasing == pack.productId,
                                isUnavailable: unavailable,
                                onPurchase: { Task { await buy(pack) } }
                            )
                            .disabled(isPurchasing != nil || unavailable)
                        }
                    }

                }
                .padding(.horizontal, Cosmic.Spacing.screen)
                .padding(.bottom, 120)
            }
            .background(Color.cosmicBackground)
            .navigationTitle("Chat Packages")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                chatPackagesFooter
            }
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
        .task {
            await storeKitManager.loadProducts()
        }
        .alert("Purchase Failed", isPresented: $showPurchaseError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseErrorMessage)
        }
    }

    private var chatPackagesFooter: some View {
        VStack(spacing: Cosmic.Spacing.xs) {
            Text("One-time purchase. Credits never expire.")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Cosmic.Spacing.sm) {
                    Link("Terms of Use", destination: termsURL)
                    Text("•")
                        .foregroundStyle(Color.cosmicTextTertiary)
                    Link("Privacy Policy", destination: privacyURL)
                }

                VStack(spacing: Cosmic.Spacing.xxs) {
                    Link("Terms of Use", destination: termsURL)
                    Link("Privacy Policy", destination: privacyURL)
                }
            }
            .font(.cosmicCaption)
            .foregroundStyle(Color.cosmicGold)
        }
        .padding(.horizontal, Cosmic.Spacing.screen)
        .padding(.top, Cosmic.Spacing.sm)
        .padding(.bottom, Cosmic.Spacing.xs)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.chatPackagesFooter)
    }

    private func buy(_ pack: ShopCatalog.ChatPack) async {
        guard isPurchasing == nil else { return }
        guard mockPurchasesEnabled || auth.isAuthenticated else {
            await MainActor.run {
                purchaseErrorMessage = "Sign in with Apple before buying chat credits so purchases can be restored to your account."
                showPurchaseError = true
            }
            return
        }
        CosmicHaptics.medium()
        isPurchasing = pack.productId
        defer { isPurchasing = nil }

        #if DEBUG
        // UI tests only: use mock store
        if mockPurchasesEnabled {
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
        guard storeKitManager.isProductAvailableForPurchase(pack.productId) else {
            await MainActor.run {
                purchaseErrorMessage = "This package is unavailable right now. You were not charged."
                showPurchaseError = true
            }
            return
        }

        let ok = await storeKitManager.purchaseProduct(productId: pack.productId)
        if ok {
            // Credits are updated by StoreKitManager.handleSuccessfulPurchase via AppStorage.
            handlePurchaseSuccess(credits: pack.credits)
        } else {
            await MainActor.run {
                purchaseErrorMessage = "Purchase could not be completed. You were not charged."
                showPurchaseError = true
            }
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

    private func isPackUnavailable(_ pack: ShopCatalog.ChatPack) -> Bool {
        if mockPurchasesEnabled { return false }
        return storeKitManager.productLoadCompleted &&
        !storeKitManager.isProductAvailableForPurchase(pack.productId)
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
    let isUnavailable: Bool
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
                    Text(isPurchasing ? "..." : (isUnavailable ? "Unavailable" : ShopCatalog.price(for: pack.productId)))
                        .font(.cosmicCalloutEmphasis)
                }
                .padding(.horizontal, Cosmic.Spacing.md)
                .padding(.vertical, Cosmic.Spacing.sm)
                .background(
                    isUnavailable ? LinearGradient(colors: [Color.gray.opacity(0.45), Color.gray.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient.cosmicAntiqueGold
                )
                .foregroundStyle(Color.cosmicVoid)
                .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous))
            }
            .accessibilityIdentifier(AccessibilityID.chatPackBuyButton(pack.productId))
            .accessibilityHint(isUnavailable ? "This package is unavailable right now. You will not be charged." : "")
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
