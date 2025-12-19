import SwiftUI

// MARK: - Mini Chart Wheel View
// A living, breathing birth chart avatar that represents the user's cosmic identity

struct MiniChartWheelView: View {
    let sunSign: String?
    let moonSign: String?
    let risingSign: String?
    let size: CGFloat

    @State private var isBreathing = false
    @State private var wheelRotation: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(sunSign: String? = nil, moonSign: String? = nil, risingSign: String? = nil, size: CGFloat = 120) {
        self.sunSign = sunSign
        self.moonSign = moonSign
        self.risingSign = risingSign
        self.size = size
    }

    var body: some View {
        ZStack {
            // Outer glow - breathing effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.cosmicGold.opacity(isBreathing ? 0.4 : 0.2),
                            Color.cosmicAmethyst.opacity(isBreathing ? 0.2 : 0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.4,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size * 1.4, height: size * 1.4)

            // Zodiac wheel background
            Circle()
                .fill(Color.cosmicNebula)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(
                            AngularGradient.cosmicZodiacWheel,
                            lineWidth: size * 0.08
                        )
                        .rotationEffect(.degrees(wheelRotation))
                )
                .overlay(
                    Circle()
                        .stroke(Color.cosmicGold.opacity(0.3), lineWidth: 1)
                )

            // Inner circle - soul essence
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.cosmicStardust,
                            Color.cosmicNebula
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.35
                    )
                )
                .frame(width: size * 0.7, height: size * 0.7)
                .overlay(
                    Circle()
                        .stroke(Color.cosmicGold.opacity(0.2), lineWidth: 0.5)
                )

            // House divisions
            ForEach(0..<12, id: \.self) { index in
                Rectangle()
                    .fill(Color.cosmicTextTertiary.opacity(0.3))
                    .frame(width: 0.5, height: size * 0.15)
                    .offset(y: -size * 0.425)
                    .rotationEffect(.degrees(Double(index) * 30))
            }

            // Planet positions (simplified representation)
            if sunSign != nil || moonSign != nil || risingSign != nil {
                // Sun position
                if sunSign != nil {
                    PlanetMarker(
                        symbol: "sun.max.fill",
                        color: .planetSun,
                        size: size * 0.12
                    )
                    .offset(x: size * 0.2, y: -size * 0.15)
                }

                // Moon position
                if moonSign != nil {
                    PlanetMarker(
                        symbol: "moon.fill",
                        color: .planetMoon,
                        size: size * 0.1
                    )
                    .offset(x: -size * 0.18, y: size * 0.12)
                }

                // Ascendant marker
                if risingSign != nil {
                    AscendantMarker(size: size * 0.08)
                        .offset(x: size * 0.35, y: 0)
                }
            }

            // Center point - cosmic essence
            Circle()
                .fill(Color.cosmicGold)
                .frame(width: size * 0.06, height: size * 0.06)
                .shadow(color: .cosmicGold.opacity(0.5), radius: 4)
        }
        .frame(width: size * 1.4, height: size * 1.4)
        .onAppear {
            guard !reduceMotion else { return }

            // Breathing glow
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                isBreathing = true
            }

            // Slow wheel rotation
            withAnimation(.linear(duration: 120).repeatForever(autoreverses: false)) {
                wheelRotation = 360
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your cosmic chart wheel")
    }
}

// MARK: - Planet Marker

private struct PlanetMarker: View {
    let symbol: String
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.cosmicVoid.opacity(0.8))
                .frame(width: size * 1.5, height: size * 1.5)

            Image(systemName: symbol)
                .font(.system(size: size))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.5), radius: 2)
        }
    }
}

// MARK: - Ascendant Marker

private struct AscendantMarker: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Arrow pointing right (East/Ascendant)
            Image(systemName: "arrowtriangle.right.fill")
                .font(.system(size: size))
                .foregroundStyle(Color.cosmicGold)
                .shadow(color: .cosmicGold.opacity(0.5), radius: 2)
        }
    }
}

// MARK: - Zodiac Symbol Helper

extension MiniChartWheelView {
    static func zodiacSymbol(for sign: String) -> String {
        switch sign.lowercased() {
        case "aries": return "♈"
        case "taurus": return "♉"
        case "gemini": return "♊"
        case "cancer": return "♋"
        case "leo": return "♌"
        case "virgo": return "♍"
        case "libra": return "♎"
        case "scorpio": return "♏"
        case "sagittarius": return "♐"
        case "capricorn": return "♑"
        case "aquarius": return "♒"
        case "pisces": return "♓"
        default: return "✧"
        }
    }

    static func zodiacColor(for sign: String) -> Color {
        switch sign.lowercased() {
        case "aries": return .zodiacAries
        case "taurus": return .zodiacTaurus
        case "gemini": return .zodiacGemini
        case "cancer": return .zodiacCancer
        case "leo": return .zodiacLeo
        case "virgo": return .zodiacVirgo
        case "libra": return .zodiacLibra
        case "scorpio": return .zodiacScorpio
        case "sagittarius": return .zodiacSagittarius
        case "capricorn": return .zodiacCapricorn
        case "aquarius": return .zodiacAquarius
        case "pisces": return .zodiacPisces
        default: return .cosmicGold
        }
    }
}

// MARK: - Preview

#Preview("Mini Chart Wheel") {
    ZStack {
        Color.cosmicVoid.ignoresSafeArea()

        VStack(spacing: 40) {
            MiniChartWheelView(
                sunSign: "Leo",
                moonSign: "Cancer",
                risingSign: "Libra",
                size: 140
            )

            MiniChartWheelView(
                sunSign: nil,
                moonSign: nil,
                risingSign: nil,
                size: 100
            )
        }
    }
}
