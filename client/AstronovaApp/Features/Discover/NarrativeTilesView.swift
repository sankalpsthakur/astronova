import SwiftUI

/// Tappable narrative tiles anchored to cosmic drivers
struct NarrativeTilesView: View {
    let tiles: [NarrativeTile]
    let onTileTap: ((NarrativeTile) -> Void)?

    @State private var expandedTileId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.s) {
            Text("Your Day")
                .font(.cosmicHeadline)
                .foregroundStyle(Color.cosmicTextPrimary)

            Text("Tap to see what's driving each insight")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)

            VStack(spacing: Cosmic.Spacing.xs) {
                ForEach(tiles) { tile in
                    NarrativeTileRow(
                        tile: tile,
                        isExpanded: expandedTileId == tile.id,
                        onTap: {
                            CosmicHaptics.light()
                            withAnimation(.spring(response: 0.3)) {
                                expandedTileId = expandedTileId == tile.id ? nil : tile.id
                            }
                            onTileTap?(tile)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Narrative Tile Row

private struct NarrativeTileRow: View {
    let tile: NarrativeTile
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main tile content
            Button(action: onTap) {
                HStack(alignment: .top, spacing: Cosmic.Spacing.s) {
                    // Domain indicator
                    domainIndicator

                    // Text content
                    VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                        Text(tile.text)
                            .font(.cosmicBody)
                            .foregroundStyle(Color.cosmicTextPrimary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(isExpanded ? nil : 2)
                    }

                    Spacer()

                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.cosmicMicro)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .padding(.top, Cosmic.Spacing.xxs)
                }
                .padding(Cosmic.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                        .fill(isExpanded ? Color.cosmicSurfaceSecondary : Color.cosmicSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                        .stroke(
                            isExpanded ? domainColor.opacity(0.4) : Color.cosmicGold.opacity(0.1),
                            lineWidth: isExpanded ? 1.5 : Cosmic.Border.hairline
                        )
                )
            }
            .buttonStyle(.plain)

            // Expanded driver info
            if isExpanded, let driver = tile.driver {
                driverInfo(driver)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Domain Indicator

    private var domainIndicator: some View {
        VStack(spacing: Cosmic.Spacing.xxs) {
            ZStack {
                Circle()
                    .fill(domainColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Text(domainIcon)
                    .font(.cosmicCallout)
            }

            // Weight indicator bar
            RoundedRectangle(cornerRadius: 2)
                .fill(domainColor)
                .frame(width: 4, height: CGFloat(tile.weight * 40))
                .opacity(0.6)
        }
    }

    private var domainColor: Color {
        switch tile.domain {
        case "self": return .cosmicGold
        case "love": return .planetVenus
        case "work": return .planetSaturn
        case "mind": return .planetMercury
        default: return .cosmicGold
        }
    }

    private var domainIcon: String {
        switch tile.domain {
        case "self": return "✦"
        case "love": return "♡"
        case "work": return "◆"
        case "mind": return "◎"
        default: return "●"
        }
    }

    // MARK: - Driver Info

    private func driverInfo(_ driver: TileDriver) -> some View {
        HStack(spacing: Cosmic.Spacing.s) {
            Image(systemName: "sparkles")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicGold)

            VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
                Text("Driven by")
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextSecondary)

                HStack(spacing: Cosmic.Spacing.xxs) {
                    Text(planetSymbol(for: driver.planet))
                        .font(.cosmicCallout)

                    Text("\(driver.planet.capitalized)")
                        .font(.cosmicCaptionEmphasis)
                        .foregroundStyle(Color.cosmicTextPrimary)

                    if let sign = driver.sign, !sign.isEmpty {
                        Text("in \(sign.capitalized)")
                            .font(.cosmicCaption)
                            .foregroundStyle(Color.cosmicTextSecondary)
                    }
                }
            }

            Spacer()

            // Frequency/vibration indicator
            VStack(alignment: .trailing, spacing: Cosmic.Spacing.xxs) {
                Text("Frequency")
                    .font(.cosmicMicro)
                    .foregroundStyle(Color.cosmicTextSecondary)

                HStack(spacing: Cosmic.Spacing.xxs) {
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(i < frequencyLevel ? domainColor : Color.cosmicTextSecondary.opacity(0.3))
                            .frame(width: 3, height: 8 + CGFloat(i) * 2)
                    }
                }
            }
        }
        .padding(Cosmic.Spacing.s)
        .padding(.leading, Cosmic.Spacing.xxl) // Align with text
        .background(Color.cosmicSurface.opacity(0.5))
    }

    private var frequencyLevel: Int {
        // Convert weight to 1-5 scale
        return max(1, min(5, Int(tile.weight * 5) + 1))
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
        case "uranus": return "♅"
        case "neptune": return "♆"
        case "pluto": return "♇"
        default: return "★"
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        NarrativeTilesView(
            tiles: [
                NarrativeTile(
                    id: "tile_1",
                    text: "Channel your natural achievement into meaningful projects.",
                    domain: "self",
                    weight: 0.3,
                    driver: TileDriver(type: "transit", planet: "sun", sign: "capricorn", longitude: 298.5)
                ),
                NarrativeTile(
                    id: "tile_2",
                    text: "Lead with empathy; ask one more question before responding.",
                    domain: "love",
                    weight: 0.25,
                    driver: TileDriver(type: "transit", planet: "venus", sign: "aquarius", longitude: 315.2)
                ),
                NarrativeTile(
                    id: "tile_3",
                    text: "Energy peaks mid-day; schedule deep work between 10am and 1pm.",
                    domain: "work",
                    weight: 0.25,
                    driver: TileDriver(type: "transit", planet: "mars", sign: "leo", longitude: 142.8)
                ),
                NarrativeTile(
                    id: "tile_4",
                    text: "Your mental clarity is heightened - perfect for important conversations.",
                    domain: "mind",
                    weight: 0.2,
                    driver: TileDriver(type: "transit", planet: "mercury", sign: "capricorn", longitude: 285.1)
                )
            ]
        ) { tile in
            #if DEBUG
            debugPrint("[NarrativeTilesView] Tapped tile: \(tile.id)")
            #endif
        }
        .padding()
    }
    .background(Color.cosmicBackground)
}
