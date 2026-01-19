import SwiftUI

// MARK: - Compatibility Meaning Stack
// Three cards answering: What's our vibration? What frequency shift is coming? How to align?
// Always visible, collapses into compact bar on scroll.

struct CompatibilityMeaningStack: View {
    let now: RelationshipNowInsight
    let next: NextShift
    let isCompact: Bool
    let onNowTapped: () -> Void
    let onNextTapped: () -> Void

    var body: some View {
        if isCompact {
            compactBar
        } else {
            expandedStack
        }
    }

    // MARK: - Compact Bar

    private var compactBar: some View {
        HStack(spacing: 12) {
            // Pulse mini
            MiniPulseView(pulse: now.pulse)

            Divider()
                .frame(height: 16)
                .background(Color.cosmicNebula)

            // Next countdown
            HStack(spacing: Cosmic.Spacing.xxs) {
                Text("\(next.daysUntil)d")
                    .font(.cosmicCaption)
                    .fontWeight(.bold)
                    .monospacedDigit()
                Text("→")
                Text(next.newState.rawValue.prefix(4))
                    .font(.cosmicMicro)
            }
            .foregroundStyle(Color.cosmicTextSecondary)

            Divider()
                .frame(height: 16)
                .background(Color.cosmicNebula)

            Text(now.sharedInsight.title)
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicGold)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Expanded Stack

    private var expandedStack: some View {
        VStack(spacing: 12) {
            // NOW Card
            nowCard

            // NEXT Card
            nextCard
        }
    }

    // MARK: - Now Card

    private var nowCard: some View {
        Button(action: onNowTapped) {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                HStack {
                    Label("VIBRATION", systemImage: "waveform.path")
                        .font(.cosmicCaption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.cosmicGold)

                    Spacer()

                    RelationshipPulseView(pulse: now.pulse, isCompact: true, showLabel: true)
                }

                Text(now.sharedInsight.title)
                    .font(.cosmicCalloutEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .multilineTextAlignment(.leading)

                Text(now.sharedInsight.sentence)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                // Linked aspects indicator
                if !now.sharedInsight.linkedAspectIds.isEmpty {
                    HStack(spacing: Cosmic.Spacing.xxs) {
                        Image(systemName: "link")
                            .font(.cosmicMicro)
                        Text("\(now.sharedInsight.linkedAspectIds.count) aspects contributing")
                            .font(.cosmicMicro)
                    }
                    .foregroundStyle(Color.cosmicTextTertiary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground(accent: Color.cosmicGold))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current vibration: \(now.sharedInsight.title). \(now.sharedInsight.sentence)")
        .accessibilityHint("Tap for more details about your current energy state")
    }

    // MARK: - Next Card

    private var nextCard: some View {
        Button(action: onNextTapped) {
            HStack(alignment: .top, spacing: Cosmic.Spacing.md) {
                // Countdown
                VStack(spacing: 2) {
                    Text("\(next.daysUntil)")
                        .font(.cosmicTitle1)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(nextColor)
                    Text("days")
                        .font(.cosmicMicro)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }
                .frame(width: 50)

                VStack(alignment: .leading, spacing: Cosmic.Spacing.xs) {
                    HStack {
                        Label("FREQUENCY SHIFT", systemImage: "waveform.badge.plus")
                            .font(.cosmicCaption)
                            .fontWeight(.bold)
                            .foregroundStyle(nextColor)

                        Spacer()

                        // New state indicator
                        HStack(spacing: Cosmic.Spacing.xxs) {
                            Circle()
                                .fill(nextStateColor)
                                .frame(width: 8, height: 8)
                            Text(next.newState.rawValue.capitalized)
                                .font(.cosmicMicro)
                                .fontWeight(.medium)
                                .foregroundStyle(nextStateColor)
                        }
                    }

                    Text(next.whatChanges)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .multilineTextAlignment(.leading)

                    Text(next.planForIt)
                        .font(.cosmicMicro)
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .italic()
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(Cosmic.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground(accent: nextColor))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Frequency shift in \(next.daysUntil) days to \(next.newState.rawValue). \(next.whatChanges)")
        .accessibilityHint("Tap for more details about the upcoming shift")
    }

    private var nextColor: Color {
        switch next.newState {
        case .flowing, .grounded: return Color.cosmicTeal
        case .electric, .magnetic: return Color.cosmicGold
        case .friction: return Color.cosmicCopper
        }
    }

    private var nextStateColor: Color {
        switch next.newState {
        case .flowing: return Color.cosmicTeal
        case .electric: return Color.cosmicGold
        case .grounded: return Color.cosmicBrass
        case .friction: return Color.cosmicCopper
        case .magnetic: return Color.cosmicAmethyst
        }
    }

    // MARK: - Card Background

    private func cardBackground(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.cosmicSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [accent.opacity(0.3), accent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Insight Detail Sheet

struct SharedInsightDetailSheet: View {
    let insight: SharedInsight
    let linkedAspects: [SynastryAspect]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.lg) {
                    // Main insight
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                        Text(insight.title)
                            .font(.cosmicTitle2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        Text(insight.sentence)
                            .font(.cosmicBody)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }

                    Divider()
                        .background(Color.cosmicNebula)

                    // Why
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                        Text("Vibrational Source")
                            .font(.cosmicHeadline)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        Text(insight.whyExpanded)
                            .font(.cosmicBody)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }

                    // Linked aspects
                    if !linkedAspects.isEmpty {
                        Divider()
                            .background(Color.cosmicNebula)

                        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                            Text("Frequency Activators")
                                .font(.cosmicHeadline)
                                .foregroundStyle(Color.cosmicTextPrimary)

                            ForEach(linkedAspects) { aspect in
                                LinkedAspectRow(aspect: aspect)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.cosmicBackground.ignoresSafeArea())
            .navigationTitle("Current Vibration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.cosmicGold)
                }
            }
        }
    }
}

struct LinkedAspectRow: View {
    let aspect: SynastryAspect

    var body: some View {
        HStack(spacing: Cosmic.Spacing.sm) {
            HStack(spacing: Cosmic.Spacing.xxs) {
                Text(aspect.planetAGlyph)
                    .foregroundStyle(Color.cosmicGold)
                Text(aspect.aspectGlyph)
                    .foregroundStyle(Color.cosmicTextTertiary)
                Text(aspect.planetBGlyph)
                    .foregroundStyle(Color.planetVenus)
            }
            .font(.cosmicBodyEmphasis)

            VStack(alignment: .leading, spacing: 2) {
                Text(aspect.interpretation.title)
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicTextPrimary)
                Text(aspect.interpretation.oneLiner)
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .lineLimit(1)
            }

            Spacer()

            if aspect.isActivatedNow {
                Text("Active")
                    .font(.cosmicMicro)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.cosmicGold)
                    .padding(.horizontal, Cosmic.Spacing.xs)
                    .padding(.vertical, Cosmic.Spacing.xxs)
                    .background(Color.cosmicGold.opacity(0.2))
                    .cornerRadius(Cosmic.Radius.subtle)
            }
        }
        .padding(Cosmic.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft)
                .fill(Color.cosmicSurface)
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.cosmicBackground.ignoresSafeArea()

        ScrollView {
            CompatibilityMeaningStack(
                now: .mock,
                next: .mock,
                isCompact: false,
                onNowTapped: {},
                onNextTapped: {}
            )
            .padding()
        }
    }
}

#Preview("Compact") {
    ZStack {
        Color.cosmicBackground.ignoresSafeArea()

        VStack {
            CompatibilityMeaningStack(
                now: .mock,
                next: .mock,
                isCompact: true,
                onNowTapped: {},
                onNextTapped: {}
            )

            Spacer()
        }
    }
}
