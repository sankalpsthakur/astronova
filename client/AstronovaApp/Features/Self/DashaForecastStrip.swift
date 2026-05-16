import SwiftUI

// MARK: - Dasha Forecast Strip
// Renders upcoming dasha transitions as a horizontal "weather forecast" strip.
// Each card surfaces a single upcoming MD / AD / PD lord switch with a
// relative time-to-event label.

struct DashaForecastStrip: View {
    let transitions: DashaCompleteResponse.TransitionInfo?
    var maxVisibleCards: Int = 5
    var onSeeMore: (() -> Void)? = nil

    private var cards: [TransitionCard] {
        DashaForecastStrip.buildCards(from: transitions)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Forecast", systemImage: "cloud.sun.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                if cards.count > maxVisibleCards, let onSeeMore {
                    Button("See more", action: onSeeMore)
                        .font(.caption.weight(.medium))
                }
            }

            if cards.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(cards.prefix(maxVisibleCards)) { card in
                            DashaForecastCard(card: card)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var emptyState: some View {
        Text("No transitions in the visible window")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }

    // MARK: - Card synthesis

    fileprivate static func buildCards(from info: DashaCompleteResponse.TransitionInfo?) -> [TransitionCard] {
        guard let info else { return [] }
        var result: [TransitionCard] = []

        if let pd = info.timing?.pratyantardasha,
           let card = TransitionCard.make(level: .pratyantardasha, timing: pd) {
            result.append(card)
        }
        if let ad = info.timing?.antardasha,
           let card = TransitionCard.make(level: .antardasha, timing: ad) {
            result.append(card)
        }
        if let md = info.timing?.mahadasha,
           let card = TransitionCard.make(level: .mahadasha, timing: md) {
            result.append(card)
        }

        // Order by soonest first when day counts are known.
        result.sort { ($0.daysUntil ?? .max) < ($1.daysUntil ?? .max) }
        return result
    }
}

// MARK: - Transition Card Model

fileprivate struct TransitionCard: Identifiable {
    enum Level: String {
        case mahadasha
        case antardasha
        case pratyantardasha

        var shortLabel: String {
            switch self {
            case .mahadasha: return "MD"
            case .antardasha: return "AD"
            case .pratyantardasha: return "PD"
            }
        }
    }

    let id = UUID()
    let level: Level
    let currentLord: String
    let nextLord: String
    let daysUntil: Int?
    let endsOn: Date?

    static func make(level: Level,
                     timing: DashaCompleteResponse.TransitionInfo.Timing.PeriodTiming) -> TransitionCard? {
        guard let current = timing.currentLord, let next = timing.nextLord,
              !current.isEmpty, !next.isEmpty else { return nil }
        return TransitionCard(
            level: level,
            currentLord: current.capitalized,
            nextLord: next.capitalized,
            daysUntil: timing.daysRemaining,
            endsOn: timing.endsOn.flatMap(DashaForecastDateParser.parse)
        )
    }

    var relativeLabel: String {
        if let days = daysUntil {
            return DashaForecastDateParser.relativeLabel(daysUntil: days)
        }
        if let endsOn {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: endsOn).day ?? 0
            return DashaForecastDateParser.relativeLabel(daysUntil: max(0, days))
        }
        return "soon"
    }

    var summary: String {
        "\(currentLord) \(level.shortLabel) ends \(relativeLabel) → \(nextLord) \(level.shortLabel) begins"
    }
}

// MARK: - Card View

fileprivate struct DashaForecastCard: View {
    let card: TransitionCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(DashaConstants.symbol(for: card.nextLord))
                    .font(.title3)
                Text(card.level.shortLabel)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.18), in: Capsule())
            }
            Text(card.relativeLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
            Text("\(card.currentLord) → \(card.nextLord)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .padding(10)
        .frame(width: 132, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}

// MARK: - Date helpers

fileprivate enum DashaForecastDateParser {
    static func parse(_ raw: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: raw) { return d }
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: raw) { return d }
        let plain = DateFormatter()
        plain.dateFormat = "yyyy-MM-dd"
        return plain.date(from: raw)
    }

    static let componentsFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.unitsStyle = .full
        f.maximumUnitCount = 1
        f.allowedUnits = [.year, .month, .day]
        return f
    }()

    static func relativeLabel(daysUntil: Int) -> String {
        if daysUntil <= 0 { return "today" }
        if daysUntil == 1 { return "in 1 day" }
        if daysUntil < 60 { return "in \(daysUntil) days" }
        let secs = TimeInterval(daysUntil) * 86_400
        if let label = componentsFormatter.string(from: secs) {
            return "in \(label)"
        }
        return "in \(daysUntil) days"
    }
}

// MARK: - Preview

#Preview("Forecast strip") {
    let timing = DashaCompleteResponse.TransitionInfo.Timing(
        mahadasha: .init(currentLord: "saturn", nextLord: "mercury",
                         endsOn: nil, daysRemaining: 720,
                         monthsRemaining: nil, yearsRemaining: nil),
        antardasha: .init(currentLord: "saturn", nextLord: "mercury",
                          endsOn: nil, daysRemaining: 47,
                          monthsRemaining: nil, yearsRemaining: nil),
        pratyantardasha: .init(currentLord: "venus", nextLord: "sun",
                               endsOn: nil, daysRemaining: 9,
                               monthsRemaining: nil, yearsRemaining: nil)
    )
    let info = DashaCompleteResponse.TransitionInfo(
        timing: timing,
        insights: nil,
        impactComparison: nil,
        nextKeywords: nil,
        nextLord: nil,
        preparationTips: nil,
        summary: nil,
        timeRemaining: nil
    )
    return VStack(spacing: 24) {
        DashaForecastStrip(transitions: info)
        Divider()
        DashaForecastStrip(transitions: nil)
    }
    .padding()
}
