import CoreGraphics
import Foundation

// MARK: - Time Travel Snapshot
// Single atomic unit that drives the Time Travel UI for a given targetDate.

struct TimeTravelSnapshot: Equatable {
    let targetDate: Date

    // Cosmic map
    let planets: [PlanetState]
    let currentDasha: DashaContext
    let aspects: [ActiveAspect]

    // Meaning stack
    let now: NowInsight
    /// Sorted soonest → latest
    let nextTransitions: [NextTransition]
    let act: ActionGuidance
}

// MARK: - Planet State

struct PlanetState: Identifiable, Equatable {
    let id: String
    let name: String
    let symbol: String

    /// 0–360 degrees ecliptic longitude.
    let longitude: Double
    /// Display name (normalized to Western sign names).
    let sign: String
    /// 0–30 degree within sign.
    let degree: Double

    let house: Int?
    let significance: String?

    let isRetrograde: Bool
    /// Approx degrees/day, used for trails and aspect "applying" direction.
    let speed: Double

    // Dasha highlighting
    var isDashaLord: Bool = false
    var isAntardashaLord: Bool = false
}

// MARK: - Dasha Context

struct DashaContext: Equatable {
    let mahadasha: DashaPeriodInfo
    let antardasha: DashaPeriodInfo
    let pratyantardasha: DashaPeriodInfo?

    /// Full antardasha timeline within the current mahadasha, sorted by start date.
    let antardashaTimeline: [DashaPeriodInfo]

    /// Progress through current periods (0.0 - 1.0).
    let mahadashaProgress: Double
    let antardashaProgress: Double
}

struct DashaPeriodInfo: Equatable {
    let lord: String
    let symbol: String
    let startDate: Date
    let endDate: Date
    let theme: String
}

// MARK: - Aspects

struct ActiveAspect: Identifiable, Equatable {
    var id: String { "\(planet1)-\(planet2)-\(type.rawValue)" }

    let planet1: String
    let planet2: String
    let type: AspectType
    let orb: Double
    let isApplying: Bool
    let significance: String
}

enum AspectType: String, Equatable {
    case conjunction
    case sextile
    case square
    case trine
    case opposition

    var angle: Double {
        switch self {
        case .conjunction: return 0
        case .sextile: return 60
        case .square: return 90
        case .trine: return 120
        case .opposition: return 180
        }
    }

    var isHarmonious: Bool {
        switch self {
        case .conjunction, .sextile, .trine: return true
        case .square, .opposition: return false
        }
    }
}

// MARK: - Meaning Stack Models

struct NowInsight: Equatable {
    let theme: String
    let risk: String
    let opportunity: String
    let expandedDetail: String?
}

struct NextTransition: Identifiable, Equatable {
    var id: String { "\(transitionType.rawValue)-\(targetDate.timeIntervalSinceReferenceDate)-\(fromLord)-\(toLord)" }

    let transitionType: TransitionType
    let targetDate: Date
    let daysUntil: Int
    let whatShifts: String
    let fromLord: String
    let toLord: String

    var countdownShort: String {
        if daysUntil < 30 { return "\(daysUntil)d" }
        let months = max(1, daysUntil / 30)
        if months < 24 { return "\(months)mo" }
        let years = max(1, months / 12)
        return "\(years)y"
    }
}

enum TransitionType: String, Equatable {
    case mahadasha = "Mahadasha"
    case antardasha = "Antardasha"
    case pratyantardasha = "Pratyantardasha"

    var shortLabel: String {
        switch self {
        case .mahadasha: return "Maha"
        case .antardasha: return "Antar"
        case .pratyantardasha: return "Praty"
        }
    }
}

struct ActionGuidance: Equatable {
    let doThis: String
    let avoidThis: String
    let whyExplanation: String
}

// MARK: - Cosmic Element (Selection State)

enum CosmicElement: Equatable, Hashable {
    case planet(String)
    case dashaLord(String)
    case aspect(String, String)

    var displayName: String {
        switch self {
        case .planet(let id): return id.capitalized
        case .dashaLord(let name): return name
        case .aspect(let p1, let p2): return "\(p1.capitalized)-\(p2.capitalized)"
        }
    }
}

// MARK: - Hit Area (Tap Detection)

struct HitArea {
    let element: CosmicElement
    let center: CGPoint
    let radius: CGFloat

    func contains(_ point: CGPoint) -> Bool {
        let dx = point.x - center.x
        let dy = point.y - center.y
        return (dx * dx + dy * dy) <= (radius * radius)
    }
}

// MARK: - Seeker Feedback (Delta Insights)

struct ScrubInsight: Identifiable, Equatable {
    enum Tone: Equatable {
        case supportive
        case challenging
        case review
        case neutral
    }

    let id: String
    let tone: Tone
    let text: String
    /// Optional mapping back to the cosmic map for reciprocal interactions (tap chip → highlight).
    let element: CosmicElement?
}

struct ScrubFeedback: Equatable {
    let insights: [ScrubInsight]
    let summary: String?
}

// MARK: - Snapshot Builder

extension TimeTravelSnapshot {
    static func build(
        targetDate: Date,
        planets: [PlanetState],
        dashaResponse: DashaCompleteResponse
    ) -> TimeTravelSnapshot {
        let dasha = buildDashaContext(from: dashaResponse, targetDate: targetDate, planets: planets)
        let flaggedPlanets = markDashaPlanets(planets, dasha: dasha)

        let aspects = generateAspects(planets: flaggedPlanets)
        let now = buildNowInsight(from: dashaResponse)
        let nextTransitions = buildNextTransitions(from: dashaResponse, targetDate: targetDate)
        let act = buildActionGuidance(from: dashaResponse)

        return TimeTravelSnapshot(
            targetDate: targetDate,
            planets: flaggedPlanets,
            currentDasha: dasha,
            aspects: aspects,
            now: now,
            nextTransitions: nextTransitions,
            act: act
        )
    }

    static func planetState(from position: DetailedPlanetaryPosition) -> PlanetState {
        let idx = signIndex(for: position.sign) ?? 0
        let longitude = normalizeLongitude(Double(idx) * 30.0 + position.degree)

        let displaySign = westernSignNames[safe: idx] ?? position.sign

        let baseSpeed = defaultDailySpeed(forPlanetId: position.id)
        let speed = (position.retrograde ? -abs(baseSpeed) : abs(baseSpeed))

        return PlanetState(
            id: position.id,
            name: position.name,
            symbol: position.symbol,
            longitude: longitude,
            sign: displaySign,
            degree: position.degree,
            house: position.house,
            significance: position.significance,
            isRetrograde: position.retrograde,
            speed: speed
        )
    }

    static func computeAspects(planets: [PlanetState]) -> [ActiveAspect] {
        generateAspects(planets: planets)
    }
}

// MARK: - UI Test / Preview Helpers

extension TimeTravelSnapshot {
    static func sample(targetDate: Date = Date()) -> TimeTravelSnapshot {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .year, value: -2, to: targetDate) ?? targetDate
        let end = calendar.date(byAdding: .year, value: 18, to: targetDate) ?? targetDate

        let maha = DashaPeriodInfo(
            lord: "Jupiter",
            symbol: "♃",
            startDate: start,
            endDate: end,
            theme: "Expansion, teachers, and long-range luck."
        )
        let antarStart = calendar.date(byAdding: .month, value: -6, to: targetDate) ?? targetDate
        let antarEnd = calendar.date(byAdding: .month, value: 10, to: targetDate) ?? targetDate
        let antar = DashaPeriodInfo(
            lord: "Venus",
            symbol: "♀",
            startDate: antarStart,
            endDate: antarEnd,
            theme: "Relationships, beauty, and alignment."
        )

        let dasha = DashaContext(
            mahadasha: maha,
            antardasha: antar,
            pratyantardasha: nil,
            antardashaTimeline: [antar],
            mahadashaProgress: 0.42,
            antardashaProgress: 0.33
        )

        let planets: [PlanetState] = [
            PlanetState(id: "sun", name: "Sun", symbol: "☉", longitude: 128.2, sign: "Leo", degree: 8.2, house: nil, significance: "Vitality, visibility.", isRetrograde: false, speed: 0.98),
            PlanetState(id: "moon", name: "Moon", symbol: "☾", longitude: 242.1, sign: "Sagittarius", degree: 2.1, house: nil, significance: "Emotions, instincts.", isRetrograde: false, speed: 13.1),
            PlanetState(id: "mercury", name: "Mercury", symbol: "☿", longitude: 101.7, sign: "Cancer", degree: 11.7, house: nil, significance: "Mind, messages.", isRetrograde: true, speed: -0.2),
            PlanetState(id: "venus", name: "Venus", symbol: "♀", longitude: 312.4, sign: "Aquarius", degree: 12.4, house: nil, significance: "Love, values.", isRetrograde: false, speed: 1.1, isAntardashaLord: true),
            PlanetState(id: "mars", name: "Mars", symbol: "♂", longitude: 20.6, sign: "Aries", degree: 20.6, house: nil, significance: "Drive, courage.", isRetrograde: false, speed: 0.7),
            PlanetState(id: "jupiter", name: "Jupiter", symbol: "♃", longitude: 55.0, sign: "Taurus", degree: 25.0, house: nil, significance: "Growth, mentors.", isRetrograde: false, speed: 0.08, isDashaLord: true),
            PlanetState(id: "saturn", name: "Saturn", symbol: "♄", longitude: 305.2, sign: "Aquarius", degree: 5.2, house: nil, significance: "Structure, time.", isRetrograde: true, speed: -0.02),
            PlanetState(id: "rahu", name: "Rahu", symbol: "☊", longitude: 185.0, sign: "Libra", degree: 5.0, house: nil, significance: "Desire, hunger.", isRetrograde: true, speed: -0.05),
            PlanetState(id: "ketu", name: "Ketu", symbol: "☋", longitude: 5.0, sign: "Aries", degree: 5.0, house: nil, significance: "Release, clarity.", isRetrograde: true, speed: -0.05),
            PlanetState(id: "ascendant", name: "Ascendant", symbol: "↑", longitude: 90.0, sign: "Cancer", degree: 0.0, house: 1, significance: "Approach, presence.", isRetrograde: false, speed: 0.0),
        ]

        let aspects: [ActiveAspect] = [
            ActiveAspect(
                planet1: "sun",
                planet2: "moon",
                type: .trine,
                orb: 1.8,
                isApplying: true,
                significance: "Head and heart cooperate; decisions land cleanly."
            )
        ]

        let now = NowInsight(
            theme: "Build the next chapter with calm conviction.",
            risk: "Overcommitting to someone else’s timeline.",
            opportunity: "Make one decisive move that simplifies the week.",
            expandedDetail: "Your current dasha emphasis supports steady growth. If you pick a direction and remove noise, progress accelerates."
        )

        let transitionDate = calendar.date(byAdding: .day, value: 23, to: targetDate) ?? targetDate
        let nextTransitions: [NextTransition] = [
            NextTransition(
                transitionType: .antardasha,
                targetDate: transitionDate,
                daysUntil: 23,
                whatShifts: "Near-term focus shifts from Venus to Mercury themes.",
                fromLord: "Venus",
                toLord: "Mercury"
            )
        ]

        let act = ActionGuidance(
            doThis: "Write down your next 3 moves. Execute the first today.",
            avoidThis: "Starting new commitments without an end date.",
            whyExplanation: "This phase rewards clean priorities and bounded effort."
        )

        return TimeTravelSnapshot(
            targetDate: targetDate,
            planets: planets,
            currentDasha: dasha,
            aspects: aspects,
            now: now,
            nextTransitions: nextTransitions,
            act: act
        )
    }
}

// MARK: - Builder Helpers

private extension TimeTravelSnapshot {
    static func buildDashaContext(from response: DashaCompleteResponse, targetDate: Date, planets: [PlanetState]) -> DashaContext {
        let maha = response.currentPeriod.mahadasha
        let antar = response.currentPeriod.antardasha ?? response.currentPeriod.mahadasha
        let praty = response.currentPeriod.pratyantardasha

        let mahaStart = parseDate(maha.start) ?? targetDate
        let mahaEnd = parseDate(maha.end) ?? targetDate

        let antarStart = parseDate(antar.start) ?? targetDate
        let antarEnd = parseDate(antar.end) ?? targetDate

        func symbol(for lord: String) -> String {
            planets.first { $0.name == lord }?.symbol ?? planetSymbol(for: lord)
        }

        let mahaTheme = keywordTheme(from: response.planetaryKeywords.mahadasha, fallbackLord: maha.lord)
        let antarTheme = keywordTheme(from: response.planetaryKeywords.antardasha, fallbackLord: antar.lord)

        let pratyInfo: DashaPeriodInfo? = {
            guard let praty else { return nil }
            let start = parseDate(praty.start) ?? targetDate
            let end = parseDate(praty.end) ?? targetDate
            return DashaPeriodInfo(
                lord: praty.lord,
                symbol: symbol(for: praty.lord),
                startDate: start,
                endDate: end,
                theme: shortPlanetTheme(for: praty.lord)
            )
        }()

        let antardashaTimeline: [DashaPeriodInfo] = (response.dasha.allAntardashas ?? [])
            .map { period in
                DashaPeriodInfo(
                    lord: period.lord,
                    symbol: symbol(for: period.lord),
                    startDate: parseDate(period.start) ?? targetDate,
                    endDate: parseDate(period.end) ?? targetDate,
                    theme: shortPlanetTheme(for: period.lord)
                )
            }
            .sorted { $0.startDate < $1.startDate }

        return DashaContext(
            mahadasha: DashaPeriodInfo(
                lord: maha.lord,
                symbol: symbol(for: maha.lord),
                startDate: mahaStart,
                endDate: mahaEnd,
                theme: mahaTheme
            ),
            antardasha: DashaPeriodInfo(
                lord: antar.lord,
                symbol: symbol(for: antar.lord),
                startDate: antarStart,
                endDate: antarEnd,
                theme: antarTheme
            ),
            pratyantardasha: pratyInfo,
            antardashaTimeline: antardashaTimeline,
            mahadashaProgress: progress(targetDate, start: mahaStart, end: mahaEnd),
            antardashaProgress: progress(targetDate, start: antarStart, end: antarEnd)
        )
    }

    static func markDashaPlanets(_ planets: [PlanetState], dasha: DashaContext) -> [PlanetState] {
        var copy = planets
        for idx in copy.indices {
            if copy[idx].name == dasha.mahadasha.lord {
                copy[idx].isDashaLord = true
            }
            if copy[idx].name == dasha.antardasha.lord {
                copy[idx].isAntardashaLord = true
            }
        }
        return copy
    }

    static func buildNowInsight(from response: DashaCompleteResponse) -> NowInsight {
        let mahaLord = response.currentPeriod.mahadasha.lord
        let antarLord = response.currentPeriod.antardasha?.lord ?? mahaLord

        let mahaKeyword = response.planetaryKeywords.mahadasha.first
        let antarKeyword = response.planetaryKeywords.antardasha.first
        let theme: String = {
            switch (mahaKeyword, antarKeyword) {
            case let (a?, b?) where a.lowercased() != b.lowercased():
                return "\(titleCase(a)) meets \(titleCase(b))"
            case let (a?, _):
                return "Deepening \(titleCase(a))"
            default:
                return "\(mahaLord) • \(antarLord)"
            }
        }()

        let combined = response.impactAnalysis.combinedScores
        let topArea = bestImpactArea(combined)
        let lowArea = worstImpactArea(combined)

        let opportunity = opportunityLabel(for: topArea)
        let risk = riskLabel(for: lowArea)

        let narrative = response.currentPeriod.narrative
        let expanded = [narrative.nonEmpty, expandedKeywords(maha: response.planetaryKeywords.mahadasha, antar: response.planetaryKeywords.antardasha)]
            .compactMap { $0 }
            .joined(separator: "\n\n")

        return NowInsight(
            theme: theme,
            risk: risk,
            opportunity: opportunity,
            expandedDetail: expanded.isEmpty ? nil : expanded
        )
    }

    static func buildActionGuidance(from response: DashaCompleteResponse) -> ActionGuidance {
        let guide = response.education?.antardashaGuide ?? response.education?.mahadashaGuide

        let doThis = guide?.opportunities?.first
            ?? guide?.advice?.sentencePrefix
            ?? "Take one aligned step toward your priorities."

        let avoidThis = guide?.challenges?.first
            ?? "Overcommitting without clarity."

        let why = [
            guide?.overview?.nonEmpty,
            guide?.advice?.nonEmpty,
            response.currentPeriod.narrative.nonEmpty,
        ]
        .compactMap { $0 }
        .joined(separator: "\n\n")

        return ActionGuidance(
            doThis: doThis,
            avoidThis: avoidThis,
            whyExplanation: why
        )
    }

    static func buildNextTransitions(from response: DashaCompleteResponse, targetDate: Date) -> [NextTransition] {
        let calendar = Calendar.current

        func daysUntil(_ end: Date) -> Int {
            max(0, calendar.dateComponents([.day], from: targetDate, to: end).day ?? 0)
        }

        func transition(
            type: TransitionType,
            currentLord: String?,
            nextLord: String?,
            endsOn: String?,
            daysRemaining: Int?,
            whatShifts: String?
        ) -> NextTransition? {
            guard let currentLord, let nextLord, let endsOn, let endDate = parseDate(endsOn) else { return nil }
            let days = daysRemaining ?? daysUntil(endDate)
            return NextTransition(
                transitionType: type,
                targetDate: endDate,
                daysUntil: max(0, days),
                whatShifts: whatShifts ?? shiftSummary(toLord: nextLord, type: type),
                fromLord: currentLord,
                toLord: nextLord
            )
        }

        var transitions: [NextTransition] = []

        if let timing = response.transitions?.timing {
            if let pratyantarTransition = transition(
                type: .pratyantardasha,
                currentLord: timing.pratyantardasha?.currentLord,
                nextLord: timing.pratyantardasha?.nextLord,
                endsOn: timing.pratyantardasha?.endsOn,
                daysRemaining: timing.pratyantardasha?.daysRemaining,
                whatShifts: nil
            ) {
                transitions.append(pratyantarTransition)
            }

            if let antarTransition = transition(
                type: .antardasha,
                currentLord: timing.antardasha?.currentLord,
                nextLord: timing.antardasha?.nextLord,
                endsOn: timing.antardasha?.endsOn,
                daysRemaining: timing.antardasha?.daysRemaining,
                whatShifts: nil
            ) {
                transitions.append(antarTransition)
            }

            let mahaWhatShifts = response.transitions?.insights?.summary
                ?? response.transitions?.impactComparison?.transitionSummary

            if let mahaTransition = transition(
                type: .mahadasha,
                currentLord: timing.mahadasha?.currentLord,
                nextLord: timing.mahadasha?.nextLord,
                endsOn: timing.mahadasha?.endsOn,
                daysRemaining: timing.mahadasha?.daysRemaining,
                whatShifts: mahaWhatShifts
            ) {
                transitions.append(mahaTransition)
            }
        }

        return transitions
            .compactMap { $0 }
            .sorted { $0.daysUntil < $1.daysUntil }
    }
}

// MARK: - Astro Utilities

private extension TimeTravelSnapshot {
    static let westernSignNames: [String] = [
        "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
        "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces",
    ]

    static func signIndex(for signName: String) -> Int? {
        let key = signName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let mapping: [String: Int] = [
            "aries": 0, "mesha": 0,
            "taurus": 1, "vrishabha": 1, "vṛṣabha": 1,
            "gemini": 2, "mithuna": 2,
            "cancer": 3, "karka": 3,
            "leo": 4, "simha": 4,
            "virgo": 5, "kanya": 5,
            "libra": 6, "tula": 6,
            "scorpio": 7, "vrischika": 7, "vrishchika": 7,
            "sagittarius": 8, "dhanu": 8,
            "capricorn": 9, "makara": 9,
            "aquarius": 10, "kumbha": 10,
            "pisces": 11, "meena": 11, "mina": 11,
        ]
        return mapping[key]
    }

    static func normalizeLongitude(_ longitude: Double) -> Double {
        let value = longitude.truncatingRemainder(dividingBy: 360)
        return value < 0 ? value + 360 : value
    }

    static func planetSymbol(for lord: String) -> String {
        let symbols: [String: String] = [
            "Sun": "☉",
            "Moon": "☽",
            "Mercury": "☿",
            "Venus": "♀",
            "Mars": "♂",
            "Jupiter": "♃",
            "Saturn": "♄",
            "Rahu": "☊",
            "Ketu": "☋",
            "Uranus": "♅",
            "Neptune": "♆",
            "Pluto": "♇",
            "Ascendant": "⟰",
        ]
        return symbols[lord] ?? "✦"
    }

    static func defaultDailySpeed(forPlanetId id: String) -> Double {
        switch id.lowercased() {
        case "sun": return 0.9856
        case "moon": return 13.176
        case "mercury": return 1.2
        case "venus": return 1.18
        case "mars": return 0.52
        case "jupiter": return 0.083
        case "saturn": return 0.034
        case "uranus": return 0.012
        case "neptune": return 0.006
        case "pluto": return 0.004
        case "rahu", "ketu": return 0.053
        default: return 0.2
        }
    }

    static func progress(_ date: Date, start: Date, end: Date) -> Double {
        guard end > start else { return 0 }
        let total = end.timeIntervalSince(start)
        let current = date.timeIntervalSince(start)
        return max(0, min(1, current / total))
    }

    static func parseDate(_ string: String) -> Date? {
        dateFormatter.date(from: string)
    }

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func titleCase(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    static func keywordTheme(from keywords: [String], fallbackLord: String) -> String {
        let phrase = keywords.prefix(3).map(titleCase).joined(separator: " • ")
        return phrase.isEmpty ? shortPlanetTheme(for: fallbackLord) : phrase
    }

    static func shortPlanetTheme(for lord: String) -> String {
        switch lord {
        case "Sun": return "Purpose • Leadership • Vitality"
        case "Moon": return "Emotions • Home • Intuition"
        case "Mars": return "Action • Courage • Drive"
        case "Mercury": return "Learning • Communication • Adaptability"
        case "Jupiter": return "Growth • Wisdom • Opportunity"
        case "Venus": return "Love • Values • Harmony"
        case "Saturn": return "Discipline • Structure • Commitment"
        case "Rahu": return "Ambition • Desire • Expansion"
        case "Ketu": return "Detachment • Insight • Release"
        default: return "Shift • Focus • Momentum"
        }
    }

    static func shiftSummary(toLord: String, type: TransitionType) -> String {
        switch type {
        case .mahadasha:
            return "A new long-term chapter begins with \(toLord) energy — \(shortPlanetTheme(for: toLord))."
        case .antardasha:
            return "Your near-term focus shifts toward \(toLord) — \(shortPlanetTheme(for: toLord))."
        case .pratyantardasha:
            return "Micro-shifts highlight \(toLord) vibrations — \(shortPlanetTheme(for: toLord))."
        }
    }

    enum ImpactArea: CaseIterable {
        case career
        case relationships
        case health
        case spiritual
    }

    static func bestImpactArea(_ scores: DashaCompleteResponse.ImpactScores) -> ImpactArea {
        let pairs: [(ImpactArea, Double)] = [
            (.career, scores.career),
            (.relationships, scores.relationships),
            (.health, scores.health),
            (.spiritual, scores.spiritual),
        ]
        return pairs.max { $0.1 < $1.1 }?.0 ?? .career
    }

    static func worstImpactArea(_ scores: DashaCompleteResponse.ImpactScores) -> ImpactArea {
        let pairs: [(ImpactArea, Double)] = [
            (.career, scores.career),
            (.relationships, scores.relationships),
            (.health, scores.health),
            (.spiritual, scores.spiritual),
        ]
        return pairs.min { $0.1 < $1.1 }?.0 ?? .health
    }

    static func opportunityLabel(for area: ImpactArea) -> String {
        switch area {
        case .career: return "Career momentum"
        case .relationships: return "Relationship openings"
        case .health: return "Health rebuild"
        case .spiritual: return "Spiritual clarity"
        }
    }

    static func riskLabel(for area: ImpactArea) -> String {
        switch area {
        case .career: return "Career pressure"
        case .relationships: return "Relationship sensitivity"
        case .health: return "Health fatigue"
        case .spiritual: return "Spiritual drift"
        }
    }

    static func expandedKeywords(maha: [String], antar: [String]) -> String? {
        let mahaLine = maha.prefix(4).map(titleCase).joined(separator: " • ")
        let antarLine = antar.prefix(4).map(titleCase).joined(separator: " • ")
        let lines = [
            mahaLine.isEmpty ? nil : "Mahadasha keywords: \(mahaLine)",
            antarLine.isEmpty ? nil : "Antardasha keywords: \(antarLine)",
        ].compactMap { $0 }
        return lines.isEmpty ? nil : lines.joined(separator: "\n")
    }
}

// MARK: - Aspect Generation

private extension TimeTravelSnapshot {
    static func generateAspects(planets: [PlanetState]) -> [ActiveAspect] {
        let aspectTypes: [AspectType] = [.conjunction, .sextile, .square, .trine, .opposition]
        let maxOrb: Double = 6.0

        func angularDistance(_ a: Double, _ b: Double) -> Double {
            let d = abs(normalizeLongitude(a) - normalizeLongitude(b))
            return min(d, 360 - d)
        }

        func orb(for type: AspectType, distance: Double) -> Double {
            abs(distance - type.angle)
        }

        func applying(p1: PlanetState, p2: PlanetState, type: AspectType) -> Bool {
            let d0 = angularDistance(p1.longitude, p2.longitude)
            let o0 = orb(for: type, distance: d0)

            let d1 = angularDistance(p1.longitude + p1.speed, p2.longitude + p2.speed)
            let o1 = orb(for: type, distance: d1)
            return o1 < o0
        }

        func significance(type: AspectType, p1: PlanetState, p2: PlanetState) -> String {
            switch type {
            case .conjunction: return "\(p1.name) and \(p2.name) blend their energies"
            case .sextile: return "\(p1.name) supports \(p2.name) with opportunity"
            case .trine: return "\(p1.name) and \(p2.name) flow with ease"
            case .square: return "\(p1.name) challenges \(p2.name) to adjust"
            case .opposition: return "\(p1.name) and \(p2.name) seek balance"
            }
        }

        var aspects: [ActiveAspect] = []

        for i in 0..<planets.count {
            for j in (i + 1)..<planets.count {
                let p1 = planets[i]
                let p2 = planets[j]
                let distance = angularDistance(p1.longitude, p2.longitude)

                var best: (type: AspectType, orb: Double)?
                for type in aspectTypes {
                    let o = orb(for: type, distance: distance)
                    if o <= maxOrb {
                        if let best, o >= best.orb { continue }
                        best = (type, o)
                    }
                }

                if let best {
                    aspects.append(
                        ActiveAspect(
                            planet1: p1.id,
                            planet2: p2.id,
                            type: best.type,
                            orb: best.orb,
                            isApplying: applying(p1: p1, p2: p2, type: best.type),
                            significance: significance(type: best.type, p1: p1, p2: p2)
                        )
                    )
                }
            }
        }

        return aspects
            .sorted { $0.orb < $1.orb }
            .prefix(6)
            .map { $0 }
    }
}

// MARK: - Seeker Feedback

extension TimeTravelSnapshot {
    static func scrubFeedback(from previous: TimeTravelSnapshot, to current: TimeTravelSnapshot) -> ScrubFeedback {
        let previousPlanets = Dictionary(uniqueKeysWithValues: previous.planets.map { ($0.id, $0) })
        let currentPlanets = Dictionary(uniqueKeysWithValues: current.planets.map { ($0.id, $0) })

        let mahaLord = current.currentDasha.mahadasha.lord
        let antarLord = current.currentDasha.antardasha.lord
        let pratyLord = current.currentDasha.pratyantardasha?.lord

        func isDashaLord(_ planet: PlanetState) -> Bool {
            planet.name == mahaLord || planet.name == antarLord || (pratyLord != nil && planet.name == pratyLord)
        }

        var insights: [ScrubInsight] = []

        // Dasha transitions (highest-salience time-travel change)
        if previous.currentDasha.pratyantardasha?.lord != current.currentDasha.pratyantardasha?.lord,
           let praty = current.currentDasha.pratyantardasha {
            insights.append(
                ScrubInsight(
                    id: "dasha-praty-\(praty.lord)",
                    tone: .review,
                    text: "Praty: \(previous.currentDasha.pratyantardasha?.lord ?? "—")→\(praty.lord)",
                    element: .dashaLord(praty.lord)
                )
            )
        }

        if previous.currentDasha.antardasha.lord != current.currentDasha.antardasha.lord {
            insights.append(
                ScrubInsight(
                    id: "dasha-antar-\(current.currentDasha.antardasha.lord)",
                    tone: .review,
                    text: "Antar: \(previous.currentDasha.antardasha.lord)→\(current.currentDasha.antardasha.lord)",
                    element: .dashaLord(current.currentDasha.antardasha.lord)
                )
            )
        }

        if previous.currentDasha.mahadasha.lord != current.currentDasha.mahadasha.lord {
            insights.append(
                ScrubInsight(
                    id: "dasha-maha-\(current.currentDasha.mahadasha.lord)",
                    tone: .review,
                    text: "Maha: \(previous.currentDasha.mahadasha.lord)→\(current.currentDasha.mahadasha.lord)",
                    element: .dashaLord(current.currentDasha.mahadasha.lord)
                )
            )
        }

        // Planet sign changes + stations
        for planet in current.planets {
            guard let prev = previousPlanets[planet.id] else { continue }

            if prev.sign != planet.sign {
                let glyph = signGlyph(forName: planet.sign)
                insights.append(
                    ScrubInsight(
                        id: "sign-\(planet.id)-\(planet.sign)",
                        tone: isDashaLord(planet) ? .supportive : .neutral,
                        text: "\(planet.symbol) → \(glyph) \(planet.sign)",
                        element: .planet(planet.id)
                    )
                )
            }

            if prev.isRetrograde != planet.isRetrograde {
                let text = planet.isRetrograde ? "\(planet.symbol) Rx (review)" : "\(planet.symbol) direct (forward)"
                insights.append(
                    ScrubInsight(
                        id: "station-\(planet.id)-\(planet.isRetrograde)",
                        tone: .review,
                        text: text,
                        element: .planet(planet.id)
                    )
                )
            }

            // House changes are user-specific (if houses are available).
            if let prevHouse = prev.house, let newHouse = planet.house, prevHouse != newHouse {
                let isPriority = isDashaLord(planet) || planet.id == "sun" || planet.id == "moon"
                if isPriority {
                    insights.append(
                        ScrubInsight(
                            id: "house-\(planet.id)-\(prevHouse)-\(newHouse)",
                            tone: isDashaLord(planet) ? .supportive : .neutral,
                            text: "\(planet.symbol) H\(prevHouse)→H\(newHouse)",
                            element: .planet(planet.id)
                        )
                    )
                }
            }
        }

        // New aspects formed (most interpretable change)
        let prevAspectKeys = Set(previous.aspects.map(aspectKey))
        let newAspects = current.aspects
            .filter { !prevAspectKeys.contains(aspectKey($0)) }
            .sorted { $0.orb < $1.orb }

        for aspect in newAspects.prefix(2) {
            guard let p1 = currentPlanets[aspect.planet1],
                  let p2 = currentPlanets[aspect.planet2] else { continue }

            let glyph = aspect.type.glyph
            let tone: ScrubInsight.Tone = aspect.type.isHarmonious ? .supportive : .challenging
            insights.append(
                ScrubInsight(
                    id: "aspect-\(aspectKey(aspect))",
                    tone: tone,
                    text: "\(p1.symbol)\(glyph)\(p2.symbol) • \(aspect.type.impactWord)",
                    element: .aspect(aspect.planet1, aspect.planet2)
                )
            )
        }

        // Fallback: show key movers so scrub always feels "informative"
        if insights.isEmpty {
            let movers = current.planets
                .compactMap { planet -> (planet: PlanetState, delta: Double)? in
                    guard let prev = previousPlanets[planet.id] else { return nil }
                    let delta = abs(currentAngularDelta(from: prev.longitude, to: planet.longitude))
                    return (planet: planet, delta: delta)
                }
                .sorted { $0.delta > $1.delta }
                .prefix(2)

            for mover in movers {
                insights.append(
                    ScrubInsight(
                        id: "move-\(mover.planet.id)-\(current.targetDate.timeIntervalSinceReferenceDate)",
                        tone: isDashaLord(mover.planet) ? .supportive : .neutral,
                        text: "\(mover.planet.symbol) +\(String(format: "%.0f", mover.delta))°",
                        element: .planet(mover.planet.id)
                    )
                )
            }
        }

        // Prioritize dasha transitions + dasha-lord-relevant insights for density.
        insights.sort { a, b in
            let aScore = insightScore(a, currentPlanets: currentPlanets, mahaLord: mahaLord, antarLord: antarLord, pratyLord: pratyLord)
            let bScore = insightScore(b, currentPlanets: currentPlanets, mahaLord: mahaLord, antarLord: antarLord, pratyLord: pratyLord)
            if aScore != bScore { return aScore > bScore }
            return a.id < b.id
        }

        let topInsights = Array(insights.prefix(4))
        let summary = generateImpactSummary(previous: previous, current: current, newAspects: newAspects) ?? "Tap a chip to highlight what changed — or tap a planet for details."

        return ScrubFeedback(insights: topInsights, summary: summary)
    }
}

private extension TimeTravelSnapshot {
    static func insightScore(
        _ insight: ScrubInsight,
        currentPlanets: [String: PlanetState],
        mahaLord: String,
        antarLord: String,
        pratyLord: String?
    ) -> Int {
        let kind: Int = {
            if insight.id.hasPrefix("dasha-") { return 1000 }
            if insight.id.hasPrefix("aspect-") { return 900 }
            if insight.id.hasPrefix("station-") { return 850 }
            if insight.id.hasPrefix("sign-") { return 800 }
            if insight.id.hasPrefix("house-") { return 750 }
            if insight.id.hasPrefix("move-") { return 100 }
            return 0
        }()

        let dashaRelevant: Bool = {
            switch insight.element {
            case .planet(let id):
                guard let p = currentPlanets[id] else { return false }
                return p.name == mahaLord || p.name == antarLord || (pratyLord != nil && p.name == pratyLord)
            case .dashaLord(let lord):
                return lord == mahaLord || lord == antarLord || (pratyLord != nil && lord == pratyLord)
            case .aspect(let p1, let p2):
                let n1 = currentPlanets[p1]?.name
                let n2 = currentPlanets[p2]?.name
                return n1 == mahaLord || n1 == antarLord || n2 == mahaLord || n2 == antarLord
                    || (pratyLord != nil && (n1 == pratyLord || n2 == pratyLord))
            case nil:
                return false
            }
        }()

        return kind + (dashaRelevant ? 50 : 0) + insight.tone.priority
    }

    static func generateImpactSummary(previous: TimeTravelSnapshot, current: TimeTravelSnapshot, newAspects: [ActiveAspect]) -> String? {
        // First: any dasha shift (chapter/phase change).
        if previous.currentDasha.mahadasha.lord != current.currentDasha.mahadasha.lord {
            return "Mahadasha shifts to \(current.currentDasha.mahadasha.lord) — a bigger chapter change with a new core energy."
        }
        if previous.currentDasha.antardasha.lord != current.currentDasha.antardasha.lord {
            return "Antardasha shifts to \(current.currentDasha.antardasha.lord) — near‑term focus changes; align with the new energy."
        }
        if previous.currentDasha.pratyantardasha?.lord != current.currentDasha.pratyantardasha?.lord,
           let praty = current.currentDasha.pratyantardasha {
            return "Pratyantardasha shifts to \(praty.lord) — short‑term frequency shifts; watch the details."
        }

        let mahaLord = current.currentDasha.mahadasha.lord
        let antarLord = current.currentDasha.antardasha.lord

        func theme(for planetName: String) -> String {
            switch planetName.lowercased() {
            case "sun": return "confidence"
            case "moon": return "emotions"
            case "mercury": return "communication"
            case "venus": return "relationships"
            case "mars": return "drive"
            case "jupiter": return "growth"
            case "saturn": return "commitments"
            case "rahu": return "desires"
            case "ketu": return "letting go"
            default: return "focus"
            }
        }

        func isDashaName(_ name: String) -> Bool {
            name == mahaLord || name == antarLord
        }

        let currentPlanets = Dictionary(uniqueKeysWithValues: current.planets.map { ($0.id, $0) })
        let previousPlanets = Dictionary(uniqueKeysWithValues: previous.planets.map { ($0.id, $0) })

        // Prefer a newly formed aspect involving a dasha lord.
        if let featured = newAspects.first(where: { aspect in
            guard let p1 = currentPlanets[aspect.planet1],
                  let p2 = currentPlanets[aspect.planet2] else { return false }
            return isDashaName(p1.name) || isDashaName(p2.name)
        }) {
            guard let p1 = currentPlanets[featured.planet1],
                  let p2 = currentPlanets[featured.planet2] else { return nil }
            let t1 = theme(for: p1.name)
            let t2 = theme(for: p2.name)
            return featured.type.isHarmonious
                ? "\(t1.capitalized) harmonizes with \(t2) — lean in and take one meaningful step."
                : "\(t1.capitalized) and \(t2) clash — slow down, simplify, and choose one priority."
        }

        // Next: house shift for Sun or dasha lords (user-specific).
        let priorityPlanetIds: [String] = ["sun", "moon"]
        for id in priorityPlanetIds {
            guard let cur = currentPlanets[id], let prev = previousPlanets[id],
                  let newHouse = cur.house, let oldHouse = prev.house, newHouse != oldHouse else { continue }
            return "\(cur.name) shifts into your \(houseLabel(newHouse)) — expect this area to feel louder."
        }

        // Next: a dasha-lord sign shift.
        for planet in current.planets {
            guard isDashaName(planet.name),
                  let prev = previousPlanets[planet.id],
                  prev.sign != planet.sign else { continue }
            return "\(theme(for: planet.name).capitalized) takes a \(signMood(forName: planet.sign)) frequency — adjust your approach this month."
        }

        // Fallback: Sun sign shift gives a readable month-level cue.
        if let sun = currentPlanets["sun"], let prevSun = previousPlanets["sun"], prevSun.sign != sun.sign {
            return "Sun takes a \(signMood(forName: sun.sign)) frequency — keep actions aligned with what matters."
        }

        return nil
    }

    static func aspectKey(_ aspect: ActiveAspect) -> String {
        let a = aspect.planet1
        let b = aspect.planet2
        let pair = a < b ? "\(a)-\(b)" : "\(b)-\(a)"
        return "\(pair)-\(aspect.type.rawValue)"
    }

    static func currentAngularDelta(from a: Double, to b: Double) -> Double {
        let na = normalizeLongitude(a)
        let nb = normalizeLongitude(b)
        var d = nb - na
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }

    static func signGlyph(forName name: String) -> String {
        let glyphs = ["♈︎", "♉︎", "♊︎", "♋︎", "♌︎", "♍︎", "♎︎", "♏︎", "♐︎", "♑︎", "♒︎", "♓︎"]
        if let idx = signIndex(for: name), let glyph = glyphs[safe: idx] { return glyph }
        return "✦"
    }

    static func signMood(forName name: String) -> String {
        let moods = [
            "bold", "steady", "curious", "protective", "expressive", "precise",
            "balanced", "intense", "expansive", "practical", "inventive", "dreamy",
        ]
        if let idx = signIndex(for: name), let mood = moods[safe: idx] { return mood }
        return "new"
    }

    static func houseLabel(_ house: Int) -> String {
        let mapping: [Int: String] = [
            1: "1st house (self)",
            2: "2nd house (money & values)",
            3: "3rd house (communication)",
            4: "4th house (home)",
            5: "5th house (creativity)",
            6: "6th house (health & routines)",
            7: "7th house (partnerships)",
            8: "8th house (transformation)",
            9: "9th house (beliefs & learning)",
            10: "10th house (career)",
            11: "11th house (gains & friends)",
            12: "12th house (rest & release)",
        ]
        return mapping[house] ?? "\(house)th house"
    }
}

private extension ScrubInsight.Tone {
    var priority: Int {
        switch self {
        case .challenging: return 3
        case .supportive: return 2
        case .review: return 1
        case .neutral: return 0
        }
    }
}

private extension AspectType {
    var glyph: String {
        switch self {
        case .conjunction: return "☌"
        case .sextile: return "⚹"
        case .square: return "□"
        case .trine: return "△"
        case .opposition: return "☍"
        }
    }

    var impactWord: String {
        switch self {
        case .conjunction: return "merge"
        case .sextile: return "open"
        case .trine: return "flow"
        case .square: return "test"
        case .opposition: return "balance"
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var sentencePrefix: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let range = trimmed.range(of: ".") {
            return String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
    }
}
