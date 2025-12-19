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
    let onActionTapped: () -> Void

    @State private var isWhyExpanded = false

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
            HStack(spacing: 4) {
                Text("\(next.daysUntil)d")
                    .font(.caption.weight(.bold).monospacedDigit())
                Text("→")
                Text(next.newState.rawValue.prefix(4))
                    .font(.caption2)
            }
            .foregroundStyle(Color.cosmicTextSecondary)

            Divider()
                .frame(height: 16)
                .background(Color.cosmicNebula)

            // Quick action
            Text(now.sharedInsight.suggestedAction.prefix(20) + "...")
                .font(.caption2)
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

            // ACT Card
            actCard
        }
    }

    // MARK: - Now Card

    private var nowCard: some View {
        Button(action: onNowTapped) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("VIBRATION", systemImage: "waveform.path")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.cosmicGold)

                    Spacer()

                    RelationshipPulseView(pulse: now.pulse, isCompact: true, showLabel: true)
                }

                Text(now.sharedInsight.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .multilineTextAlignment(.leading)

                Text(now.sharedInsight.sentence)
                    .font(.caption)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                // Linked aspects indicator
                if !now.sharedInsight.linkedAspectIds.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption2)
                        Text("\(now.sharedInsight.linkedAspectIds.count) aspects contributing")
                            .font(.caption2)
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
            HStack(alignment: .top, spacing: 16) {
                // Countdown
                VStack(spacing: 2) {
                    Text("\(next.daysUntil)")
                        .font(.title.weight(.bold).monospacedDigit())
                        .foregroundStyle(nextColor)
                    Text("days")
                        .font(.caption2)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }
                .frame(width: 50)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("FREQUENCY SHIFT", systemImage: "waveform.badge.plus")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(nextColor)

                        Spacer()

                        // New state indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(nextStateColor)
                                .frame(width: 8, height: 8)
                            Text(next.newState.rawValue.capitalized)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(nextStateColor)
                        }
                    }

                    Text(next.whatChanges)
                        .font(.caption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .multilineTextAlignment(.leading)

                    Text(next.planForIt)
                        .font(.caption2)
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .italic()
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(16)
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
        case .friction: return Color(red: 0.95, green: 0.6, blue: 0.5)
        }
    }

    private var nextStateColor: Color {
        switch next.newState {
        case .flowing: return Color.cosmicTeal
        case .electric: return Color.cosmicGold
        case .grounded: return Color(red: 0.6, green: 0.5, blue: 0.4)
        case .friction: return Color(red: 0.95, green: 0.5, blue: 0.5)
        case .magnetic: return Color(red: 0.7, green: 0.5, blue: 0.9)
        }
    }

    // MARK: - Act Card

    private var actCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("ALIGN", systemImage: "dot.radiowaves.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.cosmicGold)

            // Do
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.body)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Do")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.cosmicTextTertiary)
                    Text(now.sharedInsight.suggestedAction)
                        .font(.subheadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }
            }

            // Avoid
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red.opacity(0.8))
                    .font(.body)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Avoid")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.cosmicTextTertiary)
                    Text(now.sharedInsight.avoidAction)
                        .font(.subheadline)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }
            }

            // Why (expandable)
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isWhyExpanded.toggle()
                }
                CosmicHaptics.light()
            }) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.cosmicGold.opacity(0.7))
                    Text("Why?")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.cosmicGold.opacity(0.7))
                    Spacer()
                    Image(systemName: isWhyExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }
            }
            .buttonStyle(.plain)

            if isWhyExpanded {
                Text(now.sharedInsight.whyExpanded)
                    .font(.caption)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .padding(.leading, 24)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(accent: Color.cosmicGold.opacity(0.5)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Alignment guidance. Do: \(now.sharedInsight.suggestedAction). Avoid: \(now.sharedInsight.avoidAction)")
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
                VStack(alignment: .leading, spacing: 24) {
                    // Main insight
                    VStack(alignment: .leading, spacing: 12) {
                        Text(insight.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.cosmicTextPrimary)

                        Text(insight.sentence)
                            .font(.body)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }

                    Divider()
                        .background(Color.cosmicNebula)

                    // Actions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Alignment Actions")
                            .font(.headline)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        ActionRow(
                            icon: "checkmark.circle.fill",
                            iconColor: .green,
                            label: "Do",
                            text: insight.suggestedAction
                        )

                        ActionRow(
                            icon: "xmark.circle.fill",
                            iconColor: .red.opacity(0.8),
                            label: "Avoid",
                            text: insight.avoidAction
                        )
                    }

                    Divider()
                        .background(Color.cosmicNebula)

                    // Why
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Vibrational Source")
                            .font(.headline)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        Text(insight.whyExpanded)
                            .font(.body)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }

                    // Linked aspects
                    if !linkedAspects.isEmpty {
                        Divider()
                            .background(Color.cosmicNebula)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Frequency Activators")
                                .font(.headline)
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

struct ActionRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.cosmicTextTertiary)
                Text(text)
                    .font(.body)
                    .foregroundStyle(Color.cosmicTextPrimary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(iconColor.opacity(0.1))
        )
    }
}

struct LinkedAspectRow: View {
    let aspect: SynastryAspect

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Text(aspect.planetAGlyph)
                    .foregroundStyle(Color.cosmicGold)
                Text(aspect.aspectGlyph)
                    .foregroundStyle(Color.cosmicTextTertiary)
                Text(aspect.planetBGlyph)
                    .foregroundStyle(Color(red: 0.9, green: 0.6, blue: 0.7))
            }
            .font(.body.weight(.medium))

            VStack(alignment: .leading, spacing: 2) {
                Text(aspect.interpretation.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.cosmicTextPrimary)
                Text(aspect.interpretation.oneLiner)
                    .font(.caption2)
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .lineLimit(1)
            }

            Spacer()

            if aspect.isActivatedNow {
                Text("Active")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.cosmicGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cosmicGold.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
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
                onNextTapped: {},
                onActionTapped: {}
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
                onNextTapped: {},
                onActionTapped: {}
            )

            Spacer()
        }
    }
}
