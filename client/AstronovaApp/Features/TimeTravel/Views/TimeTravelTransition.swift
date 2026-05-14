//
//  TimeTravelTransition.swift
//  AstronovaApp
//
//  Wave 11 polish — Move 2 (Time Travel reveal polish).
//
//  When a user picks a past month from the March of Life, this view stages
//  a brief rewinding ceremony before the chart re-renders:
//    - 1.5s of subtle counter-rotation + opacity dim on a star field (the
//      "wheels back" feeling — atomic snapshot swap means we can't truly
//      animate per-planet, so we animate the surface).
//    - Slow-fade-in of the destination date in serif typography.
//    - A subtle particle field at the edges (reused from ChartRevealCeremony).
//
//  The implementation is a `fullScreenCover`-friendly overlay. Caller mounts
//  it as a transient overlay or sheet; on completion, it fires `onComplete`
//  and the caller dismisses.
//
//  Constraint note: `UnifiedTimeTravelView.fetchSnapshot` swaps `displaySnapshot`
//  atomically. There is no per-planet interpolation. The "planets retreat to
//  their past positions" sensation is conveyed through whole-chart motion
//  (rotation + scale) on the existing CosmicMapView while the new snapshot
//  loads underneath. Per-planet animation would require holding both the
//  source and destination snapshots and tweening between them — out of scope.
//

import SwiftUI

struct TimeTravelTransition: View {
    /// The destination date being scrubbed to.
    let destinationDate: Date
    /// Called once the transition finishes (1.5s rewind + 0.6s date fade).
    let onComplete: () -> Void

    @State private var rewindActive: Bool = false
    @State private var dateRevealed: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    var body: some View {
        ZStack {
            Color.cosmicVoid
                .opacity(0.94)
                .ignoresSafeArea()

            // Particle field — reuses ChartRevealCeremony's twenty-dot canvas.
            TimeTravelParticleField(active: !reduceMotion)
                .opacity(0.5)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Counter-rotating star wheel — the "rewinding" visual cue.
            // 12 dots arranged in a circle; the whole layer rotates backwards.
            ZStack {
                ForEach(0..<12) { i in
                    Circle()
                        .fill(Color.cosmicGold.opacity(0.4))
                        .frame(width: 4, height: 4)
                        .offset(y: -110)
                        .rotationEffect(.degrees(Double(i) * 30))
                }
            }
            .rotationEffect(.degrees(rewindActive ? -720 : 0))
            .opacity(rewindActive ? 0.0 : 0.85)
            .scaleEffect(rewindActive ? 0.65 : 1.0)
            .animation(reduceMotion ? .linear(duration: 0.4) : .easeInOut(duration: 1.5), value: rewindActive)

            // Destination date — serif typography, slow fade-in on arrival.
            VStack(spacing: Cosmic.Spacing.xs) {
                Text("REWINDING")
                    .font(.cosmicMicro)
                    .tracking(3)
                    .foregroundStyle(Color.cosmicGold.opacity(0.7))
                    .opacity(dateRevealed ? 0 : 0.9)

                Text(Self.dateFormatter.string(from: destinationDate))
                    .font(.system(.largeTitle, design: .serif).weight(.regular))
                    .foregroundStyle(Color.cosmicTextPrimary)
                    .opacity(dateRevealed ? 1 : 0)
                    .scaleEffect(dateRevealed ? 1 : 0.96)
                    .animation(reduceMotion ? .linear(duration: 0.3) : .easeOut(duration: 0.9), value: dateRevealed)

                Text("the sky as it was then")
                    .font(.cosmicCaption.italic())
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .opacity(dateRevealed ? 0.9 : 0)
            }
            .offset(y: 140)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rewinding to \(Self.dateFormatter.string(from: destinationDate))")
        .accessibilityIdentifier("timeTravel.transition")
        .task {
            // 1.5s rewind, then a brief beat, then 0.6s for the date to fade in.
            await runSequence()
        }
    }

    private func runSequence() async {
        // Trip the rewind animation immediately.
        rewindActive = true

        // Reduced motion: collapse to a single short beat. The full sequence
        // would feel like a stutter for users with vestibular sensitivity.
        if reduceMotion {
            try? await Task.sleep(nanoseconds: 350_000_000)
            dateRevealed = true
            try? await Task.sleep(nanoseconds: 450_000_000)
            onComplete()
            return
        }

        // Wait out the rewind animation (1.5s) then reveal the date.
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        dateRevealed = true

        // Hold the date on screen briefly before handing back.
        try? await Task.sleep(nanoseconds: 900_000_000)
        onComplete()
    }
}

// MARK: - Particle field (mirrors ChartRevealCeremony.ParticleField)

/// Lightweight star particles for the rewind overlay. A trimmed copy of
/// ChartRevealCeremony's ParticleField so we don't reach across files into
/// a `private` view. Same shape, same cost.
private struct TimeTravelParticleField: View {
    let active: Bool

    private let dots: [Dot] = {
        var rng = SystemRandomNumberGenerator()
        return (0..<24).map { _ in
            Dot(
                x: CGFloat.random(in: 0...1, using: &rng),
                y: CGFloat.random(in: 0...1, using: &rng),
                size: CGFloat.random(in: 1.0...3.0, using: &rng),
                phase: Double.random(in: 0...(.pi * 2), using: &rng)
            )
        }
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !active)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for dot in dots {
                    let alpha = 0.15 + 0.3 * (sin(t * 0.6 + dot.phase) + 1) / 2
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
    /// Presents the Time Travel rewind transition over `self` when `destination`
    /// becomes non-nil. The presenter clears `destination` after the transition
    /// completes via the supplied binding.
    ///
    /// Skipped automatically under UI tests so deterministic snapshot tests
    /// aren't blocked by the 2-second sequence.
    func timeTravelRewindTransition(
        to destination: Binding<Date?>,
        onComplete: @escaping () -> Void = {}
    ) -> some View {
        modifier(TimeTravelTransitionModifier(destination: destination, onComplete: onComplete))
    }
}

private struct TimeTravelTransitionModifier: ViewModifier {
    @Binding var destination: Date?
    let onComplete: () -> Void

    func body(content: Content) -> some View {
        content.overlay {
            if let date = destination, !TestEnvironment.shared.isUITest {
                TimeTravelTransition(destinationDate: date) {
                    destination = nil
                    onComplete()
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }
        }
    }
}
