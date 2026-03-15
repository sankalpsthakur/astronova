import SwiftUI

// MARK: - House Insight Card
// Displays planet-in-house interpretation when a planet is tapped in the chart.

struct HouseInsightCard: View {
    let planet: PlanetState
    let insight: HouseInsight

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            // Header: Planet symbol + name + sign
            headerRow

            // House badge
            houseBadge

            // Summary
            Text(insight.summary)
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Strengths & Challenges
            if !insight.strengths.isEmpty || !insight.challenges.isEmpty {
                traitsSection
            }

            // Retrograde note
            if insight.isRetrograde, let note = insight.retrogradeNote {
                retrogradeNote(note)
            }
        }
        .padding(Cosmic.Spacing.screen)
        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.cosmicGold, .cosmicGold.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: Cosmic.Border.thin
                )
        )
        .cosmicElevation(.low)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(planet.name) in \(planet.sign), \(insight.houseName). \(insight.summary)")
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: Cosmic.Spacing.sm) {
            Text(planet.symbol)
                .font(.cosmicTitle1)
                .foregroundStyle(planetColor)

            VStack(alignment: .leading, spacing: Cosmic.Spacing.hair) {
                HStack(spacing: Cosmic.Spacing.xs) {
                    Text("\(planet.symbol) \(planet.name) in \(planet.sign)")
                        .font(.cosmicHeadline)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    if planet.isRetrograde {
                        Text("Rx")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.cosmicWarning)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.cosmicWarning.opacity(0.15), in: Capsule())
                    }
                }

                Text(String(format: "%.1f\u{00B0} %@", planet.degree, planet.sign))
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }

            Spacer()
        }
    }

    // MARK: - House Badge

    private var houseBadge: some View {
        HStack(spacing: Cosmic.Spacing.xs) {
            Image(systemName: "house.fill")
                .font(.cosmicCallout)
                .foregroundStyle(elementColor)

            Text("\(insight.houseName) \u{2014} \(insight.houseTheme)")
                .font(.cosmicCalloutEmphasis)
                .foregroundStyle(Color.cosmicTextPrimary)
        }
        .padding(.horizontal, Cosmic.Spacing.sm)
        .padding(.vertical, Cosmic.Spacing.xs)
        .background(
            elementColor.opacity(0.12),
            in: RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous)
        )
    }

    // MARK: - Strengths & Challenges

    private var traitsSection: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            // Strengths
            if !insight.strengths.isEmpty {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    ForEach(insight.strengths, id: \.self) { strength in
                        HStack(alignment: .top, spacing: Cosmic.Spacing.xs) {
                            Circle()
                                .fill(Color.cosmicSuccess)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)

                            Text(strength)
                                .font(.cosmicCaption)
                                .foregroundStyle(Color.cosmicSuccess)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            // Challenges
            if !insight.challenges.isEmpty {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    ForEach(insight.challenges, id: \.self) { challenge in
                        HStack(alignment: .top, spacing: Cosmic.Spacing.xs) {
                            Circle()
                                .fill(Color.cosmicWarning)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)

                            Text(challenge)
                                .font(.cosmicCaption)
                                .foregroundStyle(Color.cosmicWarning)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Retrograde Note

    private func retrogradeNote(_ note: String) -> some View {
        HStack(alignment: .top, spacing: Cosmic.Spacing.xs) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicWarning)

            Text(note)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Cosmic.Spacing.sm)
        .background(
            Color.cosmicWarning.opacity(0.08),
            in: RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous)
        )
    }

    // MARK: - Colors

    private var planetColor: Color {
        Self.planetColors[planet.id] ?? .cosmicTextPrimary
    }

    private var elementColor: Color {
        // Map signs to their element color
        let fireSign = ["Aries", "Leo", "Sagittarius"]
        let earthSign = ["Taurus", "Virgo", "Capricorn"]
        let airSign = ["Gemini", "Libra", "Aquarius"]
        let waterSign = ["Cancer", "Scorpio", "Pisces"]

        if fireSign.contains(planet.sign) { return .cosmicCopper }
        if earthSign.contains(planet.sign) { return .cosmicBrass }
        if airSign.contains(planet.sign) { return .cosmicInfo }
        if waterSign.contains(planet.sign) { return .cosmicAmethyst }
        return .cosmicGold
    }

    static let planetColors: [String: Color] = [
        "sun": .planetSun,
        "moon": .planetMoon,
        "mercury": .planetMercury,
        "venus": .planetVenus,
        "mars": .planetMars,
        "jupiter": .planetJupiter,
        "saturn": .planetSaturn,
        "uranus": .planetUranus,
        "neptune": .planetNeptune,
        "pluto": .planetPluto,
        "rahu": .planetRahu,
        "ketu": .planetKetu,
        "ascendant": .cosmicGold,
    ]
}
