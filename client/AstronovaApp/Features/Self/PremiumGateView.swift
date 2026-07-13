import SwiftUI

// MARK: - Premium Gate Context

/// Identifies which feature is being gated, for analytics and paywall context.
enum PremiumFeatureContext: String {
    case synthesisNarrative = "synthesis_narrative"
    case fullTimeline = "full_timeline"
    case peakWindows = "peak_windows"
    case pdfExport = "pdf_export"

    var paywallContext: PaywallContext {
        switch self {
        case .peakWindows, .fullTimeline:
            return .home
        case .synthesisNarrative:
            return .home
        case .pdfExport:
            return .report
        }
    }

    var analyticsFeatureName: String {
        switch self {
        case .synthesisNarrative: return "Cosmic Synthesis"
        case .fullTimeline: return "Full Timeline"
        case .peakWindows: return "Peak Windows"
        case .pdfExport: return "PDF Export"
        }
    }
}

// MARK: - Premium Gate Modifier

/// A reusable ViewModifier that gates content behind a premium subscription.
///
/// Free users see the content blurred with a peek-through overlay and an
/// unlock CTA that opens the paywall. Premium users see content normally.
struct PremiumGateModifier: ViewModifier {
    let isPremium: Bool
    let featureName: String
    let context: PremiumFeatureContext

    @State private var showPaywall = false

    func body(content: Content) -> some View {
        if isPremium {
            content
        } else {
            ZStack {
                // Blurred content as peek-through preview
                content
                    .blur(radius: Cosmic.Blur.subtle)
                    .overlay(
                        Color.cosmicVoid.opacity(Cosmic.Opacity.light)
                    )
                    .allowsHitTesting(false)

                // Unlock overlay centered on the card
                premiumOverlay
            }
            .onAppear {
                Analytics.shared.track(
                    .paywallShown,
                    properties: [
                        "variant": "premium_gate",
                        "context": context.rawValue,
                        "trigger": "premium_gate_\(context.rawValue)",
                        "paywall_id": "astronova_pro_premium_gate",
                        "screen": "cosmic_mirror"
                    ]
                )
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(context: context.paywallContext)
            }
        }
    }

    // MARK: - Overlay

    private var premiumOverlay: some View {
        VStack(spacing: Cosmic.Spacing.md) {
            // Crown icon with gradient
            Image(systemName: "crown.fill")
                .font(.system(size: 28))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.cosmicBrass, Color.cosmicGold],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cosmicFloat(amount: 4)

            VStack(spacing: Cosmic.Spacing.xxs) {
                Text("Unlock \(featureName)")
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Start your 14-day free trial for unlimited access")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                CosmicHaptics.medium()
                showPaywall = true
            } label: {
                HStack(spacing: Cosmic.Spacing.xs) {
                    Image(systemName: "sparkles")
                        .font(.cosmicCaption)
                    Text("Start Free Trial")
                        .font(.cosmicBodyEmphasis)
                }
                .foregroundStyle(Color.cosmicVoid)
                .frame(height: Cosmic.ButtonHeight.medium)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.cosmicBrass, Color.cosmicGold, Color.cosmicCopper],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous))
            }
            .accessibilityLabel("Start free trial to unlock \(featureName)")
            .accessibilityHint("Opens the Astronova Pro subscription screen")

            // Subtle "no commitment" reassurance
            Text("Cancel anytime during trial")
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextTertiary)
        }
        .padding(Cosmic.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(Color.cosmicGold.opacity(0.2), lineWidth: Cosmic.Border.thin)
        )
        .padding(Cosmic.Spacing.screen)
    }
}

// MARK: - View Extension

extension View {
    /// Gates this view behind a premium subscription. Free users see a
    /// blurred preview with an unlock CTA; premium users see the content.
    func premiumGate(
        isPremium: Bool,
        featureName: String,
        context: PremiumFeatureContext
    ) -> some View {
        self.modifier(PremiumGateModifier(
            isPremium: isPremium,
            featureName: featureName,
            context: context
        ))
    }
}

// MARK: - Premium Lock Card (for inline CTAs in horizontal strips)

/// A compact CTA card shown inline within horizontal scroll strips
/// (e.g., after the free peak windows). Taps open the paywall.
struct PremiumLockCard: View {
    let featureName: String
    let context: PremiumFeatureContext

    @State private var showPaywall = false

    var body: some View {
        Button {
            CosmicHaptics.medium()
            showPaywall = true
        } label: {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.cosmicGold)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock \(featureName)")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                        .lineLimit(2)
                    Text("14-day free trial")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicGold)
                }
            }
            .padding(Cosmic.Spacing.md)
            .frame(width: 180)
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .fill(Color.cosmicSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .stroke(Color.cosmicGold.opacity(0.2), lineWidth: Cosmic.Border.thin)
            )
            .cosmicElevation(.subtle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Unlock \(featureName). Start 14-day free trial.")
        .sheet(isPresented: $showPaywall) {
            PaywallView(context: context.paywallContext)
        }
    }
}

// MARK: - Timeline Lock Banner

/// A full-width banner shown at the end of the free months in
/// PredictionTimelineView. Contains a strong CTA to unlock the full forecast.
struct TimelineLockBanner: View {
    @State private var showPaywall = false

    var body: some View {
        Button {
            CosmicHaptics.medium()
            showPaywall = true
        } label: {
            VStack(spacing: Cosmic.Spacing.sm) {
                HStack(spacing: Cosmic.Spacing.xs) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.cosmicGold)
                    Text("Unlock 5-Year Forecast")
                        .font(.cosmicBodyEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }

                HStack(spacing: Cosmic.Spacing.xxs) {
                    Image(systemName: "sparkles")
                        .font(.cosmicMicro)
                        .foregroundStyle(Color.cosmicGold)
                    Text("12-month action forecast, peak windows, and transit triggers")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
            }
            .padding(Cosmic.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .fill(Color.cosmicSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.cosmicGold.opacity(0.3), Color.cosmicGold.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: Cosmic.Border.thin
                    )
            )
            .cosmicElevation(.low)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Unlock 5-Year Forecast with 14-day free trial")
        .sheet(isPresented: $showPaywall) {
            PaywallView(context: .home)
        }
    }
}

// MARK: - Previews

#Preview("Premium Gate — Gated") {
    ZStack {
        Color.cosmicBackground.ignoresSafeArea()

        VStack(spacing: Cosmic.Spacing.lg) {
            Text("Peekaboo — you can kinda see me")
                .font(.cosmicTitle2)
                .foregroundStyle(Color.cosmicTextPrimary)
                .padding()
                .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
        }
        .premiumGate(
            isPremium: false,
            featureName: "Cosmic Synthesis",
            context: .synthesisNarrative
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Premium Gate — Unlocked") {
    ZStack {
        Color.cosmicBackground.ignoresSafeArea()

        VStack(spacing: Cosmic.Spacing.lg) {
            Text("Full access — you are Pro")
                .font(.cosmicTitle2)
                .foregroundStyle(Color.cosmicTextPrimary)
                .padding()
                .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
        }
        .premiumGate(
            isPremium: true,
            featureName: "Cosmic Synthesis",
            context: .synthesisNarrative
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Premium Lock Card") {
    ZStack {
        Color.cosmicBackground.ignoresSafeArea()
        HStack {
            PremiumLockCard(
                featureName: "Peak Windows",
                context: .peakWindows
            )
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Timeline Lock Banner") {
    ZStack {
        Color.cosmicBackground.ignoresSafeArea()
        TimelineLockBanner()
            .padding()
    }
    .preferredColorScheme(.dark)
}
