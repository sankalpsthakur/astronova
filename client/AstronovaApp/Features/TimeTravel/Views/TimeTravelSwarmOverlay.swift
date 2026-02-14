import SwiftUI

/// A lightweight "visual swarm" overlay to make scrubbing feel alive.
/// This is intentionally non-interactive and pure decoration, so it never blocks map taps.
struct TimeTravelSwarmOverlay: View {
    enum Mode {
        case idle
        case scrubbing
        case loading
    }

    let mode: Mode
    let tone: ScrubInsight.Tone?
    let scrubMotion: TimeTravelScrubMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let motion = scrubMotion
                let direction = (motion.isScrubbing && mode != .idle)
                    ? (motion.direction == 0 ? 0.0001 : motion.direction)
                    : 0
                let isMoving = motion.isScrubbing && motion.speed > 0.01
                let rawSpeed = isMoving ? min(1, max(0.05, motion.speed)) : 0
                let intensity = isMoving ? rawSpeed : (mode == .loading ? 0.55 : 0.1)
                let modeBoost = motionBoost(for: mode)

                let baseCount: Int = mode == .idle ? 20 : 36
                let count: Int = mode == .loading ? 52 : baseCount
                let phaseShift = Double(direction) * t * (0.8 + intensity * 0.9) * modeBoost

                let color = swarmColor(tone: tone)
                let opacity = swarmOpacity
                let speedBase = mode == .loading ? 2.85 : (mode == .scrubbing ? 1.95 : 0.85)

                let atmosphereRadius = min(size.width, size.height) * 0.18
                let pulse = 0.9 + 0.14 * sin(t * 1.2 + Double(modeBoost))
                let orbitBias = Double(direction) * (0.012 * Double(size.width) + 0.006 * Double(size.height))

                // Soft orbital wash.
                let ambientRadius = atmosphereRadius * pulse
                for ring in 0..<3 {
                    let ringR = ambientRadius * (1.0 + Double(ring) * 0.34)
                    let ringAlpha = opacity * 0.18 * (1.0 - Double(ring) * 0.25)
                    let ringPath = Path(ellipseIn: CGRect(
                        x: center.x - ringR,
                        y: center.y - ringR,
                        width: ringR * 2,
                        height: ringR * 2
                    ))
                    context.stroke(
                        ringPath,
                        with: .color(color.opacity(ringAlpha)),
                        style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [4, 10], dashPhase: t * 30 * direction)
                    )
                }

                // Ambient core pulse.
                let core = Path(ellipseIn: CGRect(
                    x: center.x - atmosphereRadius * 0.45 * CGFloat(pulse),
                    y: center.y - atmosphereRadius * 0.45 * CGFloat(pulse),
                    width: atmosphereRadius * 0.9 * CGFloat(pulse),
                    height: atmosphereRadius * 0.9 * CGFloat(pulse)
                ))
                context.fill(core, with: .color(color.opacity(0.06 * opacity)))

                for i in 0..<count {
                    let seed = Double(i) * 0.37
                    let orbit = (min(size.width, size.height) * 0.44) * (0.24 + 0.76 * Double(i % 9) / 8.0)
                    let motionLayer = (i % 3)
                    let layerSpeed = modeBoost * (1 + CGFloat(motionLayer) * 0.28)
                    let speed = speedBase + Double(i % 6) * 0.06 + Double(intensity) * 1.25 * layerSpeed
                    let directionalBias = direction * orbit * (0.012 + 0.05 * Double(intensity))

                    let wobble = sin(t * (1.15 + 0.22 * Double(motionLayer)) + seed) *
                    (5 + (6 * Double(intensity) * modeBoost))
                    let breathing = 0.68 + 0.24 * sin(t * 1.5 + seed * 5 + Double(direction))
                    let modeOffset: Double = switch mode {
                    case .idle: 0.35
                    case .scrubbing: 1.1
                    case .loading: 1.95
                    }
                    let angle = t * speed + seed * 9 + phaseShift + modeOffset
                    let radial = 1.0 + 0.07 * sin(t * 1.4 + seed) + 0.02 * Double(modeLayerIntensity(mode: mode, layer: motionLayer))

                    let orbitRadius = CGFloat(orbit * Double(radial))
                    let x = center.x + CGFloat(cos(angle)) * orbitRadius + CGFloat(directionalBias) + CGFloat(orbitBias * 0.6 * (1 + Double(motionLayer)))
                    let y = center.y + CGFloat(sin(angle * 0.92)) * orbitRadius - CGFloat(directionalBias) +
                        CGFloat(wobble * 0.55)

                    let sizeJitter = 1.0 + 0.45 * sin(t * 2.1 + seed * 11)
                    let r: CGFloat = (mode == .loading ? 2.5 : 1.85) * CGFloat(sizeJitter) * (1 + CGFloat(motionLayer) * 0.22)

                    let glow = Path(ellipseIn: CGRect(x: x - r * 2, y: y - r * 2, width: r * 4, height: r * 4))
                    context.fill(
                        glow,
                        with: .color(color.opacity(0.10 * opacity * Double(breathing)))
                    )

                    let dot = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                    context.fill(
                        dot,
                        with: .color(color.opacity(0.34 * opacity * Double(breathing)))
                    )

                    // Light trailing motion while scrubbing for perceived velocity feedback.
                    if isMoving {
                        let trailLength = 8 + 18 * CGFloat(intensity) + CGFloat(motionLayer) * 3
                        let vx = CGFloat(cos(angle))
                        let vy = CGFloat(sin(angle))
                        let trailStart = CGPoint(x: x - vx * trailLength, y: y - vy * trailLength)
                        let trailPath = Path { path in
                            path.move(to: trailStart)
                            path.addLine(to: CGPoint(x: x + vx * 3, y: y + vy * 3))
                        }
                        context.stroke(
                            trailPath,
                            with: .color(color.opacity(0.12 * opacity * Double(breathing))),
                            style: StrokeStyle(lineWidth: 1.0 + Double(motionLayer) * 0.6, lineCap: .round)
                        )
                    }

                    // Scrub burst accents for momentum spikes.
                    if isMoving && mode == .loading && i % 7 == 0 {
                        let burst = CGPoint(
                            x: center.x + CGFloat(cos(t * 1.7 + seed)) * atmosphereRadius * 0.6,
                            y: center.y + CGFloat(sin(t * 1.7 + seed)) * atmosphereRadius * 0.6
                        )
                        let burstRadius = CGFloat(1.4 + 1.2 * sin(t * 4 + seed).magnitude) * (1 + CGFloat(motionLayer) * 0.1)
                        let burstNode = Path(ellipseIn: CGRect(
                            x: burst.x - burstRadius,
                            y: burst.y - burstRadius,
                            width: burstRadius * 2,
                            height: burstRadius * 2
                        ))
                        context.fill(
                            burstNode,
                            with: .color(color.opacity(0.22 * opacity * Double(modeBoost)))
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .blendMode(.plusLighter)
    }

    private var swarmOpacity: Double {
        switch mode {
        case .idle: return 0.45
        case .scrubbing: return 0.75
        case .loading: return 0.85
        }
    }

    private func motionBoost(for mode: Mode) -> Double {
        switch mode {
        case .idle: return 0.55
        case .scrubbing: return 1.0
        case .loading: return 1.25
        }
    }

    private func modeLayerIntensity(mode: Mode, layer: Int) -> Double {
        let base = [0.0, 0.45, 0.75]
        let layerGain = base[min(base.count - 1, max(0, layer))]
        switch mode {
        case .idle: return layerGain * 0.4
        case .scrubbing: return layerGain
        case .loading: return layerGain * 1.25
        }
    }

    private func swarmColor(tone: ScrubInsight.Tone?) -> Color {
        switch tone ?? .neutral {
        case .supportive: return .cosmicSuccess
        case .challenging: return .cosmicError
        case .review: return .cosmicWarning
        case .neutral: return .cosmicGold
        }
    }
}
