import SwiftUI

// MARK: - Archetype Header View
// A hero-style header card that synthesizes the entire chart
// into 1-2 archetype labels with supporting detail.

// MARK: - Data Model

struct ChartArchetype: Codable {
    let primary: String
    let secondary: String
    let synthesis: String
    let dominantElement: String
    let dominantPlanet: String
    let rajayogaCount: Int
    let constraintCount: Int
}

// MARK: - Element Color Helper

private func elementColor(for element: String) -> Color {
    switch element.lowercased() {
    case "fire": return Color(red: 0.95, green: 0.45, blue: 0.15)
    case "earth": return Color.cosmicCopper
    case "air": return Color.planetMercury
    case "water": return Color.planetNeptune
    default: return Color.cosmicGold
    }
}

private func elementIcon(for element: String) -> String {
    switch element.lowercased() {
    case "fire": return "flame.fill"
    case "earth": return "leaf.fill"
    case "air": return "wind"
    case "water": return "drop.fill"
    default: return "sparkles"
    }
}

private func planetColor(for name: String) -> Color {
    switch name.lowercased() {
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
    case "rahu": return .planetRahu
    case "ketu": return .planetKetu
    default: return .cosmicGold
    }
}

// MARK: - Main View

struct ArchetypeHeaderView: View {
    let archetype: ChartArchetype

    var body: some View {
        VStack(spacing: Cosmic.Spacing.md) {
            heroCard
            synthesisCard
            statsRow
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        ZStack(alignment: .topLeading) {
            // Gradient background
            RoundedRectangle(cornerRadius: Cosmic.Radius.hero, style: .continuous)
                .fill(LinearGradient.cosmicCelestialDawn)

            // Subtle starfield overlay for depth
            RoundedRectangle(cornerRadius: Cosmic.Radius.hero, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.1),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )

            // Content
            VStack(alignment: .center, spacing: Cosmic.Spacing.md) {
                // Top tags
                topTagsRow

                // Primary archetype
                Text(archetype.primary)
                    .font(.cosmicHero)
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, y: 2)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel("Primary archetype: \(archetype.primary)")

                // Secondary archetype
                Text(archetype.secondary)
                    .font(.cosmicTitle2)
                    .foregroundStyle(Color.cosmicGold)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.2), radius: 4)
                    .accessibilityLabel("Secondary archetype: \(archetype.secondary)")

                // Divider
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 60, height: 2)

                // Summary row
                summaryRow
            }
            .padding(.horizontal, Cosmic.Spacing.screen)
            .padding(.vertical, Cosmic.Spacing.xl)
            .frame(maxWidth: .infinity)
        }
        .frame(minHeight: 260)
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.hero, style: .continuous))
        .cosmicElevation(.glow(.cosmicGold))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Chart archetype: \(archetype.primary), with secondary: \(archetype.secondary)")
    }

    // MARK: - Top Tags Row

    private var topTagsRow: some View {
        HStack(spacing: Cosmic.Spacing.sm) {
            // Element tag
            HStack(spacing: 4) {
                Image(systemName: elementIcon(for: archetype.dominantElement))
                    .font(.system(size: 10))
                Text(archetype.dominantElement)
                    .font(.cosmicMicro)
            }
            .foregroundStyle(elementColor(for: archetype.dominantElement))
            .padding(.horizontal, Cosmic.Spacing.xs)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .accessibilityLabel("Dominant element: \(archetype.dominantElement)")

            // Planet tag
            HStack(spacing: 4) {
                Circle()
                    .fill(planetColor(for: archetype.dominantPlanet))
                    .frame(width: 6, height: 6)
                Text(archetype.dominantPlanet)
                    .font(.cosmicMicro)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, Cosmic.Spacing.xs)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .accessibilityLabel("Dominant planet: \(archetype.dominantPlanet)")

            Spacer()
        }
    }

    // MARK: - Summary Row

    private var summaryRow: some View {
        HStack(spacing: Cosmic.Spacing.lg) {
            summaryChip(
                value: "\(archetype.rajayogaCount)",
                label: "Rajayogas",
                icon: "crown.fill",
                color: .cosmicGold
            )

            summaryChip(
                value: "\(archetype.constraintCount)",
                label: "Constraints",
                icon: "shield.lefthalf.filled",
                color: Color(red: 0.95, green: 0.6, blue: 0.15)
            )
        }
    }

    private func summaryChip(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(value)
                    .font(.cosmicMonoLarge.weight(.bold))
            }
            .foregroundStyle(color)

            Text(label)
                .font(.cosmicMicro)
                .foregroundStyle(Color.white.opacity(0.6))
        }
        .accessibilityLabel("\(value) \(label)")
    }

    // MARK: - Synthesis Card

    private var synthesisCard: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left gold accent border
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.cosmicGold)
                .frame(width: 2)

            VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                HStack(spacing: Cosmic.Spacing.xs) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.cosmicGold)

                    Text("Chart Synthesis")
                        .font(.cosmicBodyEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }

                Text(archetype.synthesis)
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .lineSpacing(CosmicTypography.LineHeight.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Cosmic.Spacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(Color.cosmicGold.opacity(0.08), lineWidth: Cosmic.Border.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
        .cosmicElevation(.low)
        .accessibilityLabel("Chart synthesis: \(archetype.synthesis)")
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: Cosmic.Spacing.sm) {
            StatCapsule(
                icon: elementIcon(for: archetype.dominantElement),
                label: "Element",
                value: archetype.dominantElement,
                accent: elementColor(for: archetype.dominantElement)
            )

            StatCapsule(
                icon: "circle.hexagongrid.fill",
                label: "Dominant Planet",
                value: archetype.dominantPlanet,
                accent: planetColor(for: archetype.dominantPlanet)
            )

            StatCapsule(
                icon: "crown.fill",
                label: "Rajayogas",
                value: "\(archetype.rajayogaCount)",
                accent: .cosmicGold
            )
        }
    }
}

// MARK: - Stat Capsule

private struct StatCapsule: View {
    let icon: String
    let label: String
    let value: String
    let accent: Color

    var body: some View {
        HStack(spacing: Cosmic.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextTertiary)
                Text(value)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextPrimary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Cosmic.Spacing.sm)
        .padding(.vertical, Cosmic.Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                .stroke(Color.white.opacity(Cosmic.Opacity.subtle), lineWidth: Cosmic.Border.hairline)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Sample Data

extension ChartArchetype {
    static let sample: ChartArchetype = ChartArchetype(
        primary: "Sovereign Creator",
        secondary: "Capital Engineer",
        synthesis: "Your chart is built around a Leo ascendant with the Sun exalted in Aries in the 9th house of dharma, creating a powerful fire-dominant architecture. Jupiter's aspect on the 10th house and a strong 2nd-11th house axis makes material manifestation a natural byproduct of your creative output. The Moon in Rohini softens the fierce edges, adding an artistic sensibility and deep emotional intelligence. However, Saturn's conjunction with the Moon and Mercury in the 12th house introduces a contemplative counterweight — you build not for ego but because creation itself is your spiritual practice.",
        dominantElement: "Fire",
        dominantPlanet: "Jupiter",
        rajayogaCount: 4,
        constraintCount: 3
    )

    static let alternateSample: ChartArchetype = ChartArchetype(
        primary: "Wise Strategist",
        secondary: "Mystic Diplomat",
        synthesis: "A Capricorn ascendant with Saturn in its own sign in the 1st house gives you the rare gift of self-made authority. Mercury in the 11th house makes you a natural networker who thinks in systems, while Venus in Pisces in the 3rd house gives your words a lyrical, intuitive quality that draws people in. The Jupiter-Moon conjunction in the 5th house of intelligence brings both emotional depth and philosophical breadth. Your challenge is the Mars-Rahu conjunction in the 7th — partnerships will always test you, but they are also your greatest teacher.",
        dominantElement: "Earth",
        dominantPlanet: "Saturn",
        rajayogaCount: 3,
        constraintCount: 5
    )
}

// MARK: - Preview

#Preview("Archetype Header - Full") {
    ScrollView {
        ArchetypeHeaderView(archetype: .sample)
            .padding(Cosmic.Spacing.screen)
    }
    .background(Color.cosmicBackground)
    .preferredColorScheme(.dark)
}

#Preview("Archetype Header - Alternate") {
    ScrollView {
        ArchetypeHeaderView(archetype: .alternateSample)
            .padding(Cosmic.Spacing.screen)
    }
    .background(Color.cosmicBackground)
    .preferredColorScheme(.dark)
}
