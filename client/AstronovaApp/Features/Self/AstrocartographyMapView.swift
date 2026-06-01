import MapKit
import SwiftUI

// MARK: - Astrocartography Data Models

/// Relocation astrology data for a single city —
/// showing how the user's chart changes when they relocate.
struct CityRelocation: Identifiable {
    let id = UUID()
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double
    let ascendantSign: String       // "♐ Sagittarius"
    let ascendantLord: String       // "Jupiter"
    let score: Double               // 0.0 – 1.0
    let deltaAsc: String            // "+ Jupiter"
    let deltaMc: String             // "+ public"
    let blemish: String             // "excess heat"
    let description: String
    let bestFor: [String]
    let rank: Int

    /// Normalized position for map rendering (0–1 range).
    /// Derived from the mockup's 480×300 SVG viewBox.
    let mapX: Double
    let mapY: Double
}

/// A planetary influence line crossing the world map.
struct PlanetaryLine: Identifiable {
    let id = UUID()
    let planet: String
    let lineType: String  // "MC", "AS", "IC", "DS"
    let colorHex: String
    let interpretation: String

    /// SVG path data in the 480×300 coordinate space.
    let svgPath: String
}

/// Full astrocartography dataset for the interactive map.
struct AstrocartographyData {
    let cities: [CityRelocation]
    let planetaryLines: [PlanetaryLine]
    let topRecommendation: String
}

// MARK: - Sample Data

extension AstrocartographyData {

    /// Realistic sample used for previews and development.
    static let sample = AstrocartographyData(
        cities: [
            CityRelocation(
                name: "Dubai",
                country: "UAE",
                latitude: 25.2048,
                longitude: 55.2708,
                ascendantSign: "♐ Sagittarius",
                ascendantLord: "Jupiter",
                score: 0.91,
                deltaAsc: "+ Jupiter",
                deltaMc: "+ public",
                blemish: "excess heat",
                description: "Sovereign-Creator amplified. New ascendant runs Jupiter as 1L — what's already your strength gets the room to scale. MC lights up public visibility with a benefic that's comfortable in fire.",
                bestFor: ["Public speaking", "Empire building", "International trade"],
                rank: 1,
                mapX: 248, mapY: 158
            ),
            CityRelocation(
                name: "Singapore",
                country: "Singapore",
                latitude: 1.3521,
                longitude: 103.8198,
                ascendantSign: "♑ Capricorn",
                ascendantLord: "Saturn",
                score: 0.82,
                deltaAsc: "+ Saturn",
                deltaMc: "+ structure",
                blemish: "rigidity risk",
                description: "Capital · stable. Saturn in the 10th gives methodical ambition. The discipline you already have becomes institutional — good for long-term wealth building, less so for spontaneity.",
                bestFor: ["Wealth accumulation", "Corporate career", "Long-term planning"],
                rank: 2,
                mapX: 332, mapY: 192
            ),
            CityRelocation(
                name: "Bengaluru",
                country: "India",
                latitude: 12.9716,
                longitude: 77.5946,
                ascendantSign: "♏ Scorpio",
                ascendantLord: "Mars",
                score: 0.74,
                deltaAsc: "+ Mars",
                deltaMc: "baseline",
                blemish: "intensity",
                description: "Native · self. Your birth chart baseline. Mars-ruled ascendant gives drive and resilience — but without the benefic amplification that relocation offers. Home court advantage, not a power-up.",
                bestFor: ["Rooted work", "Family life", "Familiar networks"],
                rank: 3,
                mapX: 296, mapY: 178
            ),
            CityRelocation(
                name: "London",
                country: "United Kingdom",
                latitude: 51.5074,
                longitude: -0.1278,
                ascendantSign: "♌ Leo",
                ascendantLord: "Sun",
                score: 0.51,
                deltaAsc: "+ Sun",
                deltaMc: "−22% peace",
                blemish: "ego cost",
                description: "Spotlight · ego cost. Sun in the 9th brings recognition and academic prestige, but the fire-on-fire stacking drains personal peace. Good for a career phase, hard as a permanent home.",
                bestFor: ["Academia", "Performing arts", "Short-term fame"],
                rank: 4,
                mapX: 200, mapY: 122
            ),
            CityRelocation(
                name: "New York",
                country: "United States",
                latitude: 40.7128,
                longitude: -74.0060,
                ascendantSign: "♋ Cancer",
                ascendantLord: "Moon",
                score: 0.46,
                deltaAsc: "+ Moon",
                deltaMc: "soft",
                blemish: "emotional drain",
                description: "Home → care · soft. Moon ascendant makes you nurturing and intuitive, but the 4th-house emphasis pulls you inward when you need outward momentum. Good for healing work, not conquest.",
                bestFor: ["Caregiving", "Therapy", "Nesting phase"],
                rank: 5,
                mapX: 110, mapY: 144
            ),
            CityRelocation(
                name: "Tokyo",
                country: "Japan",
                latitude: 35.6762,
                longitude: 139.6503,
                ascendantSign: "♓ Pisces",
                ascendantLord: "Jupiter",
                score: 0.42,
                deltaAsc: "+ Jupiter",
                deltaMc: "heavy",
                blemish: "inner work",
                description: "Inner work · public risk. Saturn in the 1st weights every step. The Jupiter-ruled Pisces ascendant promises expansion, but Saturn demands you earn it first. Transformative, not comfortable.",
                bestFor: ["Spiritual practice", "Artistic retreat", "Deep reset"],
                rank: 6,
                mapX: 372, mapY: 152
            ),
        ],
        planetaryLines: [
            PlanetaryLine(
                planet: "Jupiter",
                lineType: "MC",
                colorHex: "#D4A853",
                interpretation: "Career zenith amplified — public recognition flows when you're on this line.",
                svgPath: "M70 60 Q 250 90 460 80"
            ),
            PlanetaryLine(
                planet: "Venus",
                lineType: "AS",
                colorHex: "#9B7ED9",
                interpretation: "Relationships and creativity soften the ascendant — charm becomes a gravitational force.",
                svgPath: "M120 50 Q 220 200 360 280"
            ),
            PlanetaryLine(
                planet: "Saturn",
                lineType: "IC",
                colorHex: "#6CB8C8",
                interpretation: "Home and roots under Saturn's discipline — structure enters the private sphere.",
                svgPath: "M30 220 Q 250 240 470 220"
            ),
            PlanetaryLine(
                planet: "Mars",
                lineType: "AS",
                colorHex: "#B84C4C",
                interpretation: "Mars on the ascendant brings drive and confrontation — courage, but watch the burn rate.",
                svgPath: "M250 60 Q 280 200 290 290"
            ),
        ],
        topRecommendation: "Dubai"
    )
}

// MARK: - SVG Path Parsing (Simplified)

/// Parses a simplified SVG path (only M, Q commands) into an array of points
/// for rendering in a SwiftUI `Path`. Coordinates are in the 480×300 viewBox space.
private struct SimpleSVGPath {
    struct Command {
        enum Kind { case move, quadCurve }
        let kind: Kind
        let points: [CGPoint]
        // For quad curves: [control, end]. For move: [point].
    }

    let commands: [Command]

    init?(_ d: String) {
        var cmds: [Command] = []
        let tokens = d.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: CharacterSet.whitespaces)

        var i = 0
        var pendingCmd: String? = nil

        while i < tokens.count {
            let token = tokens[i]

            // Determine command kind
            let cmdChar: String
            if token == "M" || token == "m" || token == "Q" || token == "q" {
                cmdChar = token
                i += 1
            } else if let pc = pendingCmd {
                cmdChar = pc
            } else {
                i += 1
                continue
            }

            switch cmdChar.uppercased() {
            case "M":
                guard i + 1 < tokens.count else { return nil }
                let x = Double(tokens[i]) ?? 0
                let y = Double(tokens[i + 1]) ?? 0
                cmds.append(Command(kind: .move, points: [CGPoint(x: x, y: y)]))
                pendingCmd = "M"
                i += 2
            case "Q":
                guard i + 3 < tokens.count else { return nil }
                let cx = Double(tokens[i]) ?? 0
                let cy = Double(tokens[i + 1]) ?? 0
                let x = Double(tokens[i + 2]) ?? 0
                let y = Double(tokens[i + 3]) ?? 0
                cmds.append(Command(kind: .quadCurve, points: [
                    CGPoint(x: cx, y: cy),
                    CGPoint(x: x, y: y)
                ]))
                pendingCmd = "Q"
                i += 4
            default:
                i += 1
            }
        }

        guard !cmds.isEmpty else { return nil }
        self.commands = cmds
    }

    /// Append this path onto a SwiftUI `Path`, scaled to fit a target rect.
    func append(to path: inout Path, in rect: CGRect, viewBox: CGSize = CGSize(width: 480, height: 300)) {
        let sx = rect.width / viewBox.width
        let sy = rect.height / viewBox.height
        let scale = CGAffineTransform(scaleX: sx, y: sy)
        let translate = CGAffineTransform(translationX: rect.minX, y: rect.minY)

        for cmd in commands {
            switch cmd.kind {
            case .move:
                let pt = cmd.points[0].applying(scale).applying(translate)
                path.move(to: pt)
            case .quadCurve:
                let ctrl = cmd.points[0].applying(scale).applying(translate)
                let end = cmd.points[1].applying(scale).applying(translate)
                path.addQuadCurve(to: end, control: ctrl)
            }
        }
    }
}

// MARK: - Continent Silhouettes

/// Simplified continent silhouettes as a SwiftUI `Path`.
/// Hand-drawn fidelity — not geographically precise; matches the mockup aesthetic.
private struct ContinentPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // The mockup's continent path data (480×300 viewBox).
        // Four shapes: North America + Europe, Asia, Australia, South America.
        let d = "M30 100 q40 -50 90 -40 q40 8 60 -20 q40 -30 80 -20 q20 6 30 30 q-10 30 -50 40 q-40 6 -90 -10 q-30 30 -90 25 q-50 -5 -30 -25z M180 110 q50 -40 110 -30 q60 12 80 -10 q50 -50 110 -30 q40 14 50 50 q-30 60 -120 40 q-60 -10 -130 30 q-60 30 -100 0z M320 200 q40 0 50 30 q-10 50 -40 60 q-40 -10 -30 -50z M40 220 q40 -20 80 0 q40 20 30 50 q-30 30 -90 20 q-40 -20 -20 -70z"

        guard let svg = SimpleSVGPath(d) else { return path }
        svg.append(to: &path, in: rect)
        return path
    }
}

// MARK: - Astrocartography Map View

/// Interactive world map for relocation astrology.
///
/// Shows how a user's birth chart transforms when they relocate to
/// different cities. Tap a city dot to select it, or tap a row in the
/// ranked candidates list.
struct AstrocartographyMapView: View {
    @State private var selectedCityName: String
    @State private var globeRefreshToken = UUID()
    let data: AstrocartographyData

    init(data: AstrocartographyData = .sample) {
        self.data = data
        _selectedCityName = State(initialValue: data.topRecommendation)
    }

    private var selectedCity: CityRelocation {
        data.cities.first { $0.name == selectedCityName } ?? data.cities[0]
    }

    /// Cities sorted by rank for the candidates list.
    private var rankedCities: [CityRelocation] {
        data.cities.sorted { $0.rank < $1.rank }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                mapSection
                selectedCityPanel
                rankedCandidatesSection
            }
            .padding(.bottom, 90)
        }
        .background(Color.cosmicBackground)
        .scrollContentBackground(.hidden)
        .accessibilityIdentifier("astrocartographyMapView")
    }

    // MARK: - Section 1: Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
            // Eyebrow
            Text("ASTROCARTOGRAPHY · ACG/v2")
                .font(.cosmicMicro)
                .tracking(CosmicTypography.Tracking.uppercase)
                .foregroundStyle(Color.cosmicTextTertiary)

            HStack(alignment: .firstTextBaseline) {
                // Title — serif italic, cosmicGold
                Text("Where else.")
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(Color.cosmicGold)

                Spacer()

                // Trailing icon button
                Button {
                    CosmicHaptics.light()
                } label: {
                    Image(systemName: "scope")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.horizontal, Cosmic.Spacing.screen)
        .padding(.top, Cosmic.Spacing.md)
        .padding(.bottom, Cosmic.Spacing.xs)
    }

    // MARK: - Section 2: World Map

    private var mapSection: some View {
        VStack(spacing: 12) {
            ZStack {
                AppleGlobeRelocationMap(
                    cities: data.cities,
                    selectedCityName: $selectedCityName,
                    refreshToken: globeRefreshToken
                )
                .accessibilityIdentifier("appleMapsGlobeView")

                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("APPLE MAPS")
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .tracking(0.18)
                                .foregroundStyle(Color.white.opacity(0.68))
                                .accessibilityIdentifier("astrocartography.appleMaps.badge")
                            Text("Globe relocation field")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.white)
                        }

                        Spacer()

                        Button {
                            CosmicHaptics.light()
                            globeRefreshToken = UUID()
                        } label: {
                            Image(systemName: "map")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .frame(width: 42, height: 42)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .accessibilityLabel("Refresh Apple Maps globe")
                        .accessibilityIdentifier("astrocartography.appleMaps.refresh")
                    }

                    Spacer()

                    HStack {
                        Label("Imagery · realistic elevation", systemImage: "globe.americas.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.82))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(.ultraThinMaterial, in: Capsule())
                            .accessibilityIdentifier("astrocartography.appleMaps.realisticElevation")

                        Spacer()
                    }
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
                .padding(.top, 28)
                .padding(.bottom, 18)
            }
            .frame(height: globeHeroHeight)
            .clipped()
            .overlay(alignment: .topLeading) {
                headerSection
                    .padding(.top, 70)
            }
            .overlay(alignment: .bottomLeading) {
                HStack(spacing: 7) {
                    Text("Maps")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(Color.white)
                    Text("Legal")
                        .font(.system(size: 12, weight: .medium))
                        .underline()
                        .foregroundStyle(Color.white.opacity(0.62))
                }
                .padding(.leading, Cosmic.Spacing.screen)
                .padding(.bottom, 8)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(rankedCities) { city in
                        mapCityChip(city)
                    }
                }
                .padding(.horizontal, Cosmic.Spacing.screen)
            }
            .padding(.top, 4)
        }
    }

    private var globeHeroHeight: CGFloat {
        max(560, UIScreen.main.bounds.height * 0.66)
    }

    private func mapCityChip(_ city: CityRelocation) -> some View {
        let isSelected = city.name == selectedCityName

        return Button {
            CosmicHaptics.selection()
            withAnimation(.cosmicSpring) {
                selectedCityName = city.name
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "mappin.circle.fill" : "mappin.circle")
                Text(city.name)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(isSelected ? Color.cosmicBackground : Color.cosmicTextSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.cosmicGold : Color.cosmicStardust)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(Cosmic.Opacity.subtle), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("astrocartography.city.\(city.name)")
    }

    /// Renders the planet glyph + line type labels at their path endpoints.
    private func planetLineLabels(in size: CGSize) -> some View {
        let sx = size.width / 480.0
        let sy = size.height / 300.0

        return ZStack {
            // ♃ MC — right side, near top
            Text("♃ MC")
                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.cosmicGold)
                .position(x: 450 * sx, y: 78 * sy)

            // ♀ AS — lower right
            Text("♀ AS")
                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.cosmicAmethyst)
                .position(x: 365 * sx, y: 285 * sy)

            // ♄ IC — right side, middle
            Text("♄ IC")
                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.planetMercury)
                .position(x: 465 * sx, y: 218 * sy)

            // ♂ AS — lower center
            Text("♂ AS")
                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.planetMars)
                .position(x: 293 * sx, y: 295 * sy)
        }
    }

    /// A single city dot with label. Selected city gets a gold glow ring.
    private func cityDot(_ city: CityRelocation, in size: CGSize) -> some View {
        let sx = size.width / 480.0
        let sy = size.height / 300.0
        let x = city.mapX * sx
        let y = city.mapY * sy
        let isSelected = city.name == selectedCityName

        return ZStack {
            // Gold glow ring for selected city
            if isSelected {
                Circle()
                    .fill(Color.cosmicGold.opacity(0.18))
                    .frame(width: 18, height: 18)
                    .position(x: x, y: y)
            }

            // Dot
            Circle()
                .fill(isSelected ? Color.cosmicGold : Color.cosmicTextPrimary)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.cosmicGold : Color.clear, lineWidth: 0.5)
                )
                .frame(width: isSelected ? 7 : 4, height: isSelected ? 7 : 4)
                .position(x: x, y: y)

            // City label
            Text(city.name)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(isSelected ? Color.cosmicGold : Color.cosmicTextSecondary)
                .position(x: x + 6 * sx + 18, y: y + 3 * sy)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            CosmicHaptics.selection()
            withAnimation(.cosmicSpring) {
                selectedCityName = city.name
            }
        }
    }

    // MARK: - Section 3: Selected City Panel

    private var selectedCityPanel: some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                // City name + ASC re-cast badge
                HStack(alignment: .firstTextBaseline) {
                    Text(selectedCity.name)
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .tracking(-0.01)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    Spacer()

                    // ASC re-cast badge
                    HStack(spacing: 4) {
                        Text("ASC re-cast →")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.cosmicGold)
                        Text(selectedCity.ascendantSign
                            .components(separatedBy: " ")
                            .first ?? selectedCity.ascendantSign)
                            .font(.system(size: 18))
                    }
                }

                // Description paragraph
                Text(selectedCity.description)
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .lineSpacing(4)
                    .padding(.top, Cosmic.Spacing.xs)

                // Stats row — 3 columns: ΔASC, ΔMC, BLEMISH
                HStack(spacing: 10) {
                    statColumn(
                        label: "ΔASC",
                        value: selectedCity.deltaAsc,
                        valueColor: .cosmicGold
                    )
                    statColumn(
                        label: "ΔMC",
                        value: selectedCity.deltaMc,
                        valueColor: .cosmicSuccess
                    )
                    statColumn(
                        label: "BLEMISH",
                        value: selectedCity.blemish,
                        valueColor: .cosmicError
                    )
                }
                .padding(.top, 14)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cosmicGold.opacity(0.10),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.cosmicGold.opacity(0.22), lineWidth: 0.5)
                    )
            )
        }
        .padding(.horizontal, Cosmic.Spacing.screen)
        .padding(.top, 18)
    }

    private func statColumn(label: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(0.16)
                .foregroundStyle(Color.cosmicTextTertiary)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Section 4: Ranked Candidates List

    private var rankedCandidatesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section label
            Text("RANKED CANDIDATES")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(0.22)
                .foregroundStyle(Color.cosmicTextTertiary)

            // Candidate rows
            VStack(spacing: 6) {
                ForEach(Array(rankedCities.enumerated()), id: \.element.id) { index, city in
                    candidateRow(city, index: index)
                }
            }
        }
        .padding(.horizontal, Cosmic.Spacing.screen)
        .padding(.top, 18)
    }

    private func candidateRow(_ city: CityRelocation, index: Int) -> some View {
        Button {
            CosmicHaptics.selection()
            withAnimation(.cosmicSpring) {
                selectedCityName = city.name
            }
        } label: {
            HStack(spacing: 10) {
                // Rank number
                Text(String(format: "%02d", index + 1))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.cosmicTextTertiary)
                    .frame(width: 20, alignment: .leading)

                // City name
                Text(city.name)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.cosmicTextPrimary)

                // Change summary
                Text(changeSummary(for: city))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.cosmicTextSecondary)

                Spacer()

                // Score badge
                Text(String(format: "%.2f", city.score))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(scoreColor(city.score))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.cosmicStardust)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(Cosmic.Opacity.subtle), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    /// Derives a compact change summary string from the city's ascendant and MC data.
    private func changeSummary(for city: CityRelocation) -> String {
        let planet = city.ascendantLord

        switch city.score {
        case 0.8...:
            return "\(planet) MC ▸ +\(Int(city.score * 100 - 50))%"
        case 0.6..<0.8:
            return "\(planet) 10th ▸ +\(Int(city.score * 100 - 50))%"
        case 0.45..<0.6:
            return "\(planet) 9th ▸ −\(Int(50 - city.score * 100))% peace"
        default:
            return "\(planet) 1st ▸ heavy"
        }
    }

    /// Color-codes the score: green above 0.7, amber above 0.5, red below.
    private func scoreColor(_ score: Double) -> Color {
        if score > 0.7 {
            return .cosmicSuccess
        } else if score > 0.5 {
            return .cosmicWarning
        } else {
            return .cosmicError
        }
    }
}

// MARK: - Planetary Line Path Shape

/// Renders a single planetary influence line across the map.
private struct PlanetaryLinePath: Shape {
    let svgPath: String

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let svg = SimpleSVGPath(svgPath) else { return path }
        svg.append(to: &path, in: rect)
        return path
    }
}

// MARK: - Apple Maps Globe Surface

private struct AppleGlobeRelocationMap: View {
    let cities: [CityRelocation]
    @Binding var selectedCityName: String
    let refreshToken: UUID

    @State private var position: MapCameraPosition

    init(cities: [CityRelocation], selectedCityName: Binding<String>, refreshToken: UUID) {
        self.cities = cities
        self._selectedCityName = selectedCityName
        self.refreshToken = refreshToken

        let selected = cities.first { $0.name == selectedCityName.wrappedValue } ?? cities.first
        self._position = State(initialValue: Self.cameraPosition(for: selected, overview: true))
    }

    var body: some View {
        Map(position: $position, interactionModes: [.pan, .zoom, .rotate, .pitch]) {
            ForEach(relocationLines) { line in
                MapPolyline(coordinates: line.coordinates)
                    .stroke(
                        line.color.opacity(0.92),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [7, 5])
                    )
            }

            ForEach(cities) { city in
                Annotation(city.name, coordinate: city.coordinate, anchor: .bottom) {
                    cityAnnotation(city)
                }
            }
        }
        .mapStyle(.hybrid(elevation: .realistic, pointsOfInterest: .excludingAll, showsTraffic: false))
        .mapControls {
            MapCompass()
            MapScaleView()
            MapPitchToggle()
        }
        .onAppear {
            focusSelectedCity(overview: true)
        }
        .onChange(of: selectedCityName) { _, _ in
            focusSelectedCity(overview: false)
        }
        .onChange(of: refreshToken) { _, _ in
            focusSelectedCity(overview: true)
        }
        .accessibilityLabel("Apple Maps globe showing astrocartography relocation cities")
        .accessibilityIdentifier("astrocartography.appleMaps.globe")
    }

    private var relocationLines: [RelocationLineOverlay] {
        let byName = Dictionary(uniqueKeysWithValues: cities.map { ($0.name, $0.coordinate) })
        return [
            RelocationLineOverlay(
                id: "jupiter-mc",
                color: .cosmicGold,
                coordinates: compactCoordinates(["New York", "London", "Dubai", "Singapore"], byName: byName)
            ),
            RelocationLineOverlay(
                id: "venus-as",
                color: .cosmicAmethyst,
                coordinates: compactCoordinates(["London", "Dubai", "Bengaluru", "Singapore"], byName: byName)
            ),
            RelocationLineOverlay(
                id: "mars-as",
                color: .planetMars,
                coordinates: compactCoordinates(["Dubai", "Bengaluru", "Tokyo"], byName: byName)
            )
        ].filter { $0.coordinates.count > 1 }
    }

    private func cityAnnotation(_ city: CityRelocation) -> some View {
        let isSelected = city.name == selectedCityName

        return Button {
            CosmicHaptics.selection()
            withAnimation(.cosmicSpring) {
                selectedCityName = city.name
                position = Self.cameraPosition(for: city, overview: false)
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.cosmicGold.opacity(0.28) : Color.black.opacity(0.34))
                        .frame(width: isSelected ? 34 : 26, height: isSelected ? 34 : 26)
                        .blur(radius: isSelected ? 1 : 0)

                    Image(systemName: isSelected ? "star.circle.fill" : "mappin.circle.fill")
                        .font(.system(size: isSelected ? 23 : 18, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.cosmicGold : Color.white)
                        .shadow(color: Color.black.opacity(0.45), radius: 4, x: 0, y: 2)
                }

                Text(city.name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("astrocartography.map.annotation.\(city.name)")
        .accessibilityLabel("\(city.name), \(city.country), relocation score \(String(format: "%.0f", city.score * 100)) percent")
    }

    private func focusSelectedCity(overview: Bool) {
        guard let selected = cities.first(where: { $0.name == selectedCityName }) ?? cities.first else {
            return
        }

        withAnimation(.easeInOut(duration: 0.75)) {
            position = Self.cameraPosition(for: selected, overview: overview)
        }
    }

    private func compactCoordinates(
        _ names: [String],
        byName: [String: CLLocationCoordinate2D]
    ) -> [CLLocationCoordinate2D] {
        names.compactMap { byName[$0] }
    }

    private static func cameraPosition(for city: CityRelocation?, overview: Bool) -> MapCameraPosition {
        let overviewCenter = CLLocationCoordinate2D(latitude: 24, longitude: -38)
        let center = overview ? overviewCenter : city?.coordinate ?? overviewCenter
        let distance: CLLocationDistance = overview ? 24_000_000 : 4_200_000
        let heading: CLLocationDirection = overview ? 0 : 0
        let pitch: CGFloat = overview ? 0 : 32

        return .camera(MapCamera(
            centerCoordinate: center,
            distance: distance,
            heading: heading,
            pitch: pitch
        ))
    }
}

private struct RelocationLineOverlay: Identifiable {
    let id: String
    let color: Color
    let coordinates: [CLLocationCoordinate2D]
}

private extension CityRelocation {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Preview

#Preview("Astrocartography Map — Light") {
    AstrocartographyMapView()
        .preferredColorScheme(.light)
}

#Preview("Astrocartography Map — Dark") {
    AstrocartographyMapView()
        .preferredColorScheme(.dark)
}
