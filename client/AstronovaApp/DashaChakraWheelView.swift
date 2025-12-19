import SwiftUI

/// Interactive Chakra Wheel for Vimshottari Dasha visualization
/// Shows Mahadasha → Antardasha → Pratyantardasha in concentric rings with smooth animations
struct DashaChakraWheelView: View {
    let dashaData: DashaCompleteResponse
    let onPeriodTap: ((DashaPeriod) -> Void)?

    @State private var selectedSegment: DashaPeriod?
    @State private var hoveredSegment: DashaPeriod?
    @State private var animationProgress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // Planet colors matching the design
    private let planetColors: [String: Color] = [
        "Sun": .yellow,
        "Moon": .cyan,
        "Mars": .red,
        "Mercury": .green,
        "Jupiter": .orange,
        "Venus": .pink,
        "Saturn": .brown,
        "Rahu": .purple,
        "Ketu": .indigo,
    ]

    private let lords = ["Ketu", "Venus", "Sun", "Moon", "Mars", "Rahu", "Jupiter", "Saturn", "Mercury"]

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                // Background cosmic gradient
                RadialGradient(
                    colors: [Color.black.opacity(0.95), Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )

                // Mahadasha ring (outer)
                MahadashaRing(
                    center: center,
                    outerRadius: size * 0.45,
                    innerRadius: size * 0.35,
                    dashaData: dashaData,
                    lords: lords,
                    colors: planetColors,
                    animationProgress: animationProgress,
                    onTap: { period in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedSegment = period
                        }
                        onPeriodTap?(period)
                    }
                )

                // Antardasha ring (middle)
                AntardashaRing(
                    center: center,
                    outerRadius: size * 0.34,
                    innerRadius: size * 0.24,
                    dashaData: dashaData,
                    lords: lords,
                    colors: planetColors,
                    animationProgress: animationProgress,
                    onTap: { period in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedSegment = period
                        }
                        onPeriodTap?(period)
                    }
                )

                // Pratyantardasha ring (inner)
                PratyantardashaRing(
                    center: center,
                    outerRadius: size * 0.23,
                    innerRadius: size * 0.13,
                    dashaData: dashaData,
                    lords: lords,
                    colors: planetColors,
                    animationProgress: animationProgress,
                    onTap: { period in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedSegment = period
                        }
                        onPeriodTap?(period)
                    }
                )

                // Center label - current dasha
                VStack(spacing: 4) {
                    Text(dashaData.currentPeriod.mahadasha.lord)
                        .font(.system(size: size * 0.055, weight: .bold))
                        .foregroundStyle(planetColors[dashaData.currentPeriod.mahadasha.lord] ?? .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let antar = dashaData.currentPeriod.antardasha {
                        Text(antar.lord)
                            .font(.system(size: size * 0.035, weight: .medium))
                            .foregroundStyle(planetColors[antar.lord]?.opacity(0.8) ?? .white.opacity(0.8))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    Text("Now")
                        .font(.system(size: size * 0.025, weight: .light))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: size * 0.22)

                // Active period indicator (pulsating glow)
                let mahaLord = dashaData.currentPeriod.mahadasha.lord
                ActivePeriodIndicator(
                    center: center,
                    radius: size * 0.40,
                    lord: mahaLord,
                    color: planetColors[mahaLord] ?? .white,
                    animationProgress: animationProgress
                )
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.6)) {
                    animationProgress = 1.0
                }
            } else {
                animationProgress = 1.0
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Dasha Chakra Wheel showing current \(dashaData.currentPeriod.mahadasha.lord) Mahadasha")
    }
}

// MARK: - Mahadasha Ring

struct MahadashaRing: View {
    let center: CGPoint
    let outerRadius: CGFloat
    let innerRadius: CGFloat
    let dashaData: DashaCompleteResponse
    let lords: [String]
    let colors: [String: Color]
    let animationProgress: CGFloat
    let onTap: (DashaPeriod) -> Void

    var body: some View {
        Canvas { context, size in
            let currentLord = dashaData.currentPeriod.mahadasha.lord
            _ = lords.firstIndex(of: currentLord) ?? 0

            for (index, lord) in lords.enumerated() {
                let startAngle = Angle(degrees: Double(index) * 40.0 - 90)
                let endAngle = Angle(degrees: Double(index + 1) * 40.0 - 90)

                let isCurrent = lord == currentLord
                let opacity = isCurrent ? 1.0 : 0.4
                let lineWidth = isCurrent ? outerRadius - innerRadius + 8 : outerRadius - innerRadius

                var path = Path()
                path.addArc(
                    center: center,
                    radius: (outerRadius + innerRadius) / 2,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )

                let color = colors[lord] ?? .white
                context.stroke(
                    path,
                    with: .color(color.opacity(opacity * animationProgress)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

                // Add glow effect for current period
                if isCurrent {
                    context.stroke(
                        path,
                        with: .color(color.opacity(0.3 * animationProgress)),
                        style: StrokeStyle(lineWidth: lineWidth + 4, lineCap: .round)
                    )
                }

                // Label - use 4 characters for better readability
                let midAngle = (startAngle.radians + endAngle.radians) / 2
                let labelRadius = outerRadius + 20
                let labelPos = CGPoint(
                    x: center.x + labelRadius * cos(midAngle),
                    y: center.y + labelRadius * sin(midAngle)
                )

                let label = Text(String(lord.prefix(4)))
                    .font(.system(size: isCurrent ? 12 : 9, weight: isCurrent ? .bold : .medium))
                    .foregroundStyle(color.opacity(opacity * animationProgress))

                context.draw(label, at: labelPos, anchor: .center)
            }
        }
    }
}

// MARK: - Antardasha Ring

struct AntardashaRing: View {
    let center: CGPoint
    let outerRadius: CGFloat
    let innerRadius: CGFloat
    let dashaData: DashaCompleteResponse
    let lords: [String]
    let colors: [String: Color]
    let animationProgress: CGFloat
    let onTap: (DashaPeriod) -> Void

    var body: some View {
        Canvas { context, size in
            guard let allAntardashas = dashaData.dasha.allAntardashas, !allAntardashas.isEmpty else { return }

            let currentAntarLord = dashaData.currentPeriod.antardasha?.lord

            // Calculate angular spans for each antardasha proportionally
            let totalMonths = allAntardashas.reduce(0.0) { sum, antar in
                sum + (antar.durationMonths ?? 1.0)
            }

            var cumulativeAngle = -90.0 // Start at top

            for antar in allAntardashas {
                let months = antar.durationMonths ?? 1.0
                let span = (months / totalMonths) * 360.0

                let startAngle = Angle(degrees: cumulativeAngle)
                let endAngle = Angle(degrees: cumulativeAngle + span)

                let isCurrent = antar.lord == currentAntarLord
                let opacity = isCurrent ? 1.0 : 0.3
                let lineWidth = isCurrent ? outerRadius - innerRadius + 4 : outerRadius - innerRadius - 2

                var path = Path()
                path.addArc(
                    center: center,
                    radius: (outerRadius + innerRadius) / 2,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )

                let color = colors[antar.lord] ?? .white
                context.stroke(
                    path,
                    with: .color(color.opacity(opacity * animationProgress)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                )

                // Subtle glow for current
                if isCurrent {
                    context.stroke(
                        path,
                        with: .color(color.opacity(0.4 * animationProgress)),
                        style: StrokeStyle(lineWidth: lineWidth + 3, lineCap: .butt)
                    )
                }

                cumulativeAngle += span
            }
        }
    }
}

// MARK: - Pratyantardasha Ring

struct PratyantardashaRing: View {
    let center: CGPoint
    let outerRadius: CGFloat
    let innerRadius: CGFloat
    let dashaData: DashaCompleteResponse
    let lords: [String]
    let colors: [String: Color]
    let animationProgress: CGFloat
    let onTap: (DashaPeriod) -> Void

    var body: some View {
        Canvas { context, size in
            guard let allPratyantar = dashaData.dasha.allPratyantardashas, !allPratyantar.isEmpty else { return }

            let currentPratyantarLord = dashaData.currentPeriod.pratyantardasha?.lord

            // Calculate angular spans proportionally
            let totalDays = allPratyantar.reduce(0.0) { sum, pratyantar in
                sum + (pratyantar.durationDays ?? 1.0)
            }

            var cumulativeAngle = -90.0

            for pratyantar in allPratyantar {
                let days = pratyantar.durationDays ?? 1.0
                let span = (days / totalDays) * 360.0

                let startAngle = Angle(degrees: cumulativeAngle)
                let endAngle = Angle(degrees: cumulativeAngle + span)

                let isCurrent = pratyantar.lord == currentPratyantarLord
                let opacity = isCurrent ? 1.0 : 0.25
                let lineWidth = isCurrent ? outerRadius - innerRadius + 2 : outerRadius - innerRadius - 4

                var path = Path()
                path.addArc(
                    center: center,
                    radius: (outerRadius + innerRadius) / 2,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )

                let color = colors[pratyantar.lord] ?? .white
                context.stroke(
                    path,
                    with: .color(color.opacity(opacity * animationProgress)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                )

                cumulativeAngle += span
            }
        }
    }
}

// MARK: - Active Period Indicator

struct ActivePeriodIndicator: View {
    let center: CGPoint
    let radius: CGFloat
    let lord: String
    let color: Color
    let animationProgress: CGFloat

    @State private var pulsePhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.02)
            .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
            .frame(width: radius * 2, height: radius * 2)
            .rotationEffect(.degrees(-90))
            .position(center)
            .opacity(animationProgress)
            .shadow(color: color.opacity(pulsePhase), radius: 20)
            .onAppear {
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulsePhase = 0.8
                    }
                }
            }
    }
}

// MARK: - Supporting Models

struct DashaPeriod: Identifiable, Equatable {
    let id = UUID()
    let lord: String
    let level: DashaLevel
    let start: String
    let end: String

    enum DashaLevel: String {
        case mahadasha, antardasha, pratyantardasha

        var displayName: String {
            switch self {
            case .mahadasha: return "Mahadasha"
            case .antardasha: return "Antardasha"
            case .pratyantardasha: return "Pratyantardasha"
            }
        }
    }
}
