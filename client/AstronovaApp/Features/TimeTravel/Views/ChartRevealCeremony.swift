import SwiftUI

/// Wave 9 UX pass 2 — Move 2 (Chart-reveal ceremony, P10 peak experience).
///
/// The first time a user generates their birth chart we treat it as a peak moment.
/// A slow animated draw of a chart wheel, a subtle particle field, and a single line
/// of poetry that settles in below. 2-second pause before the surrounding UI activates.
///
/// Gated on `@AppStorage("hasSeenChartCeremony")` — fires only on the first reveal.
struct ChartRevealCeremony: View {
    /// Called when the ceremony lifecycle finishes (including the 2-second closing pause).
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var wheelProgress: CGFloat = 0
    @State private var poetryOpacity: Double = 0
    @State private var dotsVisible: Bool = false
    @State private var hasDismissed: Bool = false

    /// Three poetic closings; the chosen line is stable per ceremony invocation
    /// so it doesn't flicker if the view body re-evaluates.
    private let poetry: String

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        let lines = [
            "The sky was watching when you arrived.",
            "Here, your map of light.",
            "This is how the cosmos arranged itself for you."
        ]
        self.poetry = lines.randomElement() ?? lines[0]
    }

    var body: some View {
        ZStack {
            Color.cosmicBackground
                .ignoresSafeArea()

            // Subtle particle field — 20 randomised dots fading in and out.
            ParticleField(active: dotsVisible)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 32) {
                Spacer()

                ChartWheel(progress: wheelProgress)
                    .frame(width: 240, height: 240)
                    .shadow(color: Color.cosmicGold.opacity(0.25), radius: 18, x: 0, y: 0)

                Text(poetry)
                    .font(.cosmicTitle3.italic())
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .opacity(poetryOpacity)

                Spacer()
            }
        }
        .onAppear { runCeremony() }
        .onTapGesture { dismissEarly() }
        .accessibilityLabel("Chart reveal ceremony")
        .accessibilityHint("Tap to skip")
    }

    private func runCeremony() {
        // Particles start gently before the chart finishes drawing.
        withAnimation(.easeIn(duration: 0.5)) {
            dotsVisible = true
        }

        // Slow chart draw — 1.5 seconds.
        let drawDuration: Double = reduceMotion ? 0.4 : 1.5
        withAnimation(.easeOut(duration: drawDuration)) {
            wheelProgress = 1
        }

        // Poetry fades in just after the wheel settles.
        DispatchQueue.main.asyncAfter(deadline: .now() + drawDuration + 0.1) {
            withAnimation(.easeIn(duration: 0.6)) {
                poetryOpacity = 1
            }
        }

        // 2-second closing pause after poetry has appeared, then complete.
        let total = drawDuration + 0.7 + 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + total) {
            guard !hasDismissed else { return }
            hasDismissed = true
            onComplete()
        }
    }

    private func dismissEarly() {
        guard !hasDismissed else { return }
        hasDismissed = true
        onComplete()
    }
}

// MARK: - Chart Wheel

/// A simplified zodiac wheel drawn as a `Path` animatable through `progress`.
/// At `progress == 0` nothing is drawn; at `progress == 1` the wheel is whole.
private struct ChartWheel: View, Animatable {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let radius = min(size.width, size.height) / 2 - 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outerRect = CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            let innerRect = outerRect.insetBy(dx: radius * 0.18, dy: radius * 0.18)

            // Outer ring — drawn proportionally to progress.
            let outerStart: CGFloat = -90
            let outerEnd = outerStart + 360 * progress
            var outerPath = Path()
            outerPath.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(outerStart),
                endAngle: .degrees(outerEnd),
                clockwise: false
            )
            context.stroke(
                outerPath,
                with: .color(Color.cosmicGold),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )

            // Inner ring — slightly delayed by drawing only after 30% progress.
            let innerProgress = max(0, min(1, (progress - 0.2) / 0.8))
            if innerProgress > 0 {
                var innerPath = Path()
                innerPath.addArc(
                    center: center,
                    radius: radius * 0.78,
                    startAngle: .degrees(outerStart),
                    endAngle: .degrees(outerStart + 360 * innerProgress),
                    clockwise: false
                )
                context.stroke(
                    innerPath,
                    with: .color(Color.cosmicGold.opacity(0.55)),
                    style: StrokeStyle(lineWidth: 1, lineCap: .round)
                )
            }

            // House spokes — fade in over the final 40% of progress.
            let spokeProgress = max(0, min(1, (progress - 0.4) / 0.6))
            if spokeProgress > 0 {
                let spokeCount = 12
                for i in 0..<spokeCount {
                    let angle = Double(i) * (360.0 / Double(spokeCount)) - 90
                    let radians = angle * .pi / 180
                    let inner = CGPoint(
                        x: center.x + cos(radians) * radius * 0.42,
                        y: center.y + sin(radians) * radius * 0.42
                    )
                    let outer = CGPoint(
                        x: center.x + cos(radians) * radius,
                        y: center.y + sin(radians) * radius
                    )
                    var spoke = Path()
                    spoke.move(to: inner)
                    spoke.addLine(to: outer)
                    context.stroke(
                        spoke,
                        with: .color(Color.cosmicGold.opacity(0.35 * spokeProgress)),
                        lineWidth: 0.8
                    )
                }
            }

            // Center sigil — small filled circle fading in last.
            let centerProgress = max(0, min(1, (progress - 0.6) / 0.4))
            if centerProgress > 0 {
                let dot = Path(ellipseIn: CGRect(
                    x: center.x - 4,
                    y: center.y - 4,
                    width: 8,
                    height: 8
                ))
                context.fill(dot, with: .color(Color.cosmicGold.opacity(centerProgress)))
            }

            _ = innerRect // unused; reserved for future zodiac labels
        }
    }
}

// MARK: - Particle Field

/// Twenty randomised dots fading in and out. Pure SwiftUI `Canvas` — performant
/// even on iPhone SE class hardware because there's no per-frame layout work.
private struct ParticleField: View {
    let active: Bool

    /// Seeded so the layout is stable across re-renders inside a single ceremony.
    private let dots: [Dot] = {
        var rng = SystemRandomNumberGenerator()
        return (0..<20).map { _ in
            Dot(
                x: CGFloat.random(in: 0...1, using: &rng),
                y: CGFloat.random(in: 0...1, using: &rng),
                size: CGFloat.random(in: 1.5...3.5, using: &rng),
                phase: Double.random(in: 0...(.pi * 2), using: &rng)
            )
        }
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !active)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for dot in dots {
                    let alpha = 0.25 + 0.35 * (sin(t * 0.7 + dot.phase) + 1) / 2
                    let point = CGPoint(x: dot.x * size.width, y: dot.y * size.height)
                    let rect = CGRect(
                        x: point.x - dot.size / 2,
                        y: point.y - dot.size / 2,
                        width: dot.size,
                        height: dot.size
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(Color.cosmicGold.opacity(active ? alpha : 0))
                    )
                }
            }
        }
    }

    private struct Dot {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let phase: Double
    }
}

// MARK: - Convenience modifier

extension View {
    /// Presents the chart-reveal ceremony as a fullScreenCover the first time
    /// `condition` becomes true. Uses `@AppStorage("hasSeenChartCeremony")` to
    /// guarantee one-shot behaviour across launches.
    func chartRevealCeremony(
        when condition: Bool,
        onComplete: @escaping () -> Void = {}
    ) -> some View {
        modifier(ChartRevealCeremonyModifier(condition: condition, onComplete: onComplete))
    }
}

private struct ChartRevealCeremonyModifier: ViewModifier {
    let condition: Bool
    let onComplete: () -> Void

    @AppStorage("hasSeenChartCeremony") private var hasSeenChartCeremony: Bool = false
    @State private var isPresenting: Bool = false

    func body(content: Content) -> some View {
        content
            .onChange(of: condition) { _, newValue in
                guard newValue, !hasSeenChartCeremony, !isPresenting else { return }
                isPresenting = true
            }
            .fullScreenCover(isPresented: $isPresenting) {
                ChartRevealCeremony {
                    hasSeenChartCeremony = true
                    isPresenting = false
                    onComplete()
                }
                .interactiveDismissDisabled(true)
            }
    }
}
