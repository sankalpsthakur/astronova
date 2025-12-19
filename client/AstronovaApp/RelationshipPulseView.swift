import SwiftUI

// MARK: - Relationship Pulse View
// A compact animated component showing the relationship's current energy state.
// Works in list rows (compact) and headers (expanded).
// Tap reveals "why" - top activations contributing to current state.

struct RelationshipPulseView: View {
    let pulse: RelationshipPulse
    var isCompact: Bool = false
    var showLabel: Bool = true
    var onTap: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animationPhase: Double = 0

    var body: some View {
        Button(action: {
            CosmicHaptics.light()
            onTap?()
        }) {
            if isCompact {
                compactView
            } else {
                expandedView
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            guard !reduceMotion else {
                animationPhase = 0.5 // Static state for reduce motion
                return
            }
            withAnimation(.linear(duration: animationDuration).repeatForever(autoreverses: false)) {
                animationPhase = 1
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pulse.state.frequencyLabel) vibration, \(pulse.intensity.displayLabel) alignment")
        .accessibilityHint("Tap to see what's contributing to this energy state")
    }

    // MARK: - Compact View (for list rows)

    private var compactView: some View {
        HStack(spacing: 6) {
            pulseGlyph
                .frame(width: 24, height: 24)

            if showLabel {
                Text(pulse.label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(pulseColor.opacity(0.9))
            }
        }
    }

    // MARK: - Expanded View (for detail header)

    private var expandedView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                pulseGlyph
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pulse.state.frequencyLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Text("\(pulse.intensity.displayLabel) vibrational alignment")
                        .font(.caption)
                        .foregroundStyle(Color.cosmicTextTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.cosmicTextTertiary)
            }

            // Waveform visualization
            waveformView
                .frame(height: 32)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(pulseColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(pulseColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Pulse Glyph

    private var pulseGlyph: some View {
        ZStack {
            // Outer glow (animated)
            Circle()
                .fill(pulseColor.opacity(0.2))
                .scaleEffect(glowScale)

            // Inner circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [pulseColor, pulseColor.opacity(0.6)],
                        center: .center,
                        startRadius: 0,
                        endRadius: isCompact ? 12 : 22
                    )
                )
                .scaleEffect(pulseScale)

            // Icon
            Image(systemName: pulse.state.icon)
                .font(.system(size: isCompact ? 10 : 16, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(iconScale)
        }
    }

    // MARK: - Waveform View

    private var waveformView: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let midY = height / 2

            var path = Path()
            path.move(to: CGPoint(x: 0, y: midY))

            for x in stride(from: 0, through: width, by: 2) {
                let normalizedX = x / width
                let y = waveY(for: normalizedX, midY: midY, amplitude: height * 0.35)
                path.addLine(to: CGPoint(x: x, y: y))
            }

            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [pulseColor.opacity(0.3), pulseColor, pulseColor.opacity(0.3)]),
                    startPoint: CGPoint(x: 0, y: midY),
                    endPoint: CGPoint(x: width, y: midY)
                ),
                lineWidth: 2
            )

            // Glow effect
            context.stroke(
                path,
                with: .color(pulseColor.opacity(0.2)),
                lineWidth: 6
            )
        }
        .drawingGroup() // GPU acceleration for smooth waveform animation
    }

    private func waveY(for normalizedX: Double, midY: CGFloat, amplitude: CGFloat) -> CGFloat {
        let phase = animationPhase * 2 * .pi
        let frequency = waveFrequency

        switch pulse.state.animationStyle {
        case .smooth:
            return midY + sin(normalizedX * frequency + phase) * amplitude * 0.6
        case .rapid:
            return midY + sin(normalizedX * frequency * 2 + phase * 2) * amplitude
        case .slow:
            return midY + sin(normalizedX * frequency * 0.5 + phase * 0.5) * amplitude * 0.4
        case .erratic:
            let base = sin(normalizedX * frequency + phase)
            let noise = sin(normalizedX * frequency * 3 + phase * 1.5) * 0.3
            return midY + (base + noise) * amplitude
        case .pulsing:
            let beat = sin(normalizedX * frequency * 0.5 + phase)
            let sharp = pow(abs(beat), 0.5) * (beat > 0 ? 1 : -1)
            return midY + sharp * amplitude
        }
    }

    // MARK: - Animation Properties

    private var pulseColor: Color {
        switch pulse.state {
        case .flowing: return Color.cosmicTeal
        case .electric: return Color.cosmicGold
        case .grounded: return Color(red: 0.6, green: 0.5, blue: 0.4)
        case .friction: return Color(red: 0.95, green: 0.5, blue: 0.5)
        case .magnetic: return Color(red: 0.7, green: 0.5, blue: 0.9)
        }
    }

    private var animationDuration: Double {
        switch pulse.state.animationStyle {
        case .smooth: return 3.0
        case .rapid: return 1.0
        case .slow: return 5.0
        case .erratic: return 2.0
        case .pulsing: return 1.5
        }
    }

    private var waveFrequency: Double {
        switch pulse.state.animationStyle {
        case .smooth: return 4 * .pi
        case .rapid: return 8 * .pi
        case .slow: return 2 * .pi
        case .erratic: return 6 * .pi
        case .pulsing: return 3 * .pi
        }
    }

    private var glowScale: CGFloat {
        let base: CGFloat = 1.3
        let variation: CGFloat = 0.2
        return base + sin(animationPhase * 2 * .pi) * variation
    }

    private var pulseScale: CGFloat {
        let base: CGFloat = 1.0
        let variation: CGFloat
        switch pulse.state.animationStyle {
        case .smooth: variation = 0.05
        case .rapid: variation = 0.15
        case .slow: variation = 0.03
        case .erratic: variation = 0.1
        case .pulsing: variation = 0.12
        }
        return base + sin(animationPhase * 2 * .pi * 2) * variation
    }

    private var iconScale: CGFloat {
        let base: CGFloat = 1.0
        let variation: CGFloat = 0.1
        return base + sin(animationPhase * 2 * .pi * 1.5) * variation
    }
}

// MARK: - Pulse Explanation Sheet

struct PulseExplanationSheet: View {
    let pulse: RelationshipPulse
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        RelationshipPulseView(pulse: pulse, isCompact: false, showLabel: true)

                        Text(stateDescription)
                            .font(.body)
                            .foregroundStyle(Color.cosmicTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.cosmicSurface)
                    )

                    // What's contributing
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Frequency Activators")
                            .font(.headline)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        ForEach(pulse.topActivations, id: \.self) { activation in
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(Color.cosmicGold)

                                Text(activation)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.cosmicTextSecondary)

                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.cosmicSurface)
                            )
                        }
                    }

                    // What it means
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Vibrational Guidance")
                            .font(.headline)
                            .foregroundStyle(Color.cosmicTextPrimary)

                        Text(stateMeaning)
                            .font(.body)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                }
                .padding()
            }
            .background(Color.cosmicBackground.ignoresSafeArea())
            .navigationTitle("Energy Vibration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.cosmicGold)
                }
            }
        }
    }

    private var stateDescription: String {
        switch pulse.state {
        case .flowing:
            return "Your frequencies are resonating in harmony. Communication and understanding flow naturally between you."
        case .electric:
            return "High-frequency vibrations are amplifying your connection. Expect intense exchanges and heightened energy."
        case .grounded:
            return "Stable, steady vibrations create a reliable foundation. Your energies are well-calibrated together."
        case .friction:
            return "Your frequencies are temporarily out of sync. This creates tension, but also an opportunity for recalibration."
        case .magnetic:
            return "Strong vibrational pull is active. The energetic attraction between you is particularly powerful right now."
        }
    }

    private var stateMeaning: String {
        switch pulse.state {
        case .flowing:
            return "This resonant frequency supports heart-to-heart talks, making plans together, or simply enjoying each other's presence. The vibrational alignment enhances mutual understanding."
        case .electric:
            return "Channel this high-frequency energy constructively. Great for creative projects together, passionate discussions, or tackling challenges as a team. Be mindful of intensity spikes."
        case .grounded:
            return "Use this stable vibrational period to address practical matters, make commitments, or work on long-term goals. The steady frequency supports lasting decisions."
        case .friction:
            return "Don't avoid the dissonance—work through it. When frequencies clash, unspoken issues surface. Approach differences with curiosity to recalibrate your connection."
        case .magnetic:
            return "The attraction vibration is amplified. Perfect for romance, rekindling connection, or deepening intimacy. Ride this powerful energetic wave together."
        }
    }
}

// MARK: - Mini Pulse (for collapsed headers)

struct MiniPulseView: View {
    let pulse: RelationshipPulse

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animationPhase: Double = 0

    var body: some View {
        HStack(spacing: 4) {
            // Animated dots (static when reduce motion enabled)
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(pulseColor)
                    .frame(width: 4, height: 4)
                    .scaleEffect(reduceMotion ? 1.0 : dotScale(for: index))
            }

            Text(pulse.label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(pulseColor)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                animationPhase = 1
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pulse.label) energy state")
    }

    private var pulseColor: Color {
        switch pulse.state {
        case .flowing: return Color.cosmicTeal
        case .electric: return Color.cosmicGold
        case .grounded: return Color(red: 0.6, green: 0.5, blue: 0.4)
        case .friction: return Color(red: 0.95, green: 0.5, blue: 0.5)
        case .magnetic: return Color(red: 0.7, green: 0.5, blue: 0.9)
        }
    }

    private func dotScale(for index: Int) -> CGFloat {
        let phase = (animationPhase + Double(index) * 0.3).truncatingRemainder(dividingBy: 1.0)
        return 0.6 + sin(phase * .pi) * 0.4
    }
}

// MARK: - Preview

#Preview("Expanded") {
    ZStack {
        Color.cosmicBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            RelationshipPulseView(
                pulse: RelationshipPulse(state: .flowing, intensity: .strong, label: "Flowing", topActivations: ["Venus trine Moon"]),
                isCompact: false
            )

            RelationshipPulseView(
                pulse: RelationshipPulse(state: .electric, intensity: .intense, label: "Electric", topActivations: ["Mars conjunct Venus"]),
                isCompact: false
            )

            RelationshipPulseView(
                pulse: RelationshipPulse(state: .friction, intensity: .moderate, label: "Friction", topActivations: ["Saturn square Sun"]),
                isCompact: false
            )
        }
        .padding()
    }
}

#Preview("Compact") {
    ZStack {
        Color.cosmicBackground.ignoresSafeArea()

        VStack(spacing: 16) {
            HStack {
                Text("Relationship")
                    .foregroundStyle(Color.cosmicTextPrimary)
                Spacer()
                RelationshipPulseView(
                    pulse: RelationshipPulse(state: .flowing, intensity: .strong, label: "Flowing", topActivations: []),
                    isCompact: true
                )
            }
            .padding()
            .background(Color.cosmicSurface)
            .cornerRadius(12)

            HStack {
                Text("Connection")
                    .foregroundStyle(Color.cosmicTextPrimary)
                Spacer()
                RelationshipPulseView(
                    pulse: RelationshipPulse(state: .magnetic, intensity: .peak, label: "Magnetic", topActivations: []),
                    isCompact: true
                )
            }
            .padding()
            .background(Color.cosmicSurface)
            .cornerRadius(12)
        }
        .padding()
    }
}
