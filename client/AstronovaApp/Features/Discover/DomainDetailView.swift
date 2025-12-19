import SwiftUI

/// Detail view for a life domain showing full insight, planetary drivers, and report CTA
struct DomainDetailView: View {
    let insight: DomainInsight
    let hasSubscription: Bool
    let onGetReport: (String) -> Void
    let onUpgrade: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var accentColor: Color {
        switch insight.domain {
        case .personal: return .cosmicGold
        case .love: return .planetVenus
        case .career: return .planetSaturn
        case .wealth: return .planetJupiter
        case .health: return .planetMars
        case .family: return .planetMoon
        case .spiritual: return .cosmicAmethyst
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cosmicBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xl) {
                        // Header with icon and domain name
                        headerSection

                        // Main insight
                        insightSection

                        // What's driving this
                        driversSection

                        // Report CTA
                        reportCTASection

                        // Bottom spacing
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, Cosmic.Spacing.screen)
                    .padding(.top, Cosmic.Spacing.m)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                        }
                        .foregroundStyle(Color.cosmicGold)
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: Cosmic.Spacing.m) {
            // Icon with glow
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: insight.domain.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(insight.domain.displayName)
                    .font(.cosmicTitle2)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Text("Today's Energy")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }

            Spacer()

            // Intensity badge
            intensityBadge
        }
    }

    private var intensityBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(intensityColor)
                .frame(width: 8, height: 8)

            Text(intensityLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(intensityColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(intensityColor.opacity(0.12))
        .clipShape(Capsule())
    }

    private var intensityColor: Color {
        if insight.intensity >= 0.7 {
            return .cosmicSuccess
        } else if insight.intensity >= 0.4 {
            return .cosmicWarning
        } else {
            return .cosmicTextTertiary
        }
    }

    private var intensityLabel: String {
        if insight.intensity >= 0.7 {
            return "Strong"
        } else if insight.intensity >= 0.4 {
            return "Moderate"
        } else {
            return "Gentle"
        }
    }

    // MARK: - Insight Section

    private var insightSection: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            // Quote-style main insight
            HStack(alignment: .top, spacing: Cosmic.Spacing.sm) {
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                Text(insight.fullInsight)
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .lineSpacing(6)
            }
        }
        .padding(Cosmic.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .fill(Color.cosmicSurface)
        )
    }

    // MARK: - Drivers Section

    private var driversSection: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.m) {
            // Section header
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.cosmicGold)

                Text("What's Driving This")
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
            }

            // Driver cards
            VStack(spacing: Cosmic.Spacing.sm) {
                ForEach(insight.drivers) { driver in
                    DriverCard(driver: driver, accentColor: accentColor)
                }
            }
        }
    }

    // MARK: - Report CTA Section

    private var reportCTASection: some View {
        VStack(spacing: Cosmic.Spacing.m) {
            // Divider
            Rectangle()
                .fill(Color.cosmicGold.opacity(0.15))
                .frame(height: 1)

            // CTA content
            VStack(spacing: Cosmic.Spacing.sm) {
                Text("Want deeper insights?")
                    .font(.cosmicCallout)
                    .foregroundStyle(Color.cosmicTextSecondary)

                Button {
                    CosmicHaptics.medium()
                    if hasSubscription {
                        onGetReport(insight.domain.reportType)
                    } else {
                        onUpgrade()
                    }
                } label: {
                    HStack(spacing: Cosmic.Spacing.xs) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 16))

                        Text("Get Your \(insight.domain.displayName) Forecast Report")
                            .font(.cosmicCalloutEmphasis)
                    }
                    .foregroundStyle(Color.cosmicVoid)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Cosmic.Spacing.m)
                    .background(
                        LinearGradient.cosmicAntiqueGold
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.button, style: .continuous))
                }

                if !hasSubscription {
                    Text("Included with Astronova Pro")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }
            }
        }
        .padding(.top, Cosmic.Spacing.m)
    }
}

// MARK: - Driver Card

private struct DriverCard: View {
    let driver: PlanetaryDriver
    let accentColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: Cosmic.Spacing.sm) {
            // Planet icon
            ZStack {
                Circle()
                    .fill(planetColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Text(planetSymbol)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 4) {
                // Planet + aspect/sign
                Text(driver.formattedTitle)
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)

                // Explanation
                Text(driver.explanation)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(Cosmic.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                .fill(Color.cosmicSurface.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                .stroke(planetColor.opacity(0.2), lineWidth: Cosmic.Border.hairline)
        )
    }

    private var planetColor: Color {
        switch driver.planet.lowercased() {
        case "sun": return .planetSun
        case "moon": return .planetMoon
        case "mercury": return .planetMercury
        case "venus": return .planetVenus
        case "mars": return .planetMars
        case "jupiter": return .planetJupiter
        case "saturn": return .planetSaturn
        case "uranus": return .planetUranus
        case "neptune": return .planetNeptune
        case "pluto": return .planetPluto
        default: return accentColor
        }
    }

    private var planetSymbol: String {
        switch driver.planet.lowercased() {
        case "sun": return "☉"
        case "moon": return "☽"
        case "mercury": return "☿"
        case "venus": return "♀"
        case "mars": return "♂"
        case "jupiter": return "♃"
        case "saturn": return "♄"
        case "uranus": return "♅"
        case "neptune": return "♆"
        case "pluto": return "♇"
        default: return "✦"
        }
    }
}

// MARK: - Preview

#Preview("Domain Detail - Love") {
    DomainDetailView(
        insight: DomainInsight.samples[1],
        hasSubscription: false,
        onGetReport: { _ in },
        onUpgrade: {}
    )
}

#Preview("Domain Detail - Career (Pro)") {
    DomainDetailView(
        insight: DomainInsight.samples[2],
        hasSubscription: true,
        onGetReport: { _ in },
        onUpgrade: {}
    )
}
