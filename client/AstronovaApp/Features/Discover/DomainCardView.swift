import SwiftUI

/// Individual domain card showing icon, title, and short insight
/// Tappable to navigate to detail view
struct DomainCardView: View {
    let insight: DomainInsight
    let onTap: () -> Void

    @State private var isPressed = false

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
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            headerRow
            insightText
        }
        .padding(Cosmic.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .overlay(cardBorder)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .contentShape(Rectangle())
        .onTapGesture(perform: handleTap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.domain.displayName) domain. \(insight.shortInsight) Intensity: \(intensityLabel).")
        .accessibilityHint("Double tap to view detailed \(insight.domain.displayName) insights")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onTap() }
        .onLongPressGesture(minimumDuration: 0.01, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private var headerRow: some View {
        HStack(spacing: Cosmic.Spacing.xs) {
            Image(systemName: insight.domain.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(accentColor)
                .accessibilityHidden(true)

            Text(insight.domain.displayName)
                .font(.cosmicCalloutEmphasis)
                .foregroundStyle(Color.cosmicTextPrimary)

            Spacer()

            intensityDot
        }
    }

    private var insightText: some View {
        Text(insight.shortInsight)
            .font(.cosmicCaption)
            .foregroundStyle(Color.cosmicTextSecondary)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
            .fill(Color.cosmicSurface)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
            .stroke(
                isPressed ? accentColor.opacity(0.4) : accentColor.opacity(0.15),
                lineWidth: Cosmic.Border.hairline
            )
    }

    private func handleTap() {
        CosmicHaptics.light()
        onTap()
    }

    private var intensityDot: some View {
        Circle()
            .fill(intensityColor)
            .frame(width: 8, height: 8)
            .shadow(color: intensityColor.opacity(0.5), radius: 2)
            .accessibilityHidden(true)
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
            return "high"
        } else if insight.intensity >= 0.4 {
            return "moderate"
        } else {
            return "low"
        }
    }
}

/// Full-width domain card for spiritual (bottom of grid)
struct DomainCardWideView: View {
    let insight: DomainInsight
    let onTap: () -> Void

    @State private var isPressed = false

    private var accentColor: Color {
        .cosmicAmethyst
    }

    var body: some View {
        HStack(spacing: Cosmic.Spacing.m) {
            iconView
            contentView
            Spacer()
            chevronView
        }
        .padding(Cosmic.Spacing.m)
        .background(cardBackground)
        .overlay(cardBorder)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .contentShape(Rectangle())
        .onTapGesture(perform: handleTap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.domain.displayName) domain. \(insight.shortInsight)")
        .accessibilityHint("Double tap to view detailed \(insight.domain.displayName) insights")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onTap() }
        .onLongPressGesture(minimumDuration: 0.01, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private var iconView: some View {
        Image(systemName: insight.domain.icon)
            .font(.system(size: 24, weight: .medium))
            .foregroundStyle(accentColor)
            .frame(width: 40)
            .accessibilityHidden(true)
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
            Text(insight.domain.displayName)
                .font(.cosmicCalloutEmphasis)
                .foregroundStyle(Color.cosmicTextPrimary)

            Text(insight.shortInsight)
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
                .lineLimit(2)
        }
    }

    private var chevronView: some View {
        Image(systemName: "chevron.right")
            .font(.cosmicCaptionEmphasis)
            .foregroundStyle(Color.cosmicTextTertiary)
            .accessibilityHidden(true)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
            .fill(Color.cosmicSurface)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
            .stroke(
                isPressed ? accentColor.opacity(0.4) : accentColor.opacity(0.15),
                lineWidth: Cosmic.Border.hairline
            )
    }

    private func handleTap() {
        CosmicHaptics.light()
        onTap()
    }
}

// MARK: - Preview

#Preview("Domain Card") {
    VStack(spacing: 16) {
        DomainCardView(
            insight: DomainInsight.samples[0],
            onTap: {}
        )

        DomainCardView(
            insight: DomainInsight.samples[1],
            onTap: {}
        )

        DomainCardWideView(
            insight: DomainInsight.samples[6],
            onTap: {}
        )
    }
    .padding()
    .background(Color.cosmicBackground)
}
