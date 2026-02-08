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

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)

                let baseCount: Int = (mode == .idle) ? 18 : 32
                let count: Int = (mode == .loading) ? 40 : baseCount

                let color = swarmColor(tone: tone)
                let opacity = swarmOpacity

                for i in 0..<count {
                    let seed = Double(i) * 0.37
                    let orbit = (min(size.width, size.height) * 0.42) * (0.25 + 0.75 * Double(i % 9) / 8.0)
                    let speed = (mode == .scrubbing ? 1.8 : 0.8) + Double(i % 5) * 0.05
                    let wobble = sin(t * 1.2 + seed) * 8

                    let angle = t * speed + seed * 9
                    let x = center.x + CGFloat(cos(angle)) * CGFloat(orbit) + CGFloat(wobble)
                    let y = center.y + CGFloat(sin(angle * 0.9)) * CGFloat(orbit) + CGFloat(wobble * 0.6)

                    let sizeJitter = 1.0 + 0.6 * sin(t * 2.0 + seed * 11)
                    let r: CGFloat = (mode == .loading ? 2.4 : 1.8) * CGFloat(sizeJitter)

                    let glow = Path(ellipseIn: CGRect(x: x - r * 2, y: y - r * 2, width: r * 4, height: r * 4))
                    context.fill(glow, with: .color(color.opacity(0.10 * opacity)))

                    let dot = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                    context.fill(dot, with: .color(color.opacity(0.35 * opacity)))
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

    private func swarmColor(tone: ScrubInsight.Tone?) -> Color {
        switch tone ?? .neutral {
        case .supportive: return .cosmicSuccess
        case .challenging: return .cosmicError
        case .review: return .cosmicWarning
        case .neutral: return .cosmicGold
        }
    }
}

