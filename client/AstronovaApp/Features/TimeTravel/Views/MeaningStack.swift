import SwiftUI

// MARK: - Meaning Stack
// Two cards answering: What energy am I in? What's changing?

struct MeaningStack: View {
    let snapshot: TimeTravelSnapshot
    let isCompact: Bool
    let onNowTapped: () -> Void
    let onNextTapped: () -> Void

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

    // MARK: - Full Stack (2 cards)

    private var fullStack: some View {
        VStack(spacing: Cosmic.Spacing.md) {
            nowCard
            nextCard
        }
    }

    // MARK: - NOW Card

    private var nowCard: some View {
        Button(action: onNowTapped) {
            VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
                // Header: NOW label + dasha lords as cause
                HStack(alignment: .center) {
                    Text("NOW")
                        .cosmicUppercaseLabel()
                        .foregroundStyle(Color.cosmicGold)

                    Spacer()

                    // Dasha lords as a glowing pairing
                    HStack(spacing: Cosmic.Spacing.xs) {
                        Text(snapshot.currentDasha.mahadasha.symbol)
                            .font(.cosmicTitle1)
                            .cosmicFloat(amount: 3)
                        Text("·")
                            .font(.cosmicTitle2)
                            .foregroundStyle(Color.cosmicTextTertiary)
                        Text(snapshot.currentDasha.antardasha.symbol)
                            .font(.cosmicTitle1)
                            .cosmicFloat(amount: 3)
                    }
                }

                // Theme headline -- the revelation
                Text(snapshot.now.theme.isEmpty
                     ? "\(snapshot.currentDasha.mahadasha.lord) \u{00B7} \(snapshot.currentDasha.antardasha.lord) Period"
                     : snapshot.now.theme)
                    .font(.cosmicTitle1)
                    .tracking(CosmicTypography.Tracking.title)
                    .cosmicCelestialGradient()
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .cosmicBreathingGlow(color: .cosmicGold)

                // Risk & Opportunity -- vertically stacked with accent bars
                VStack(spacing: Cosmic.Spacing.xs) {
                    // Risk
                    HStack(spacing: Cosmic.Spacing.xs) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.cosmicError)
                            .frame(width: Cosmic.Border.accent, height: 20)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.cosmicCallout)
                            .foregroundStyle(Color.cosmicError)

                        Text(snapshot.now.risk.isEmpty ? "Be mindful" : snapshot.now.risk)
                            .font(.cosmicCalloutEmphasis)
                            .foregroundStyle(Color.cosmicError)

                        Spacer()
                    }
                    .padding(.vertical, Cosmic.Spacing.xs)
                    .padding(.horizontal, Cosmic.Spacing.sm)
                    .background(
                        Color.cosmicError.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: Cosmic.Radius.subtle)
                    )

                    // Opportunity
                    HStack(spacing: Cosmic.Spacing.xs) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.cosmicSuccess)
                            .frame(width: Cosmic.Border.accent, height: 20)

                        Image(systemName: "sparkles")
                            .font(.cosmicCallout)
                            .foregroundStyle(Color.cosmicSuccess)

                        Text(snapshot.now.opportunity.isEmpty ? "Growth available" : snapshot.now.opportunity)
                            .font(.cosmicCalloutEmphasis)
                            .foregroundStyle(Color.cosmicSuccess)

                        Spacer()
                    }
                    .padding(.vertical, Cosmic.Spacing.xs)
                    .padding(.horizontal, Cosmic.Spacing.sm)
                    .background(
                        Color.cosmicSuccess.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: Cosmic.Radius.subtle)
                    )
                }
            }
            .padding(Cosmic.Spacing.screen)
            .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.hero, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Cosmic.Radius.hero, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.cosmicGold, .cosmicGold.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: Cosmic.Border.thick
                    )
            )
            .cosmicElevation(.medium)
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
                VStack(alignment: .leading, spacing: Cosmic.Spacing.md) {
                    // Header with hero countdown
                    HStack(alignment: .top) {
                        Text("NEXT")
                            .cosmicUppercaseLabel()
                            .foregroundStyle(Color.cosmicTextSecondary)

                        Spacer()

                        // Hero countdown for soonest transition
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(countdownNumber(soonest))
                                .font(.cosmicMonoLarge)
                                .cosmicGoldGradient()
                            Text(countdownUnit(soonest))
                                .font(.cosmicMicro)
                                .foregroundStyle(Color.cosmicTextTertiary)
                        }
                    }

                    // Timeline visualization
                    VStack(alignment: .leading, spacing: 0) {
                        let transitions = Array(snapshot.nextTransitions.prefix(3))
                        ForEach(Array(transitions.enumerated()), id: \.element.id) { index, transition in
                            HStack(alignment: .top, spacing: Cosmic.Spacing.sm) {
                                // Timeline node + connector
                                VStack(spacing: 0) {
                                    // Node circle -- size escalates with transition importance
                                    Circle()
                                        .fill(transitionColor(for: transition.transitionType))
                                        .frame(
                                            width: nodeSize(for: transition.transitionType),
                                            height: nodeSize(for: transition.transitionType)
                                        )
                                        .overlay(
                                            // Outer ring for antardasha+
                                            Circle()
                                                .stroke(
                                                    transitionColor(for: transition.transitionType).opacity(0.4),
                                                    lineWidth: transition.transitionType == .pratyantardasha ? 0 : 1.5
                                                )
                                                .frame(
                                                    width: nodeSize(for: transition.transitionType) + 6,
                                                    height: nodeSize(for: transition.transitionType) + 6
                                                )
                                        )

                                    // Connector line (except last)
                                    if index < transitions.count - 1 {
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        transitionColor(for: transition.transitionType).opacity(0.4),
                                                        transitionColor(for: transitions[index + 1].transitionType).opacity(0.4)
                                                    ],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .frame(width: 2)
                                            .frame(maxHeight: .infinity)
                                    }
                                }
                                .frame(width: 22)

                                // Transition content
                                VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                                    HStack(spacing: Cosmic.Spacing.xs) {
                                        Text(transition.transitionType.shortLabel)
                                            .font(transitionLabelFont(for: transition.transitionType))
                                            .foregroundStyle(transitionColor(for: transition.transitionType))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(
                                                transitionColor(for: transition.transitionType).opacity(0.14),
                                                in: Capsule()
                                            )

                                        Text("\(transition.fromLord) \u{2192} \(transition.toLord)")
                                            .font(transitionBodyFont(for: transition.transitionType))
                                            .foregroundStyle(Color.cosmicTextPrimary)

                                        Spacer()

                                        Text(transition.countdownShort)
                                            .font(transitionCountdownFont(for: transition.transitionType))
                                            .foregroundStyle(urgencyColor(daysUntil: transition.daysUntil))
                                    }

                                    // Inline whatShifts description
                                    Text(transition.whatShifts)
                                        .font(.cosmicCaption)
                                        .foregroundStyle(Color.cosmicTextTertiary)
                                        .lineLimit(2)
                                }
                                .padding(.bottom, index < transitions.count - 1 ? Cosmic.Spacing.md : 0)
                            }
                        }
                    }
                }
                .padding(Cosmic.Spacing.screen)
                .background(Color.cosmicSurface, in: RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                        .stroke(Color.cosmicTextTertiary.opacity(0.15), lineWidth: Cosmic.Border.thin)
                )
                .cosmicElevation(.low)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Next shift: \(soonest.transitionType.rawValue) in \(soonest.daysUntil) days. \(soonest.whatShifts)")
        }
    }

    // MARK: - Compact Bar (for sticky header)

    private var compactBar: some View {
        HStack(spacing: Cosmic.Spacing.sm) {
            // Dasha summary
            HStack(spacing: Cosmic.Spacing.xxs) {
                Text(snapshot.currentDasha.mahadasha.symbol)
                Text("\u{00B7}")
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

            Text(snapshot.now.opportunity.isEmpty ? "Growth available" : snapshot.now.opportunity)
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

// MARK: - Helpers

private extension MeaningStack {
    func transitionColor(for type: TransitionType) -> Color {
        switch type {
        case .pratyantardasha: return .cosmicAmethyst
        case .antardasha: return .cosmicInfo
        case .mahadasha: return .cosmicGold
        }
    }

    func nodeSize(for type: TransitionType) -> CGFloat {
        switch type {
        case .pratyantardasha: return 8
        case .antardasha: return 12
        case .mahadasha: return 16
        }
    }

    func transitionLabelFont(for type: TransitionType) -> Font {
        switch type {
        case .pratyantardasha: return .caption2.weight(.bold)
        case .antardasha: return .caption.weight(.bold)
        case .mahadasha: return .callout.weight(.bold)
        }
    }

    func transitionBodyFont(for type: TransitionType) -> Font {
        switch type {
        case .pratyantardasha: return .cosmicCalloutEmphasis
        case .antardasha: return .cosmicBodyEmphasis
        case .mahadasha: return .cosmicHeadline
        }
    }

    func transitionCountdownFont(for type: TransitionType) -> Font {
        switch type {
        case .pratyantardasha: return .caption.monospacedDigit()
        case .antardasha: return .callout.monospacedDigit()
        case .mahadasha: return .body.weight(.semibold).monospacedDigit()
        }
    }

    func urgencyColor(daysUntil: Int) -> Color {
        if daysUntil < 7 { return .cosmicCopper }
        if daysUntil < 30 { return .cosmicAmethyst }
        return .cosmicTextSecondary
    }

    func countdownNumber(_ transition: NextTransition) -> String {
        if transition.daysUntil < 30 { return "\(transition.daysUntil)" }
        let months = max(1, transition.daysUntil / 30)
        if months < 24 { return "\(months)" }
        return "\(max(1, months / 12))"
    }

    func countdownUnit(_ transition: NextTransition) -> String {
        if transition.daysUntil < 30 { return transition.daysUntil == 1 ? "day" : "days" }
        let months = max(1, transition.daysUntil / 30)
        if months < 24 { return months == 1 ? "month" : "months" }
        let years = max(1, months / 12)
        return years == 1 ? "year" : "years"
    }
}
