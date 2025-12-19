import SwiftUI

/// Grid of life domain cards with cosmic weather header
struct DomainGridView: View {
    let insights: [DomainInsight]
    let horoscope: String?
    let onDomainTap: (DomainInsight) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var gridInsights: [DomainInsight] {
        // First 6 domains for 2-column grid
        insights.filter { $0.domain != .spiritual }.prefix(6).map { $0 }
    }

    private var spiritualInsight: DomainInsight? {
        insights.first { $0.domain == .spiritual }
    }

    var body: some View {
        VStack(spacing: Cosmic.Spacing.lg) {
            // Cosmic Weather Header
            cosmicWeatherHeader

            // Domain Cards Grid (2 columns)
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Cosmic.Spacing.sm),
                    GridItem(.flexible(), spacing: Cosmic.Spacing.sm)
                ],
                spacing: Cosmic.Spacing.sm
            ) {
                ForEach(gridInsights) { insight in
                    DomainCardView(insight: insight) {
                        onDomainTap(insight)
                    }
                }
            }

            // Spiritual - Full width at bottom
            if let spiritual = spiritualInsight {
                DomainCardWideView(insight: spiritual) {
                    onDomainTap(spiritual)
                }
            }
        }
    }

    // MARK: - Cosmic Weather Header

    private var cosmicWeatherHeader: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            // Date and title
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Cosmic Weather")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Text(formattedDate)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }

                Spacer()

                // Animated cosmic glow
                if !reduceMotion {
                    CosmicGlowOrb()
                        .frame(width: 40, height: 40)
                }
            }

            // Daily energy summary
            if let horoscope = horoscope, !horoscope.isEmpty {
                Text(horoscope)
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(defaultSummary)
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .lineSpacing(4)
            }
        }
        .padding(Cosmic.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cosmicSurface,
                            Color.cosmicSurface.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.cosmicGold.opacity(0.3),
                            Color.cosmicGold.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: Cosmic.Border.hairline
                )
        )
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
    }

    private var defaultSummary: String {
        "The cosmos aligns to bring you clarity and purpose today. Pay attention to the subtle energies around you and trust your intuition."
    }
}

// MARK: - Cosmic Glow Orb

private struct CosmicGlowOrb: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.cosmicGold.opacity(0.4),
                            Color.cosmicGold.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 20
                    )
                )
                .scaleEffect(1.0 + sin(phase) * 0.15)

            // Inner core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.cosmicGold,
                            Color.cosmicGold.opacity(0.6)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: 16, height: 16)
                .shadow(color: Color.cosmicGold.opacity(0.5), radius: 4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                phase = .pi
            }
        }
    }
}

// MARK: - Preview

#Preview("Domain Grid") {
    ScrollView {
        DomainGridView(
            insights: DomainInsight.samples,
            horoscope: "A day of cosmic harmony awaits. The Sun's trine to Jupiter brings optimism and expansion, while Venus in Capricorn grounds your relationships in practical affection.",
            onDomainTap: { insight in
                print("Tapped: \(insight.domain.displayName)")
            }
        )
        .padding()
    }
    .background(Color.cosmicBackground)
}
