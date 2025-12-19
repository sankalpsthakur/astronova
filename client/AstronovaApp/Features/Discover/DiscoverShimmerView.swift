import SwiftUI

/// Shimmer/skeleton loading view for Discover - "never blank" experience
struct DiscoverShimmerView: View {
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        ScrollView {
            VStack(spacing: Cosmic.Spacing.lg) {
                // Spacer for sticky bar placeholder
                shimmerBar
                    .padding(.horizontal, Cosmic.Spacing.m)
                    .padding(.top, 8)

                // Cosmic Lens placeholder
                shimmerLens
                    .padding(.top, Cosmic.Spacing.m)

                // Keywords placeholder
                shimmerKeywords
                    .padding(.horizontal, Cosmic.Spacing.m)

                // Narrative tiles placeholder
                VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                    shimmerText(width: 100)
                    shimmerText(width: 180)
                        .opacity(0.6)

                    ForEach(0..<3, id: \.self) { _ in
                        shimmerTile
                    }
                }
                .padding(.horizontal, Cosmic.Spacing.m)

                // Timeline placeholder
                shimmerTimeline
                    .padding(.horizontal, Cosmic.Spacing.m)

                // Reports placeholder
                VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
                    shimmerText(width: 140)

                    ForEach(0..<2, id: \.self) { _ in
                        shimmerReportCard
                    }
                }
                .padding(.horizontal, Cosmic.Spacing.m)

                Color.clear.frame(height: 120)
            }
        }
        .scrollIndicators(.hidden)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 1
            }
        }
    }

    // MARK: - Shimmer Components

    private var shimmerBar: some View {
        HStack(spacing: Cosmic.Spacing.m) {
            VStack(alignment: .leading, spacing: 4) {
                shimmerText(width: 40)
                shimmerText(width: 120)
            }

            Divider()
                .frame(height: 24)

            VStack(alignment: .leading, spacing: 4) {
                shimmerText(width: 40)
                shimmerText(width: 80)
            }

            Spacer()

            shimmerPill(width: 80)
        }
        .padding(Cosmic.Spacing.m)
        .background(Color.cosmicSurface)
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
    }

    private var shimmerLens: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(shimmerGradient, lineWidth: 2)
                .frame(width: 220, height: 220)

            // Middle arcs
            Circle()
                .stroke(shimmerGradient, lineWidth: 12)
                .frame(width: 180, height: 180)

            // Inner circle
            Circle()
                .fill(shimmerGradient)
                .frame(width: 80, height: 80)
        }
    }

    private var shimmerKeywords: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Cosmic.Spacing.xs) {
                ForEach(0..<5, id: \.self) { i in
                    shimmerPill(width: CGFloat(50 + i * 10))
                }
            }
        }
    }

    private var shimmerTile: some View {
        HStack(alignment: .top, spacing: Cosmic.Spacing.s) {
            // Domain indicator
            VStack(spacing: 4) {
                Circle()
                    .fill(shimmerGradient)
                    .frame(width: 32, height: 32)

                RoundedRectangle(cornerRadius: 2)
                    .fill(shimmerGradient)
                    .frame(width: 4, height: 20)
            }

            // Text content
            VStack(alignment: .leading, spacing: 8) {
                shimmerText(width: 200)
                shimmerText(width: 160)
            }

            Spacer()
        }
        .padding(Cosmic.Spacing.m)
        .background(Color.cosmicSurface)
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
    }

    private var shimmerTimeline: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
            shimmerText(width: 120)
            shimmerText(width: 160)
                .opacity(0.6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(0..<14, id: \.self) { _ in
                        VStack(spacing: 4) {
                            shimmerText(width: 12)
                            Circle()
                                .fill(shimmerGradient)
                                .frame(width: 12, height: 12)
                            shimmerText(width: 16)
                        }
                    }
                }
            }
        }
    }

    private var shimmerReportCard: some View {
        HStack(spacing: Cosmic.Spacing.m) {
            RoundedRectangle(cornerRadius: 10)
                .fill(shimmerGradient)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                shimmerText(width: 140)
                shimmerText(width: 100)
                    .opacity(0.6)
            }

            Spacer()

            shimmerText(width: 50)
        }
        .padding(Cosmic.Spacing.m)
        .background(Color.cosmicSurface)
        .clipShape(RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous))
    }

    // MARK: - Helper Views

    private func shimmerText(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(shimmerGradient)
            .frame(width: width, height: 12)
    }

    private func shimmerPill(width: CGFloat) -> some View {
        Capsule()
            .fill(shimmerGradient)
            .frame(width: width, height: 28)
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.cosmicSurface,
                Color.cosmicSurface.opacity(0.5),
                Color.cosmicSurface
            ]),
            startPoint: UnitPoint(x: shimmerOffset - 1, y: 0.5),
            endPoint: UnitPoint(x: shimmerOffset + 1, y: 0.5)
        )
    }
}

// MARK: - Motion Signatures

struct CosmicMotionSignatures {
    /// Lens tilt + glow animation
    static func lensTilt() -> Animation {
        .spring(response: 0.4, dampingFraction: 0.7)
    }

    /// Narrative tile morph + underline sweep
    static func tileMorph() -> Animation {
        .easeInOut(duration: 0.25)
    }

    /// Relationship pulse breathing
    static func pulseBreathing(intensity: Double) -> Animation {
        .easeInOut(duration: 2.0 - intensity).repeatForever(autoreverses: true)
    }

    /// Timeline dot-to-card spring expansion
    static func dotExpansion() -> Animation {
        .spring(response: 0.35, dampingFraction: 0.65)
    }

    /// Action chip bounce
    static func chipBounce() -> Animation {
        .spring(response: 0.3, dampingFraction: 0.5)
    }

    /// Fade for reduced motion
    static func reducedMotionFade() -> Animation {
        .easeOut(duration: 0.2)
    }
}

// MARK: - Reduced Motion Support

extension View {
    /// Apply animation with reduced motion fallback
    @ViewBuilder
    func cosmicAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            self.animation(CosmicMotionSignatures.reducedMotionFade(), value: value)
        } else {
            self.animation(animation, value: value)
        }
    }
}

// MARK: - Preview

#Preview {
    DiscoverShimmerView()
        .background(Color.cosmicBackground)
}
