import SwiftUI

// MARK: - Planetary Optimization Matrix
// Color-coded visual grid showing every planet's dignity status
// in the user's natal chart — a single-glance optimization snapshot.

// MARK: - Optimization Status

enum OptimizationStatus: String, CaseIterable, Codable {
    case exalted = "Exalted"
    case ownSign = "Own Sign"
    case friendly = "Friendly"
    case neutral = "Neutral"
    case debilitated = "Debilitated"

    var color: Color {
        switch self {
        case .exalted:
            return Color(red: 0.0, green: 0.9, blue: 0.3)
        case .ownSign:
            return Color(red: 0.1, green: 0.5, blue: 1.0)
        case .friendly:
            return Color(red: 0.3, green: 0.8, blue: 0.5)
        case .neutral:
            return Color.cosmicTextSecondary
        case .debilitated:
            return Color(red: 0.95, green: 0.2, blue: 0.2)
        }
    }

    var emoji: String {
        switch self {
        case .exalted: return "\u{1F7E2}"   // green circle
        case .ownSign: return "\u{1F535}"   // blue circle
        case .friendly: return "\u{1F7E1}"  // yellow circle
        case .neutral: return "\u{26AA}"    // white circle
        case .debilitated: return "\u{1F534}" // red circle
        }
    }

    var sortOrder: Int {
        switch self {
        case .exalted: return 0
        case .ownSign: return 1
        case .friendly: return 2
        case .neutral: return 3
        case .debilitated: return 4
        }
    }
}

// MARK: - Planet Matrix Entry

struct PlanetMatrixEntry: Identifiable, Codable {
    let id = UUID()
    let planet: String
    let symbol: String
    let sign: String
    let house: Int
    let degree: Double
    let status: OptimizationStatus
    let statusReason: String
    let directionalNote: String?
    let rulingHouse: String?

    enum CodingKeys: String, CodingKey {
        case planet
        case symbol
        case sign
        case house
        case degree
        case status
        case statusReason
        case directionalNote
        case rulingHouse
    }
}

// MARK: - Planetary Matrix View

struct PlanetaryMatrixView: View {
    let entries: [PlanetMatrixEntry]

    @State private var expandedIDs: Set<UUID> = []

    // MARK: - Computed

    private var sortedEntries: [PlanetMatrixEntry] {
        entries.sorted { lhs, rhs in
            if lhs.status.sortOrder == rhs.status.sortOrder {
                return planetSortIndex(lhs.planet) < planetSortIndex(rhs.planet)
            }
            return lhs.status.sortOrder < rhs.status.sortOrder
        }
    }

    private var exaltedCount: Int {
        entries.filter { $0.status == .exalted }.count
    }

    private var debilitatedCount: Int {
        entries.filter { $0.status == .debilitated }.count
    }

    private var ownSignCount: Int {
        entries.filter { $0.status == .ownSign }.count
    }

    // Vedic weekday order: Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn, Rahu, Ketu
    private func planetSortIndex(_ planet: String) -> Int {
        switch planet.lowercased() {
        case "sun", "surya": return 0
        case "moon", "chandra": return 1
        case "mars", "mangal": return 2
        case "mercury", "budha": return 3
        case "jupiter", "guru": return 4
        case "venus", "shukra": return 5
        case "saturn", "shani": return 6
        case "rahu": return 7
        case "ketu": return 8
        default: return 99
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.lg) {
            header
            summaryRow
            planetCards
        }
        .padding(Cosmic.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                .fill(Color.cosmicSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.card, style: .continuous)
                        .stroke(Color.cosmicGold.opacity(Cosmic.Opacity.subtle), lineWidth: Cosmic.Border.hairline)
                )
        )
        .cosmicElevation(.low)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.xxs) {
            Text("Optimization Matrix")
                .font(.cosmicTitle2)
                .foregroundStyle(Color.cosmicTextPrimary)

            Text("Planetary dignity across your natal chart")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Optimization Matrix. Planetary dignity across your natal chart.")
    }

    // MARK: - Summary Row

    private var summaryRow: some View {
        HStack(spacing: Cosmic.Spacing.sm) {
            statusChip(emoji: OptimizationStatus.exalted.emoji,
                       count: exaltedCount,
                       label: "Exalted",
                       color: OptimizationStatus.exalted.color)

            statusChip(emoji: OptimizationStatus.debilitated.emoji,
                       count: debilitatedCount,
                       label: "Debilitated",
                       color: OptimizationStatus.debilitated.color)

            statusChip(emoji: OptimizationStatus.ownSign.emoji,
                       count: ownSignCount,
                       label: "Own Sign",
                       color: OptimizationStatus.ownSign.color)

            Spacer(minLength: 0)
        }
        .padding(Cosmic.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                .fill(Color.cosmicVoid.opacity(0.3))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Summary: \(exaltedCount) exalted, \(debilitatedCount) debilitated, \(ownSignCount) own sign")
    }

    private func statusChip(emoji: String, count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(.cosmicCaption)
            Text("\(count)")
                .font(.cosmicCalloutEmphasis)
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextSecondary)
        }
    }

    // MARK: - Planet Cards

    private var planetCards: some View {
        VStack(spacing: Cosmic.Spacing.sm) {
            ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in
                PlanetCardView(
                    entry: entry,
                    isExpanded: expandedIDs.contains(entry.id),
                    onTap: {
                        CosmicHaptics.light()
                        withAnimation(.cosmicSpring) {
                            if expandedIDs.contains(entry.id) {
                                expandedIDs.remove(entry.id)
                            } else {
                                expandedIDs.insert(entry.id)
                            }
                        }
                    }
                )
                .cosmicStaggeredAppear(index: index, isVisible: true)
            }
        }
    }
}

// MARK: - Planet Card View

private struct PlanetCardView: View {
    let entry: PlanetMatrixEntry
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Main row
                mainRow

                // Expanded detail
                if isExpanded {
                    expandedDetail
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        ))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to see why")
    }

    // MARK: - Main Row

    private var mainRow: some View {
        HStack(spacing: Cosmic.Spacing.sm) {
            // Planet symbol + name
            planetIdentity

            // Sign + House + Degree
            placementInfo

            Spacer(minLength: Cosmic.Spacing.xs)

            // Status badge
            statusBadge

            // Chevron
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.cosmicTextTertiary)
                .frame(width: 16)
        }
        .padding(Cosmic.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.soft, style: .continuous)
                .fill(Color.cosmicVoid.opacity(Cosmic.Opacity.ghost))
        )
    }

    // MARK: - Planet Identity

    private var planetIdentity: some View {
        HStack(spacing: Cosmic.Spacing.xs) {
            Text(entry.symbol)
                .font(.system(size: 18))
                .foregroundStyle(planetColor)
                .frame(width: 24, alignment: .center)

            Text(entry.planet)
                .font(.cosmicCalloutEmphasis)
                .foregroundStyle(Color.cosmicTextPrimary)
        }
    }

    // MARK: - Placement Info

    private var placementInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(entry.sign)  \u{2022}  H\(entry.house)")
                .font(.cosmicCaption)
                .foregroundStyle(Color.cosmicTextSecondary)

            Text(String(format: "%.1f\u{00B0}", entry.degree))
                .font(.cosmicMicro)
                .foregroundStyle(Color.cosmicTextTertiary)
                .monospacedDigit()
        }
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Text(entry.status.emoji)
                .font(.cosmicCaption)
            Text(entry.status.rawValue)
                .font(.cosmicMicro)
                .foregroundStyle(entry.status.color)
        }
        .padding(.horizontal, Cosmic.Spacing.xs)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous)
                .fill(entry.status.color.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: Cosmic.Radius.subtle, style: .continuous)
                        .stroke(entry.status.color.opacity(0.3), lineWidth: Cosmic.Border.hairline)
                )
        )
    }

    // MARK: - Expanded Detail

    private var expandedDetail: some View {
        VStack(alignment: .leading, spacing: Cosmic.Spacing.sm) {
            Divider()
                .background(Color.cosmicTextTertiary.opacity(0.15))

            // Status reason
            HStack(alignment: .top, spacing: Cosmic.Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundStyle(entry.status.color)
                    .frame(width: 16)

                Text(entry.statusReason)
                    .font(.cosmicCaption)
                    .foregroundStyle(Color.cosmicTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Directional note
            if let directionalNote = entry.directionalNote {
                HStack(alignment: .top, spacing: Cosmic.Spacing.xs) {
                    Image(systemName: "location.north")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.cosmicGold)
                        .frame(width: 16)

                    Text(directionalNote)
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Ruling houses
            if let rulingHouse = entry.rulingHouse {
                HStack(alignment: .top, spacing: Cosmic.Spacing.xs) {
                    Image(systemName: "house")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.cosmicCopper)
                        .frame(width: 16)

                    Text("Rules: \(rulingHouse)")
                        .font(.cosmicCaption)
                        .foregroundStyle(Color.cosmicTextSecondary)
                }
            }
        }
        .padding(.horizontal, Cosmic.Spacing.sm)
        .padding(.vertical, Cosmic.Spacing.sm)
    }

    // MARK: - Helpers

    private var planetColor: Color {
        DashaConstants.color(for: entry.planet)
    }

    private var accessibilityText: String {
        "\(entry.planet) in \(entry.sign), House \(entry.house) at \(String(format: "%.1f", entry.degree)) degrees. Status: \(entry.status.rawValue)."
    }
}

// MARK: - Sample Data

extension PlanetaryMatrixView {
    static var sampleEntries: [PlanetMatrixEntry] {
        [
            PlanetMatrixEntry(
                planet: "Sun",
                symbol: "\u{2609}",
                sign: "Aries",
                house: 1,
                degree: 10.5,
                status: .exalted,
                statusReason: "Sun at 10\u{00B0} Aries = exact exaltation point. Peak solar dignity lending charisma and leadership force.",
                directionalNote: "Strong in 1st house (East direction) \u{2014} the angular house amplifies solar expression.",
                rulingHouse: "5th house (creativity, intelligence)"
            ),
            PlanetMatrixEntry(
                planet: "Moon",
                symbol: "\u{263D}",
                sign: "Taurus",
                house: 2,
                degree: 3.2,
                status: .exalted,
                statusReason: "Moon at 3\u{00B0} Taurus = exaltation degree. Emotional stability, wealth, and deep nourishment.",
                directionalNote: "2nd house fortifies financial intuition and family bonds.",
                rulingHouse: "4th house (home, mother, inner peace)"
            ),
            PlanetMatrixEntry(
                planet: "Mars",
                symbol: "\u{2642}",
                sign: "Capricorn",
                house: 10,
                degree: 28.0,
                status: .exalted,
                statusReason: "Mars at 28\u{00B0} Capricorn = exact exaltation degree. Disciplined action, strategic power, career drive.",
                directionalNote: "Strong in 10th house (South direction) \u{2014} maximum professional impact.",
                rulingHouse: "1st and 8th houses"
            ),
            PlanetMatrixEntry(
                planet: "Mercury",
                symbol: "\u{263F}",
                sign: "Virgo",
                house: 6,
                degree: 15.3,
                status: .ownSign,
                statusReason: "Mercury in Virgo \u{2014} its own sign and exalted. Analytical precision, communication mastery.",
                directionalNote: "6th house adds a service-oriented intelligence.",
                rulingHouse: "3rd and 6th houses"
            ),
            PlanetMatrixEntry(
                planet: "Jupiter",
                symbol: "\u{2643}",
                sign: "Pisces",
                house: 12,
                degree: 5.8,
                status: .ownSign,
                statusReason: "Jupiter in Pisces \u{2014} its own sign. Expansive wisdom, spiritual depth, compassionate guidance.",
                directionalNote: "12th house channels Jupiter's wisdom inwardly \u{2014} strong meditation and dream insight.",
                rulingHouse: "9th and 12th houses"
            ),
            PlanetMatrixEntry(
                planet: "Venus",
                symbol: "\u{2640}",
                sign: "Libra",
                house: 7,
                degree: 22.1,
                status: .ownSign,
                statusReason: "Venus in Libra \u{2014} its own sign. Grace in relationships, artistic refinement, diplomatic charm.",
                directionalNote: "7th house (West direction) \u{2014} partnership and marriage receive full Venusian blessings.",
                rulingHouse: "2nd and 7th houses"
            ),
            PlanetMatrixEntry(
                planet: "Saturn",
                symbol: "\u{2644}",
                sign: "Aquarius",
                house: 11,
                degree: 17.4,
                status: .ownSign,
                statusReason: "Saturn in Aquarius \u{2014} its own sign. Structured innovation, disciplined social vision, steady gains.",
                directionalNote: "11th house amplifies network-building and long-term goal achievement.",
                rulingHouse: "10th and 11th houses"
            ),
            PlanetMatrixEntry(
                planet: "Rahu",
                symbol: "\u{260A}",
                sign: "Gemini",
                house: 3,
                degree: 12.7,
                status: .friendly,
                statusReason: "Rahu in Mercury-ruled Gemini \u{2014} friendly placement. Amplified curiosity, media savvy, unconventional communication.",
                directionalNote: "3rd house energizes courage, writing, and short-distance ventures.",
                rulingHouse: nil
            ),
            PlanetMatrixEntry(
                planet: "Ketu",
                symbol: "\u{260B}",
                sign: "Sagittarius",
                house: 9,
                degree: 12.7,
                status: .friendly,
                statusReason: "Ketu in Jupiter-ruled Sagittarius \u{2014} friendly placement. Detached wisdom, past-life spiritual mastery, philosophical insight.",
                directionalNote: "9th house deepens the spiritual detachment \u{2014} natural teacher energy.",
                rulingHouse: nil
            ),
            PlanetMatrixEntry(
                planet: "Saturn",
                symbol: "\u{2644}",
                sign: "Aries",
                house: 4,
                degree: 20.0,
                status: .debilitated,
                statusReason: "Saturn at 20\u{00B0} Aries \u{2014} exact debilitation point. Aries' impulsiveness conflicts with Saturn's discipline; lessons around patience and emotional security.",
                directionalNote: "4th house makes home and inner peace the arena for Saturn's slow maturation.",
                rulingHouse: "10th and 11th houses"
            )
        ]
    }
}

// MARK: - Previews

#Preview("Matrix View - Light") {
    ZStack {
        Color.cosmicVoid.ignoresSafeArea()

        ScrollView {
            PlanetaryMatrixView(entries: PlanetaryMatrixView.sampleEntries)
                .padding(Cosmic.Spacing.screen)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Matrix View - Dark") {
    ZStack {
        Color.cosmicVoid.ignoresSafeArea()

        ScrollView {
            PlanetaryMatrixView(entries: PlanetaryMatrixView.sampleEntries)
                .padding(Cosmic.Spacing.screen)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Matrix View - Compact") {
    ZStack {
        Color.cosmicVoid.ignoresSafeArea()

        PlanetaryMatrixView(entries: Array(PlanetaryMatrixView.sampleEntries.prefix(5)))
            .padding(Cosmic.Spacing.screen)
    }
    .preferredColorScheme(.dark)
}
