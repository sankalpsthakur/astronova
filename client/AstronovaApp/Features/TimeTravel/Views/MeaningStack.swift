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
        VStack(spacing: 12) {
            nowCard
            nextCard
            actCard
        }
    }

    // MARK: - NOW Card

    private var nowCard: some View {
        Button(action: onNowTapped) {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack {
                    Text("NOW")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Dasha lords with symbols
                    HStack(spacing: 4) {
                        Text(snapshot.currentDasha.mahadasha.symbol)
                            .font(.title3)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(snapshot.currentDasha.antardasha.symbol)
                            .font(.title3)
                    }
                }

                // Theme
                Text(snapshot.now.theme)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                // Risk & Opportunity
                HStack(spacing: 16) {
                    // Risk
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text(snapshot.now.risk)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Opportunity
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text(snapshot.now.opportunity)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
                VStack(alignment: .leading, spacing: 10) {
                    // Header with countdown
                    HStack {
                        Text("NEXT")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(soonest.transitionType.shortLabel) in \(soonest.countdownShort)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.cosmicInfo)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cosmicInfo.opacity(0.15), in: Capsule())
                    }

                    // High-density timeline: praty / antar / maha
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(snapshot.nextTransitions.prefix(3)) { transition in
                            HStack(spacing: 10) {
                                Text(transition.transitionType.shortLabel)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(transitionColor(for: transition.transitionType))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(transitionColor(for: transition.transitionType).opacity(0.14), in: Capsule())

                                Text("\(transition.fromLord) → \(transition.toLord)")
                                    .font(.subheadline.weight(.medium))

                                Spacer()

                                Text(transition.countdownShort)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(soonest.whatShifts)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Next shift: \(soonest.transitionType.rawValue) in \(soonest.daysUntil) days. \(soonest.whatShifts)")
        }
    }

    // MARK: - ACT Card

    private var actCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("ACT")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: onActTapped) {
                    Image(systemName: "arrow.up.right.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            // Do this
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Do")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(snapshot.act.doThis)
                        .font(.subheadline)
                }
            }

            // Avoid this
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(.red)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Avoid")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(snapshot.act.avoidThis)
                        .font(.subheadline)
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
                        .font(.caption)
                    Text("Why")
                        .font(.caption.weight(.medium))
                    Spacer()
                    Image(systemName: expandedWhySection ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }
            .buttonStyle(.plain)

            if expandedWhySection {
                Text(snapshot.act.whyExplanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Action guidance. Do: \(snapshot.act.doThis). Avoid: \(snapshot.act.avoidThis)")
    }

    // MARK: - Compact Bar (for sticky header)

    private var compactBar: some View {
        HStack(spacing: 12) {
            // Dasha summary
            HStack(spacing: 4) {
                Text(snapshot.currentDasha.mahadasha.symbol)
                Text("•")
                    .foregroundStyle(.secondary)
                Text(snapshot.currentDasha.antardasha.symbol)
            }
            .font(.subheadline.weight(.medium))

            Divider()
                .frame(height: 16)

            // Countdown
            if let soonest = nextTransition {
                Text("\(soonest.countdownShort) to \(soonest.toLord)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 16)

            // Quick action
            Text("Do: \(String(snapshot.act.doThis.prefix(20)))...")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            // Expand button
            Button {
                // Handled by parent
            } label: {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
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
