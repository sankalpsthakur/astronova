import SwiftUI

/// Hero visualization showing current cosmic energy state
/// - Outer ring: planetary activations
/// - Middle ring: domain weights (self/love/work/mind)
/// - Inner pulse: energy state indicator
struct CosmicLensView: View {
    let lens: CosmicLens
    let onDomainTap: ((String) -> Void)?

    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    @State private var selectedDomain: String?

    private let size: CGFloat = 220

    init(lens: CosmicLens, onDomainTap: ((String) -> Void)? = nil) {
        self.lens = lens
        self.onDomainTap = onDomainTap
    }

    var body: some View {
        ZStack {
            // Outer ring: planetary activations
            outerRing

            // Middle ring: domain arcs
            domainArcs

            // Inner pulse: energy state
            innerPulse

            // Center label
            centerLabel
        }
        .frame(width: size, height: size)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Outer Ring (Planetary Activations)

    private var outerRing: some View {
        ZStack {
            // Base ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.cosmicGold.opacity(0.1), Color.cosmicGold.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
                .frame(width: size, height: size)

            // Planetary markers
            if let activations = lens.activations {
                ForEach(Array(activations.enumerated()), id: \.offset) { index, activation in
                    planetaryMarker(for: activation, at: index, total: activations.count)
                }
            }
        }
        .rotationEffect(.degrees(rotationAngle))
    }

    private func planetaryMarker(for activation: PlanetActivation, at index: Int, total: Int) -> some View {
        let angle = (Double(index) / Double(total)) * 360 - 90
        let radius = size / 2 - 8

        return ZStack {
            Circle()
                .fill(planetColor(for: activation.planet))
                .frame(width: 12, height: 12)
                .shadow(color: planetColor(for: activation.planet).opacity(0.5), radius: 4)

            Text(planetSymbol(for: activation.planet))
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
        }
        .offset(
            x: cos(angle * .pi / 180) * radius,
            y: sin(angle * .pi / 180) * radius
        )
    }

    // MARK: - Middle Ring (Domain Arcs)

    private var domainArcs: some View {
        let domains: [(String, Double, Color)] = [
            ("self", lens.domainWeights.`self`, Color.cosmicGold),
            ("love", lens.domainWeights.love, Color.planetVenus),
            ("work", lens.domainWeights.work, Color.planetSaturn),
            ("mind", lens.domainWeights.mind, Color.planetMercury)
        ]

        var startAngle: Double = -90

        return ZStack {
            ForEach(domains, id: \.0) { domain, weight, color in
                let sweepAngle = weight * 360

                DomainArc(
                    startAngle: startAngle,
                    endAngle: startAngle + sweepAngle,
                    color: color,
                    isSelected: selectedDomain == domain,
                    label: domain
                )
                .frame(width: size - 40, height: size - 40)
                .onTapGesture {
                    CosmicHaptics.light()
                    withAnimation(.spring(response: 0.3)) {
                        selectedDomain = selectedDomain == domain ? nil : domain
                    }
                    onDomainTap?(domain)
                }
                .onAppear {
                    startAngle += sweepAngle
                }
            }
        }
    }

    // MARK: - Inner Pulse (Energy State)

    private var innerPulse: some View {
        ZStack {
            // Glow background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [energyColor.opacity(0.3), energyColor.opacity(0)],
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(pulseScale)

            // Inner circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [energyColor.opacity(0.8), energyColor.opacity(0.4)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(energyColor, lineWidth: 2)
                )
                .shadow(color: energyColor.opacity(0.5), radius: 8)

            // Energy icon
            Image(systemName: lens.energyState.icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 2)
        }
    }

    private var centerLabel: some View {
        VStack(spacing: 2) {
            Spacer()
            Text(lens.energyState.label)
                .font(.cosmicCaption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.cosmicTextPrimary)

            Text("frequency")
                .font(.system(size: 9))
                .foregroundStyle(Color.cosmicTextSecondary)
        }
        .frame(height: size)
        .padding(.bottom, 16)
    }

    // MARK: - Helpers

    private var energyColor: Color {
        switch lens.energyState.id {
        case "flowing": return .green
        case "intense": return .orange
        case "quiet": return .indigo
        case "volatile": return .red
        default: return .cosmicGold
        }
    }

    private func planetColor(for planet: String) -> Color {
        switch planet.lowercased() {
        case "sun": return .planetSun
        case "moon": return .planetMoon
        case "mercury": return .planetMercury
        case "venus": return .planetVenus
        case "mars": return .planetMars
        case "jupiter": return .planetJupiter
        case "saturn": return .planetSaturn
        default: return .cosmicGold
        }
    }

    private func planetSymbol(for planet: String) -> String {
        switch planet.lowercased() {
        case "sun": return "☉"
        case "moon": return "☽"
        case "mercury": return "☿"
        case "venus": return "♀"
        case "mars": return "♂"
        case "jupiter": return "♃"
        case "saturn": return "♄"
        default: return "★"
        }
    }

    private func startAnimations() {
        // Pulse animation based on energy state
        let duration: Double = {
            switch lens.energyState.id {
            case "flowing": return 3.0
            case "intense": return 1.5
            case "quiet": return 4.0
            case "volatile": return 1.0
            default: return 2.5
            }
        }()

        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }

        // Slow rotation for outer ring
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}

// MARK: - Domain Arc Shape

private struct DomainArc: View {
    let startAngle: Double
    let endAngle: Double
    let color: Color
    let isSelected: Bool
    let label: String

    var body: some View {
        ZStack {
            // Arc path
            ArcShape(startAngle: startAngle, endAngle: endAngle)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: isSelected ? 16 : 12, lineCap: .round)
                )
                .opacity(isSelected ? 1.0 : 0.6)

            // Label at midpoint
            let midAngle = (startAngle + endAngle) / 2
            let labelRadius: CGFloat = 70

            Text(domainIcon)
                .font(.system(size: isSelected ? 14 : 11))
                .foregroundStyle(isSelected ? color : Color.cosmicTextSecondary)
                .offset(
                    x: cos(midAngle * .pi / 180) * labelRadius,
                    y: sin(midAngle * .pi / 180) * labelRadius
                )
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }

    private var domainIcon: String {
        switch label {
        case "self": return "✦"
        case "love": return "♡"
        case "work": return "◆"
        case "mind": return "◎"
        default: return "●"
        }
    }
}

private struct ArcShape: Shape {
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )

        return path
    }
}

// MARK: - Preview

#Preview {
    VStack {
        CosmicLensView(
            lens: CosmicLens(
                energyState: EnergyState(
                    id: "flowing",
                    label: "Flowing",
                    description: "Smooth progress, natural ease",
                    icon: "wind"
                ),
                domainWeights: DomainWeights(
                    self: 0.3,
                    love: 0.25,
                    work: 0.25,
                    mind: 0.2
                ),
                activations: [
                    PlanetActivation(type: "transit", planet: "sun", sign: "capricorn", speed: 1.0),
                    PlanetActivation(type: "transit", planet: "moon", sign: "aries", speed: 12.0),
                    PlanetActivation(type: "transit", planet: "venus", sign: "aquarius", speed: 1.2),
                    PlanetActivation(type: "transit", planet: "mars", sign: "leo", speed: 0.7),
                    PlanetActivation(type: "transit", planet: "mercury", sign: "capricorn", speed: 1.5)
                ]
            )
        ) { domain in
            #if DEBUG
            debugPrint("[CosmicLensView] Tapped domain: \(domain)")
            #endif
        }
        .padding()
        .background(Color.cosmicBackground)
    }
}
