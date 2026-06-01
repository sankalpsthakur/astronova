import SwiftUI

// MARK: - Data Models

/// A single event whose probability can be estimated from chart priors and user agency.
struct BayesianEvent: Identifiable {
    let id = UUID()
    let title: String
    let priorProbability: Double   // 0.0 – 1.0 (derived from astrological chart)
    let likelihood: Double         // 0.0 – 1.0 (adjusted by actions / free will)
    let eventClass: String         // "capital", "career", "health", etc.
}

/// Snapshot of the current Bayesian blend state.
struct BayesianState {
    var freeWillWeight: Double     // 0.0 – 1.0 (how much agency matters vs fate)
    var events: [BayesianEvent]
}

// MARK: - Comparable Clamp

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

// MARK: - Bayesian Slider View

/// Interactive Bayesian probability view — blends chart priors (fate) with
/// free will (agency) to compute live posterior event probabilities.
///
/// The core idea: "fate loads the dice, you throw them." The slider lets the
/// user decide how much weight to give astrological priors versus personal agency.
struct BayesianSliderView: View {

    // MARK: - State

    @State private var freeWillWeight: Double = 0.55

    // MARK: - Sample Events

    private let events: [BayesianEvent] = [
        BayesianEvent(
            title: "Capital round closes",
            priorProbability: 0.62,
            likelihood: 0.85,
            eventClass: "capital"
        ),
        BayesianEvent(
            title: "Dubai base goes live",
            priorProbability: 0.71,
            likelihood: 0.88,
            eventClass: "career"
        ),
        BayesianEvent(
            title: "Public output peaks",
            priorProbability: 0.55,
            likelihood: 0.78,
            eventClass: "career"
        ),
        BayesianEvent(
            title: "Saturn-shaped slow month",
            priorProbability: 0.70,
            likelihood: 0.40,
            eventClass: "health"
        ),
        BayesianEvent(
            title: "Joint / posture injury",
            priorProbability: 0.30,
            likelihood: 0.10,
            eventClass: "health"
        ),
    ]

    // MARK: - Computation

    /// Blend prior and likelihood using the free-will weight.
    /// posterior = (1 - w) * prior + w * likelihood, clamped to [0.05, 0.97]
    private func posterior(prior: Double, likelihood: Double, weight: Double) -> Double {
        (prior * (1.0 - weight) + likelihood * weight).clamped(to: 0.05...0.97)
    }

    /// Threshold-based posterior colour.
    private func posteriorColor(_ value: Double) -> Color {
        if value > 0.7 { return .cosmicSuccess }
        if value > 0.5 { return .cosmicGold }
        return .cosmicError
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                explanationSection
                sliderSection
                posteriorCardsSection
                Spacer().frame(height: 90)
            }
        }
        .background(Color.cosmicVoid)
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("bayesianSliderView")
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MODEL · BAYESIAN BLEND")
                        .font(.cosmicMicro)
                        .tracking(2)
                        .foregroundStyle(Color.cosmicTextTertiary)
                        .textCase(.uppercase)

                    Text("How fated is this?")
                        .font(.cosmicDisplay)
                        .tracking(CosmicTypography.Tracking.display)
                        .foregroundStyle(Color.cosmicTextPrimary)
                }

                Spacer()

                // Info button
                Button {
                    // Info action
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
                .accessibleIconButton()
            }
        }
        .padding(.horizontal, Cosmic.Spacing.screen)
        .padding(.top, Cosmic.Spacing.lg)
        .padding(.bottom, 8)
    }

    // MARK: - Explanation

    private var explanationSection: some View {
        Text(explanationAttributed)
            .font(.cosmicCallout)
            .tracking(CosmicTypography.Tracking.callout)
            .lineSpacing(4)
            .padding(.horizontal, Cosmic.Spacing.screen)
            .padding(.bottom, Cosmic.Spacing.lg)
    }

    private var explanationAttributed: AttributedString {
        var text = AttributedString(
            "The chart gives priors. Your actions give likelihoods. The slider mixes them — you decide where to weigh the model."
        )
        text.foregroundColor = .cosmicTextSecondary

        if let priorRange = text.range(of: "priors") {
            text[priorRange].foregroundColor = .cosmicGold
            text[priorRange].font = .cosmicCalloutEmphasis
        }
        if let likelihoodRange = text.range(of: "likelihoods") {
            text[likelihoodRange].foregroundColor = .cosmicInfo
            text[likelihoodRange].font = .cosmicCalloutEmphasis
        }

        return text
    }

    // MARK: - Slider

    private var sliderSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // Left / right labels
                HStack {
                    Text("← PRIOR / FATED")
                        .font(.cosmicMicro)
                        .tracking(3)
                        .foregroundStyle(Color.cosmicTextTertiary)

                    Spacer()

                    Text("FREE WILL →")
                        .font(.cosmicMicro)
                        .tracking(3)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }
                .padding(.bottom, 12)

                // Custom slider track + thumb
                sliderTrack
                    .frame(height: 44) // Apple HIG minimum touch target

                // Value labels below slider
                HStack(alignment: .firstTextBaseline) {
                    Text("prior  \((1.0 - freeWillWeight), specifier: "%.2f")")
                        .font(.cosmicMono)
                        .foregroundStyle(Color.cosmicGold)

                    Spacer()

                    Text("w = \(freeWillWeight, specifier: "%.2f")")
                        .font(.system(.title3, design: .serif).weight(.semibold))
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Spacer()

                    Text("\(freeWillWeight, specifier: "%.2f")  agency")
                        .font(.cosmicMono)
                        .foregroundStyle(Color.cosmicInfo)
                }
                .padding(.top, 8)
            }
            .padding(18)
            .background(Color.cosmicStardust)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
        }
        .padding(.horizontal, Cosmic.Spacing.screen)
    }

    private var sliderTrack: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let thumbDiameter: CGFloat = 28
            let thumbOffset = CGFloat(freeWillWeight) * (trackWidth - thumbDiameter)

            ZStack(alignment: .leading) {
                // Gradient track
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.cosmicGold, .cosmicInfo]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 4)
                    .offset(y: (44 - 4) / 2)

                // Thumb
                Circle()
                    .fill(Color.cosmicTextPrimary)
                    .overlay(
                        Circle()
                            .stroke(Color.cosmicStardust, lineWidth: 3)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(
                        color: Color(hex: "FFC878").opacity(0.35),
                        radius: 16,
                        x: 0,
                        y: 4
                    )
                    .frame(width: thumbDiameter, height: thumbDiameter)
                    .offset(x: thumbOffset, y: (44 - thumbDiameter) / 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let raw = value.location.x / trackWidth
                                let clamped = raw.clamped(to: 0.0...1.0)
                                if abs(clamped - freeWillWeight) > 0.001 {
                                    freeWillWeight = clamped
                                    CosmicAudio.shared.selection()
                                }
                            }
                    )
                    .animation(.cosmicSnappy, value: thumbOffset)
            }
        }
    }

    // MARK: - Posterior Cards

    private var posteriorCardsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                Text("POSTERIOR · 12-MONTH HORIZON")
                    .font(.cosmicMicro)
                    .tracking(3)
                    .foregroundStyle(Color.cosmicTextTertiary)

                Spacer()

                Text("P = wL + (1−w)π")
                    .font(.cosmicMicro)
                    .tracking(1)
                    .foregroundStyle(Color.cosmicGold)
            }
            .padding(.horizontal, Cosmic.Spacing.screen)
            .padding(.top, Cosmic.Spacing.lg)
            .padding(.bottom, 10)

            // Event cards
            VStack(spacing: 8) {
                ForEach(events) { event in
                    posteriorCard(for: event)
                }
            }
            .padding(.horizontal, Cosmic.Spacing.screen)
        }
    }

    private func posteriorCard(for event: BayesianEvent) -> some View {
        let p = posterior(prior: event.priorProbability,
                          likelihood: event.likelihood,
                          weight: freeWillWeight)
        let pColor = posteriorColor(p)

        return VStack(spacing: 0) {
            // Row 1: title + posterior number
            HStack(alignment: .firstTextBaseline) {
                Text(event.title)
                    .font(.cosmicCallout)
                    .foregroundStyle(Color.cosmicTextPrimary)

                Spacer()

                Text(String(format: "%.2f", p))
                    .font(.cosmicMono)
                    .foregroundStyle(pColor)
            }

            // Row 2: probability bar with ticks + fill
            probabilityBar(
                prior: event.priorProbability,
                likelihood: event.likelihood,
                posterior: p,
                color: pColor
            )
            .padding(.top, 8)

            // Row 3: prior / likelihood labels
            HStack {
                Text("π \(event.priorProbability, specifier: "%.2f")")
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.cosmicTextTertiary)

                Spacer()

                Text("L \(event.likelihood, specifier: "%.2f")")
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.cosmicTextTertiary)
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cosmicStardust)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }

    // MARK: - Probability Bar

    /// A horizontal bar showing the posterior fill width, with vertical tick
    /// marks at the prior (gold) and likelihood (cool) positions.
    private func probabilityBar(
        prior: Double,
        likelihood: Double,
        posterior: Double,
        color: Color
    ) -> some View {
        let barHeight: CGFloat = 6

        return GeometryReader { geometry in
            let totalWidth = geometry.size.width

            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.cosmicCosmos)
                    .frame(height: barHeight)

                // Prior tick mark (gold)
                tickMark(
                    color: .cosmicGold,
                    position: CGFloat(prior) * totalWidth,
                    barHeight: barHeight
                )

                // Likelihood tick mark (cool)
                tickMark(
                    color: .cosmicInfo,
                    position: CGFloat(likelihood) * totalWidth,
                    barHeight: barHeight
                )

                // Posterior fill
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(color)
                    .frame(width: CGFloat(posterior) * totalWidth, height: barHeight)
                    .animation(.cosmicSmooth, value: posterior)
            }
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        }
        .frame(height: 10) // 6pt bar + 2pt overhang on each side
    }

    /// A thin vertical tick that extends 2pt above and below the bar.
    private func tickMark(color: Color, position: CGFloat, barHeight: CGFloat) -> some View {
        Rectangle()
            .fill(color.opacity(0.5))
            .frame(width: 2)
            .frame(height: barHeight + 4)
            .offset(x: position - 1)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Bayesian Slider") {
    BayesianSliderView()
}
#endif
