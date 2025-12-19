import SwiftUI

// MARK: - Meaning Stack
// Three cards answering: What energy am I in? What's changing? What should I do?

struct MeaningStack: View {
    let snapshot: TimeTravelSnapshot
    let isCompact: Bool
    let onNowTapped: () -> Void
    let onNextTapped: () -> Void
    let onActTapped: () -> Void

    @State private var expandedWhySection: Bool = false

    private var nextTransition: NextTransition? {
        snapshot.nextTransitions.first
    }

    var body: some View {
        if isCompact {
            compactBar
        } else {
            fullStack
        }
    }

    // MARK: - Full Stack (3 cards)

    private var fullStack: some View {
        VStack(spacing: Cosmic.Spacing.sm) {
            nowCard
            nextCard
            actCard
        }
    }

    // MARK: - NOW Card

    private var nowCard: some View {
        Button(action: onNowTapped) {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                // Header
                HStack {
                    Text("NOW")
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(Color.cosmicTextSecondary)

                    Spacer()

                    // Dasha lords with symbols
                    HStack(spacing: Cosmic.Spacing.xxs) {
                        Text(snapshot.currentDasha.mahadasha.symbol)
                            .font(.cosmicTitle2)
                        Text("•")
                            .foregroundStyle(Color.cosmicTextSecondary)
                        Text(snapshot.currentDasha.antardasha.symbol)
                            .font(.cosmicTitle2)
                    }
                }

                // Theme - with fallback to ensure visibility
                Text(snapshot.now.theme.isEmpty ? "\(snapshot.currentDasha.mahadasha.lord) • \(snapshot.currentDasha.antardasha.lord) Period" : snapshot.now.theme)
                    .font(.cosmicHeadline)
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                // Risk & Opportunity
                HStack(spacing: Cosmic.Spacing.md) {
                    // Risk
                    HStack(spacing: Cosmic.Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicWarning)
                        Text(snapshot.now.risk.isEmpty ? "Be mindful" : snapshot.now.risk)
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }

                    Spacer()

                    // Opportunity
                    HStack(spacing: Cosmic.Spacing.xs) {
                        Image(systemName: "sparkles")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicGold)
                        Text(snapshot.now.opportunity.isEmpty ? "Growth available" : snapshot.now.opportunity)
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                }
            }
            .padding()
            .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(LinearGradient(
                        colors: [.cosmicGold.opacity(0.3), .cosmicGold.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current energy: \(snapshot.currentDasha.mahadasha.lord) \(snapshot.currentDasha.antardasha.lord). \(snapshot.now.theme)")
        .accessibilityHint("Tap for more details")
    }

    // MARK: - NEXT Card

    @ViewBuilder
    private var nextCard: some View {
        if let soonest = nextTransition {
            Button(action: onNextTapped) {
                VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                    // Header with countdown
                    HStack {
                        Text("NEXT")
                            .font(.cosmicCaptionEmphasis)
                            .foregroundStyle(Color.cosmicTextSecondary)

                        Spacer()

                        Text("\(soonest.transitionType.shortLabel) in \(soonest.countdownShort)")
                            .font(.cosmicCaptionEmphasis)
                            .foregroundStyle(Color.cosmicInfo)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cosmicInfo.opacity(0.15), in: Capsule())
                    }

                    // High-density timeline: praty / antar / maha
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
                        ForEach(snapshot.nextTransitions.prefix(3)) { transition in
                            HStack(spacing: Cosmic.Spacing.sm) {
                                Text(transition.transitionType.shortLabel)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(transitionColor(for: transition.transitionType))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(transitionColor(for: transition.transitionType).opacity(0.14), in: Capsule())

                                Text("\(transition.fromLord) → \(transition.toLord)")
                                    .font(.cosmicCalloutEmphasis)

                                Spacer()

                                Text(transition.countdownShort)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(Color.cosmicTextSecondary)
                            }
                        }

                        Text(soonest.whatShifts)
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                            .lineLimit(2)
                    }
                }
                .padding()
                .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Next shift: \(soonest.transitionType.rawValue) in \(soonest.daysUntil) days. \(soonest.whatShifts)")
        }
    }

    // MARK: - ACT Card

    private var actCard: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            // Header
            HStack {
                Text("ACT")
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicTextSecondary)

                Spacer()

                Button(action: onActTapped) {
                    Image(systemName: "arrow.up.right.circle")
                        .font(.cosmicTitle2)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
            }

            // Do this
            HStack(alignment: .top, spacing: Cosmic.Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicSuccess)

                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text("Do")
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(Color.cosmicTextSecondary)
                    Text(snapshot.act.doThis)
                        .font(.cosmicCallout)
                }
            }

            // Avoid this
            HStack(alignment: .top, spacing: Cosmic.Spacing.sm) {
                Image(systemName: "xmark.circle.fill")
                    .font(.cosmicBody)
                    .foregroundStyle(Color.cosmicError)

                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                    Text("Avoid")
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(Color.cosmicTextSecondary)
                    Text(snapshot.act.avoidThis)
                        .font(.cosmicCallout)
                }
            }

            // Why expandable
            Button {
                withAnimation(.cosmicSpring) {
                    expandedWhySection.toggle()
                }
                CosmicHaptics.light()
            } label: {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.cosmicCaption)
                    Text("Why")
                        .font(.cosmicCaptionEmphasis)
                    Spacer()
                    Image(systemName: expandedWhySection ? "chevron.up" : "chevron.down")
                        .font(.cosmicMicro)
                }
                .foregroundStyle(Color.cosmicTextSecondary)
                .padding(.top, 4)
            }
            .buttonStyle(.plain)

            if expandedWhySection {
                Text(snapshot.act.whyExplanation)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .padding(.top, 4)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .padding()
        .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.soft))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Action guidance. Do: \(snapshot.act.doThis). Avoid: \(snapshot.act.avoidThis)")
    }

    // MARK: - Compact Bar (for sticky header)

    private var compactBar: some View {
        HStack(spacing: Cosmic.Spacing.sm) {
            // Dasha summary
            HStack(spacing: Cosmic.Spacing.xxs) {
                Text(snapshot.currentDasha.mahadasha.symbol)
                Text("•")
                    .foregroundStyle(Color.cosmicTextSecondary)
                Text(snapshot.currentDasha.antardasha.symbol)
            }
            .font(.cosmicCalloutEmphasis)

            Divider()
                .frame(height: 16)

            // Countdown
            if let soonest = nextTransition {
                Text("\(soonest.countdownShort) to \(soonest.toLord)")
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }

            Divider()
                .frame(height: 16)

            // Quick action
            Text("Do: \(String(snapshot.act.doThis.prefix(20)))...")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
                .lineLimit(1)

            Spacer()

            // Expand button
            Button {
                // Handled by parent
            } label: {
                Image(systemName: "chevron.down")
                    .font(.cosmicCaptionEmphasis)
                    .foregroundStyle(Color.cosmicTextSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.cosmicSurface)
    }
}

private extension MeaningStack {
    func transitionColor(for type: TransitionType) -> Color {
        switch type {
        case .pratyantardasha: return .cosmicAmethyst
        case .antardasha: return .cosmicInfo
        case .mahadasha: return .cosmicGold
        }
    }
}
