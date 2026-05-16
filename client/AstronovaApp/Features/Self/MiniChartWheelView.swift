import SwiftUI

// MARK: - Mini Chart Wheel View
// A living, breathing birth chart avatar that represents the user's cosmic identity.
// The wheel highlights the house currently "lit" by the active Mahadasha lord —
// the centerpiece of the "houses = rooms, dashas = weather" framing.

struct MiniChartWheelView: View {
    let sunSign: String?
    let moonSign: String?
    let risingSign: String?
    let size: CGFloat

    // Active house lighting (centerpiece feature)
    let activeHouse: Int?           // 1–12, the house currently illuminated
    let mahadashaPlanet: String?    // e.g. "Saturn" — used for caption
    let houseCaption: String?       // optional override; otherwise we template one

    @State private var isBreathing = false
    @State private var wheelRotation: Double = 0
    @State private var activeHousePulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        sunSign: String? = nil,
        moonSign: String? = nil,
        risingSign: String? = nil,
        size: CGFloat = 120,
        activeHouse: Int? = nil,
        mahadashaPlanet: String? = nil,
        houseCaption: String? = nil
    ) {
        self.sunSign = sunSign
        self.moonSign = moonSign
        self.risingSign = risingSign
        self.size = size
        self.activeHouse = activeHouse
        self.mahadashaPlanet = mahadashaPlanet
        self.houseCaption = houseCaption
    }

    var body: some View {
        VStack(spacing: Cosmic.Spacing.sm) {
            wheel

            // Caption beneath the wheel narrates the lit room
            if activeHouse != nil {
                Text(resolvedCaption)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: size * 1.8)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Wheel

    private var wheel: some View {
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

            // Active house wedge — drawn behind dividers/labels so it acts like
            // a backlight illuminating the segment.
            if let house = activeHouse, (1...12).contains(house) {
                ActiveHouseWedge(house: house, size: size, pulsing: activeHousePulse)
                    .accessibilityHidden(true)
            }

            // House divisions (12 spokes)
            ForEach(0..<12, id: \.self) { index in
                Rectangle()
                    .fill(Color.cosmicTextTertiary.opacity(0.3))
                    .frame(width: 0.5, height: size * 0.15)
                    .offset(y: -size * 0.425)
                    .rotationEffect(.degrees(Double(index) * 30))
            }

            // House number labels (1–12) at each cusp midpoint. Angular houses
            // (1, 4, 7, 10) are slightly emphasised; the active house is gold.
            ForEach(1...12, id: \.self) { house in
                HouseNumberLabel(
                    house: house,
                    isAngular: [1, 4, 7, 10].contains(house),
                    isActive: house == activeHouse,
                    fontSize: size * 0.075
                )
                .offset(houseLabelOffset(for: house))
            }

            // Planet positions (simplified representation)
            if sunSign != nil || moonSign != nil || risingSign != nil {
                if sunSign != nil {
                    PlanetMarker(
                        symbol: "sun.max.fill",
                        color: .planetSun,
                        size: size * 0.12
                    )
                    .offset(x: size * 0.2, y: -size * 0.15)
                }

                if moonSign != nil {
                    PlanetMarker(
                        symbol: "moon.fill",
                        color: .planetMoon,
                        size: size * 0.1
                    )
                    .offset(x: -size * 0.18, y: size * 0.12)
                }

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

            // Active house pulse (subtle, slower than breathing glow)
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                activeHousePulse = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Layout helpers

    /// Houses are laid out counter-clockwise starting from the Ascendant on the
    /// left (9 o'clock). House 1 spans 180°–210° in screen coordinates; each
    /// subsequent house adds 30°. We place the label at the midpoint of each
    /// house's wedge, slightly inside the outer ring.
    private func houseLabelOffset(for house: Int) -> CGSize {
        let radius = size * 0.32
        let angle = houseMidpointAngle(for: house)
        return CGSize(width: radius * cos(angle), height: radius * sin(angle))
    }

    private func houseMidpointAngle(for house: Int) -> CGFloat {
        // SwiftUI angles: 0 = right (3 o'clock), increasing clockwise.
        // House 1 midpoint sits at 180° + 15° = 195° (just below the
        // ascendant point on the left). Each subsequent house is 30° counter-
        // clockwise (subtract 30°).
        let degrees = 195.0 - Double(house - 1) * 30.0
        return CGFloat(degrees * .pi / 180.0)
    }

    // MARK: - Caption

    private var resolvedCaption: String {
        if let caption = houseCaption, !caption.isEmpty { return caption }
        guard let house = activeHouse else { return "" }
        let planet = mahadashaPlanet?.capitalized ?? "Your dasha lord"
        return "\(planet) currently in your \(ordinalString(house)) house"
    }

    private func ordinalString(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)th"
    }

    private var accessibilityDescription: String {
        if let house = activeHouse, let planet = mahadashaPlanet {
            return "Your cosmic chart wheel, \(planet) lighting your \(ordinalString(house)) house"
        }
        return "Your cosmic chart wheel"
    }
}

// MARK: - Active House Wedge

/// Renders a glowing 30° wedge over the target house. Acts like a backlight
/// behind the divider spokes so the lit "room" reads at a glance.
private struct ActiveHouseWedge: View {
    let house: Int
    let size: CGFloat
    let pulsing: Bool

    var body: some View {
        let opacity = pulsing ? 0.55 : 0.35

        return WedgeShape(house: house)
            .fill(
                RadialGradient(
                    colors: [
                        Color.cosmicGold.opacity(opacity),
                        Color.cosmicGold.opacity(opacity * 0.5),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.12,
                    endRadius: size * 0.5
                )
            )
            .frame(width: size, height: size)
            .overlay(
                WedgeShape(house: house)
                    .stroke(Color.cosmicGold.opacity(0.6), lineWidth: 1)
                    .frame(width: size, height: size)
            )
            .shadow(color: .cosmicGold.opacity(0.35), radius: 6)
    }
}

private struct WedgeShape: Shape {
    let house: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        // House 1 occupies 180°…210° in screen coords (counter-clockwise from
        // the ascendant on the left). Each subsequent house rotates -30°.
        let startDegrees = 180.0 - Double(house - 1) * 30.0
        let endDegrees = startDegrees + 30.0

        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startDegrees),
            endAngle: .degrees(endDegrees),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - House Number Label

private struct HouseNumberLabel: View {
    let house: Int
    let isAngular: Bool
    let isActive: Bool
    let fontSize: CGFloat

    var body: some View {
        Text("\(house)")
            .font(.system(size: fontSize, weight: isActive ? .bold : (isAngular ? .semibold : .regular), design: .rounded))
            .foregroundStyle(
                isActive
                    ? Color.cosmicGold
                    : (isAngular ? Color.cosmicTextPrimary.opacity(0.7) : Color.cosmicTextTertiary)
            )
            .shadow(
                color: isActive ? Color.cosmicGold.opacity(0.7) : .clear,
                radius: isActive ? 3 : 0
            )
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

// MARK: - Helpers

extension MiniChartWheelView {
    /// Compute the house currently lit by the active Mahadasha lord, given a
    /// planet→house natal map. Returns nil when either input is missing or the
    /// planet isn't present in the map (e.g. backend hasn't shipped the
    /// natal_snapshot field yet).
    static func activeHouse(for planet: String?, in planetHouseMap: [String: Int]) -> Int? {
        guard let planet = planet, !planet.isEmpty else { return nil }
        // Match case-insensitively to be robust against backend casing variants.
        let needle = planet.lowercased()
        for (name, house) in planetHouseMap where name.lowercased() == needle {
            return house
        }
        return nil
    }

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

#Preview("Active house lit (Saturn → 10th)") {
    ZStack {
        Color.cosmicVoid.ignoresSafeArea()

        VStack(spacing: 32) {
            MiniChartWheelView(
                sunSign: "Leo",
                moonSign: "Cancer",
                risingSign: "Libra",
                size: 160,
                activeHouse: 10,
                mahadashaPlanet: "Saturn",
                houseCaption: "Saturn currently in your 10th house — career under reconstruction"
            )

            MiniChartWheelView(
                sunSign: "Leo",
                moonSign: "Cancer",
                risingSign: "Libra",
                size: 140,
                activeHouse: 4,
                mahadashaPlanet: "Moon"
            )
        }
    }
}

#Preview("Decoration only (no active house)") {
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
