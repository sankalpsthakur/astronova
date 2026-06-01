import SwiftUI

// MARK: - Chart Constraint Card View
// Shows the user's specific chart constraints and guardrails —
// the "failure modes" hardcoded into their birth chart.

// MARK: - Data Models

struct ChartConstraint: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let guardrail: String
    let severity: ConstraintSeverity
    let affectedPlanet: String
    let affectedHouse: Int

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case guardrail
        case severity
        case affectedPlanet
        case affectedHouse
    }
}

enum ConstraintSeverity: String, CaseIterable, Codable {
    case critical = "Critical"
    case high = "High"
    case moderate = "Moderate"

    var color: Color {
        switch self {
        case .critical: return Color(red: 0.95, green: 0.3, blue: 0.2)
        case .high: return Color(red: 0.95, green: 0.6, blue: 0.15)
        case .moderate: return Color.cosmicGold
        }
    }

    var icon: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.shield.fill"
        case .moderate: return "info.circle.fill"
        }
    }

    var label: String {
        rawValue
    }
}

// MARK: - Planet Color Helper

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

struct ConstraintCardView: View {
    let constraints: [ChartConstraint]

    private var displayConstraints: [ChartConstraint] {
        Array(constraints.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
            headerSection

            if displayConstraints.isEmpty {
                emptyState
            } else {
                constraintCardsList
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
            HStack(spacing: Cosmic.Spacing.xs) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.cosmicGold)

                Text("Chart Constraints")
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
            }
            .accessibilityAddTraits(.isHeader)

            Text("Your built-in failure modes — and how to guard against them")
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextSecondary)
                .accessibilityLabel("Subtitle: Your built-in failure modes and how to guard against them")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: Cosmic.Spacing.sm) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color.cosmicSuccess)

            Text("No major constraints detected")
                .font(.cosmicBody)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Cosmic.Spacing.screen)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .fill(Color.cosmicSurface.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(Color.cosmicSuccess.opacity(0.2), lineWidth: Cosmic.Border.thin)
        )
        .accessibilityLabel("No major constraints detected in your chart")
    }

    // MARK: - Constraint Cards List

    private var constraintCardsList: some View {
        VStack(spacing: Cosmic.Spacing.sm) {
            ForEach(Array(displayConstraints.enumerated()), id: \.element.id) { index, constraint in
                ConstraintCard(constraint: constraint)
                    .transition(.cosmicSlideUp)
                    .cosmicStaggeredAppear(index: index, isVisible: true)
            }
        }
    }
}

// MARK: - Single Constraint Card

private struct ConstraintCard: View {
    let constraint: ChartConstraint

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left severity border
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(constraint.severity.color)
                .frame(width: 4)

            // Content
            VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                // Top row: severity badge + title
                topRow

                // Description
                Text(constraint.description)
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .lineSpacing(CosmicTypography.LineHeight.body)
                    .fixedSize(horizontal: false, vertical: true)

                // Guardrail box
                guardrailBox

                // Bottom tags: planet + house
                bottomTags
            }
            .padding(Cosmic.Spacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .fill(Color.cosmicSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .stroke(Color.white.opacity(Cosmic.Opacity.subtle), lineWidth: Cosmic.Border.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
        .cosmicElevation(.subtle)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Constraint: \(constraint.title), Severity: \(constraint.severity.label)")
    }

    // MARK: - Top Row

    private var topRow: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
            HStack(spacing: Cosmic.Spacing.xs) {
                // Severity badge
                HStack(spacing: 4) {
                    Image(systemName: constraint.severity.icon)
                        .font(.system(size: 11, weight: .semibold))
                    Text(constraint.severity.label)
                        .font(.cosmicCaption)
                }
                .foregroundStyle(constraint.severity.color)
                .padding(.horizontal, Cosmic.Spacing.xs)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous)
                        .fill(constraint.severity.color.opacity(0.12))
                )
                .accessibilityLabel("Severity: \(constraint.severity.label)")

                Spacer()

                // Mini icon indicating constraint area
                Image(systemName: "scope")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.cosmicTextTertiary.opacity(0.6))
            }

            // Title
            Text(constraint.title)
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)
                .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - Guardrail Box

    private var guardrailBox: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label {
                Text("Guardrail")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicGold)
            } icon: {
                Image(systemName: "light.beacon.max.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.cosmicGold)
            }

            Text(constraint.guardrail)
                .font(.cosmicCallout)
                .foregroundStyle(Color.cosmicTextPrimary)
                .lineSpacing(CosmicTypography.LineHeight.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Cosmic.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                .fill(Color.cosmicGold.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                .stroke(Color.cosmicGold.opacity(0.15), lineWidth: Cosmic.Border.hairline)
        )
        .accessibilityLabel("Guardrail: \(constraint.guardrail)")
    }

    // MARK: - Bottom Tags

    private var bottomTags: some View {
        HStack(spacing: Cosmic.Spacing.xs) {
            PlanetTag(planet: constraint.affectedPlanet)
            HouseTag(house: constraint.affectedHouse)
            Spacer()
        }
    }
}

// MARK: - Planet Tag

private struct PlanetTag: View {
    let planet: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(planetColor(for: planet))
                .frame(width: 6, height: 6)
            Text(planet)
                .font(.cosmicMicro)
                .foregroundStyle(planetColor(for: planet))
        }
        .padding(.horizontal, Cosmic.Spacing.xs)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous)
                .fill(planetColor(for: planet).opacity(0.1))
        )
        .accessibilityLabel("Affected planet: \(planet)")
    }
}

// MARK: - House Tag

private struct HouseTag: View {
    let house: Int

    private var houseSuffix: String {
        switch house {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "house.fill")
                .font(.system(size: 8))
            Text("\(house)\(houseSuffix) House")
                .font(.cosmicMicro)
        }
        .foregroundStyle(Color.cosmicTextTertiary)
        .padding(.horizontal, Cosmic.Spacing.xs)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous)
                .fill(Color.cosmicTextTertiary.opacity(0.08))
        )
        .accessibilityLabel("Affected house: \(house)\(houseSuffix) House")
    }
}

// MARK: - Sample Data

extension ChartConstraint {
    static let samples: [ChartConstraint] = [
        ChartConstraint(
            title: "12th House Mercury Leak",
            description: "Mercury in the 12th house creates a tendency to intellectualize emotions rather than feel them. You may overanalyze relationships instead of experiencing them, and your communication can drift into escapism when things get difficult.",
            guardrail: "Pause before speaking in emotional situations. Write your thoughts privately first, then share only what serves connection. A 5-second silence before responding breaks the pattern.",
            severity: .critical,
            affectedPlanet: "Mercury",
            affectedHouse: 12
        ),
        ChartConstraint(
            title: "Saturn-Moon Conjunction in 4th",
            description: "Saturn's restrictive energy paired with the Moon in the house of home creates an inner critic that never rests. You set impossibly high emotional standards for yourself and may struggle to feel truly safe or nurtured, even in supportive environments.",
            guardrail: "Designate one 'permission space' where you practice receiving without earning. Start with 10 minutes daily of unscheduled, non-productive time. Your worth is not your output.",
            severity: .critical,
            affectedPlanet: "Saturn",
            affectedHouse: 4
        ),
        ChartConstraint(
            title: "Mars in 7th House Combustion",
            description: "Mars in the house of partnership burns hot and fast. You may attract conflict-driven relationships or provoke arguments in otherwise calm situations. The instinct to compete rather than collaborate in close bonds is strong.",
            guardrail: "When you feel the urge to 'win' a conversation with your partner, ask: 'What outcome do I actually want?' Redirect competitive energy into shared physical activities like training together.",
            severity: .high,
            affectedPlanet: "Mars",
            affectedHouse: 7
        ),
        ChartConstraint(
            title: "Rahu in 2nd House Amplification",
            description: "Rahu's insatiable hunger in the house of wealth creates an endless chase. No amount of money, possessions, or status feels like enough. You risk building a life of accumulation that never satisfies the deeper longing beneath.",
            guardrail: "Track your 'enough' metric weekly: write down three things you already have that you once desperately wanted. This rewires the scarcity narrative Rahu feeds on.",
            severity: .high,
            affectedPlanet: "Rahu",
            affectedHouse: 2
        ),
        ChartConstraint(
            title: "Debilitated Jupiter in 10th",
            description: "Jupiter in Capricorn (debilitated) in the career house dampens your natural optimism about professional growth. You may undervalue your contributions, settle for less than you deserve, or struggle to see the larger purpose in your daily work.",
            guardrail: "Keep a 'professional grace' log: record one instance each week where things worked out better than you expected. Jupiter's wisdom is present but quiet — you need to listen for it deliberately.",
            severity: .moderate,
            affectedPlanet: "Jupiter",
            affectedHouse: 10
        ),
    ]
}

// MARK: - Preview

#Preview("Constraints - Full") {
    ScrollView {
        ConstraintCardView(constraints: ChartConstraint.samples)
            .padding(Cosmic.Spacing.screen)
    }
    .background(Color.cosmicBackground)
    .preferredColorScheme(.dark)
}

#Preview("Constraints - Empty") {
    ScrollView {
        ConstraintCardView(constraints: [])
            .padding(Cosmic.Spacing.screen)
    }
    .background(Color.cosmicBackground)
    .preferredColorScheme(.dark)
}

#Preview("Constraints - Single") {
    ScrollView {
        ConstraintCardView(constraints: [ChartConstraint.samples[0]])
            .padding(Cosmic.Spacing.screen)
    }
    .background(Color.cosmicBackground)
    .preferredColorScheme(.dark)
}
