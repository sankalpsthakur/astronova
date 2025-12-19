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
        Button {
            CosmicHaptics.light()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                // Icon and title row
                HStack(spacing: Cosmic.Spacing.xs) {
                    Image(systemName: insight.domain.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(accentColor)

                    Text(insight.domain.displayName)
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Spacer()

                    // Intensity indicator
                    intensityDot
                }

                // Short insight text
                Text(insight.shortInsight)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(Cosmic.Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .fill(Color.cosmicSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .stroke(
                        isPressed ? accentColor.opacity(0.4) : accentColor.opacity(0.15),
                        lineWidth: Cosmic.Border.hairline
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var intensityDot: some View {
        Circle()
            .fill(intensityColor)
            .frame(width: 8, height: 8)
            .shadow(color: intensityColor.opacity(0.5), radius: 2)
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
        Button {
            CosmicHaptics.light()
            onTap()
        } label: {
            HStack(spacing: Cosmic.Spacing.m) {
                // Icon
                Image(systemName: insight.domain.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(accentColor)
                    .frame(width: 40)

                // Content
                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text(insight.domain.displayName)
                        .font(.cosmicCalloutEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Text(insight.shortInsight)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
            .padding(Cosmic.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .fill(Color.cosmicSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                    .stroke(
                        isPressed ? accentColor.opacity(0.4) : accentColor.opacity(0.15),
                        lineWidth: Cosmic.Border.hairline
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
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
