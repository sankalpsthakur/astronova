import Foundation

// MARK: - Compatibility Snapshot
// The atomic data unit - one API call powers the entire compatibility experience.
// "Pick a person → understand our connection (now/next/act), explore why via a beautiful map"

struct CompatibilitySnapshot: Codable, Equatable {
    let pair: RelationshipPair
    let natalA: NatalPlacements
    let natalB: NatalPlacements
    let synastry: SynastryData
    let composite: CompositePlacements?
    let now: RelationshipNowInsight
    let next: NextShift
    let journey: JourneyForecast
    let share: ShareModel
}

// MARK: - Relationship Pair

struct RelationshipPair: Codable, Equatable {
    let idA: String
    let idB: String
    let nameA: String
    let nameB: String
    let avatarUrlA: String?
    let avatarUrlB: String?
    let sharedSignature: String // "Warmth + honesty, watch power dynamics"
}

// MARK: - Natal Placements

struct NatalPlacements: Codable, Equatable {
    let sun: Placement
    let moon: Placement
    let mercury: Placement
    let venus: Placement
    let mars: Placement
    let jupiter: Placement
    let saturn: Placement
    let ascendant: Placement?

    var allPlacements: [(name: String, placement: Placement)] {
        var result: [(String, Placement)] = [
            ("Sun", sun),
            ("Moon", moon),
            ("Mercury", mercury),
            ("Venus", venus),
            ("Mars", mars),
            ("Jupiter", jupiter),
            ("Saturn", saturn)
        ]
        if let asc = ascendant {
            result.append(("Ascendant", asc))
        }
        return result
    }
}

struct Placement: Codable, Equatable {
    let sign: String
    let degree: Double
    let longitude: Double
    let house: Int?

    var formattedDegree: String {
        let wholeDegree = Int(degree)
        let minutes = Int((degree - Double(wholeDegree)) * 60)
        return "\(wholeDegree)°\(minutes)'"
    }

    var signGlyph: String {
        ZodiacSign(rawValue: sign)?.glyph ?? "?"
    }
}

// MARK: - Synastry Data

struct SynastryData: Codable, Equatable {
    let topAspects: [SynastryAspect]
    let domainBreakdown: [DomainScore]
    let overallScore: Int

    var harmonousAspects: [SynastryAspect] {
        topAspects.filter { $0.isHarmonious }
    }

    var challengingAspects: [SynastryAspect] {
        topAspects.filter { !$0.isHarmonious }
    }

    var activatedAspects: [SynastryAspect] {
        topAspects.filter { $0.isActivatedNow }
    }
}

struct SynastryAspect: Codable, Equatable, Identifiable {
    let planetA: String
    let planetB: String
    let aspectType: SynastryAspectKind
    let orb: Double
    let strength: Double      // 0.0-1.0
    let isHarmonious: Bool
    let isActivatedNow: Bool
    let interpretation: AspectInterpretation

    var id: String { "\(planetA)-\(aspectType.rawValue)-\(planetB)" }

    var planetAGlyph: String {
        Planet(rawValue: planetA)?.glyph ?? planetA.prefix(2).uppercased()
    }

    var planetBGlyph: String {
        Planet(rawValue: planetB)?.glyph ?? planetB.prefix(2).uppercased()
    }

    var aspectGlyph: String {
        aspectType.glyph
    }

    var description: String {
        "\(planetA) \(aspectType.rawValue) \(planetB)"
    }
}

enum SynastryAspectKind: String, Codable, CaseIterable {
    case conjunction
    case sextile
    case square
    case trine
    case opposition

    var glyph: String {
        switch self {
        case .conjunction: return "☌"
        case .sextile: return "⚹"
        case .square: return "□"
        case .trine: return "△"
        case .opposition: return "☍"
        }
    }

    var isHarmonious: Bool {
        switch self {
        case .conjunction: return true // Generally, depends on planets
        case .sextile: return true
        case .trine: return true
        case .square: return false
        case .opposition: return false
        }
    }

    var angle: Double {
        switch self {
        case .conjunction: return 0
        case .sextile: return 60
        case .square: return 90
        case .trine: return 120
        case .opposition: return 180
        }
    }
}

struct AspectInterpretation: Codable, Equatable {
    let title: String
    let oneLiner: String
    let deepDive: String
    let suggestedAction: String
    let avoidAction: String
}

// MARK: - Domain

enum Domain: String, Codable, CaseIterable {
    case identity = "Identity"
    case emotion = "Emotion"
    case communication = "Communication"
    case love = "Love"
    case desire = "Desire"
    case growth = "Growth"
    case commitment = "Commitment"

    var icon: String {
        switch self {
        case .identity: return "sun.max.fill"
        case .emotion: return "moon.fill"
        case .communication: return "bubble.left.and.bubble.right.fill"
        case .love: return "heart.fill"
        case .desire: return "flame.fill"
        case .growth: return "arrow.up.right"
        case .commitment: return "link"
        }
    }

    var planet: Planet {
        switch self {
        case .identity: return .sun
        case .emotion: return .moon
        case .communication: return .mercury
        case .love: return .venus
        case .desire: return .mars
        case .growth: return .jupiter
        case .commitment: return .saturn
        }
    }
}

struct DomainScore: Codable, Equatable, Identifiable {
    let domain: Domain
    let score: Int
    let signA: String
    let signB: String
    let aspectsInDomain: [String]

    var id: String { domain.rawValue }
}

// MARK: - Now Insight

struct RelationshipNowInsight: Codable, Equatable {
    let pulse: RelationshipPulse
    let sharedInsight: SharedInsight
}

struct RelationshipPulse: Codable, Equatable, Hashable {
    let state: PulseState
    let score: Int
    let label: String
    let topActivations: [String]
}

enum PulseState: String, Codable {
    case flowing      // Resonant - frequencies in harmony
    case electric     // High frequency - amplified energy
    case grounded     // Stable vibration - steady frequency
    case friction     // Dissonant - frequencies clashing
    case magnetic     // Attracted - strong pull energy

    var color: String {
        switch self {
        case .flowing: return "cosmicTeal"
        case .electric: return "cosmicGold"
        case .grounded: return "cosmicEarth"
        case .friction: return "cosmicRose"
        case .magnetic: return "cosmicPurple"
        }
    }

    var icon: String {
        switch self {
        case .flowing: return "waveform.path"
        case .electric: return "bolt.fill"
        case .grounded: return "waveform"
        case .friction: return "waveform.path.ecg"
        case .magnetic: return "antenna.radiowaves.left.and.right"
        }
    }

    /// User-friendly label for the energy state
    var frequencyLabel: String {
        switch self {
        case .flowing: return "Resonant"
        case .electric: return "High Frequency"
        case .grounded: return "Stable Vibration"
        case .friction: return "Dissonant"
        case .magnetic: return "Amplified"
        }
    }

    /// Description of the vibrational state
    var vibrationDescription: String {
        switch self {
        case .flowing: return "Your energies are vibrating in harmony"
        case .electric: return "High-frequency connection amplifying your bond"
        case .grounded: return "Steady, stable vibration between you"
        case .friction: return "Frequencies temporarily out of sync"
        case .magnetic: return "Strong vibrational pull drawing you together"
        }
    }

    var animationStyle: PulseAnimationStyle {
        switch self {
        case .flowing: return .smooth
        case .electric: return .rapid
        case .grounded: return .slow
        case .friction: return .erratic
        case .magnetic: return .pulsing
        }
    }
}

enum PulseAnimationStyle {
    case smooth   // Gentle sine wave
    case rapid    // Fast oscillation
    case slow     // Slow breathing
    case erratic  // Irregular peaks
    case pulsing  // Strong beats
}

struct SharedInsight: Codable, Equatable {
    let title: String
    let sentence: String
    let suggestedAction: String
    let avoidAction: String
    let whyExpanded: String
    let linkedAspectIds: [String]
}

// MARK: - Next Shift

struct NextShift: Codable, Equatable {
    let date: Date
    let daysUntil: Int
    let whatChanges: String
    let newState: PulseState
    let planForIt: String
}

// MARK: - Journey Forecast

struct JourneyForecast: Codable, Equatable {
    let dailyMarkers: [DayMarker]
    let peakWindows: [PeakWindow]
}

struct DayMarker: Codable, Equatable, Identifiable {
    let date: Date
    let intensity: DayIntensity
    let reason: String?

    var id: Date { date }
}

enum DayIntensity: String, Codable {
    case peak
    case elevated
    case neutral
    case challenging
    case quiet

    var color: String {
        switch self {
        case .peak: return "cosmicGold"
        case .elevated: return "cosmicTeal"
        case .neutral: return "cosmicMuted"
        case .challenging: return "cosmicRose"
        case .quiet: return "cosmicDim"
        }
    }

    var height: CGFloat {
        switch self {
        case .peak: return 1.0
        case .elevated: return 0.75
        case .neutral: return 0.5
        case .challenging: return 0.6
        case .quiet: return 0.25
        }
    }
}

struct PeakWindow: Codable, Equatable, Identifiable {
    let startDate: Date
    let endDate: Date
    let label: String
    let suggestion: String

    var id: Date { startDate }
}

// MARK: - Share Model

struct ShareModel: Codable, Equatable {
    let cardTitle: String
    let cardSentence: String
    let cardAction: String
    let cardAvoid: String
    let highlightedAspectId: String?
    let deepLinkToken: String
}

// MARK: - Composite Placements

struct CompositePlacements: Codable, Equatable {
    let sun: Placement
    let moon: Placement
    let venus: Placement
    let mars: Placement
    let ascendant: Placement?
}

// MARK: - Supporting Enums

enum Planet: String, Codable, CaseIterable {
    case sun = "Sun"
    case moon = "Moon"
    case mercury = "Mercury"
    case venus = "Venus"
    case mars = "Mars"
    case jupiter = "Jupiter"
    case saturn = "Saturn"
    case uranus = "Uranus"
    case neptune = "Neptune"
    case pluto = "Pluto"
    case ascendant = "Ascendant"

    var glyph: String {
        switch self {
        case .sun: return "☉"
        case .moon: return "☽"
        case .mercury: return "☿"
        case .venus: return "♀"
        case .mars: return "♂"
        case .jupiter: return "♃"
        case .saturn: return "♄"
        case .uranus: return "♅"
        case .neptune: return "♆"
        case .pluto: return "♇"
        case .ascendant: return "AC"
        }
    }

    var orbitRadius: CGFloat {
        switch self {
        case .sun: return 0.15
        case .moon: return 0.25
        case .mercury: return 0.35
        case .venus: return 0.45
        case .mars: return 0.55
        case .jupiter: return 0.65
        case .saturn: return 0.75
        case .uranus: return 0.82
        case .neptune: return 0.88
        case .pluto: return 0.94
        case .ascendant: return 1.0
        }
    }
}

enum ZodiacSign: String, Codable, CaseIterable {
    case Aries, Taurus, Gemini, Cancer, Leo, Virgo
    case Libra, Scorpio, Sagittarius, Capricorn, Aquarius, Pisces

    var glyph: String {
        switch self {
        case .Aries: return "♈"
        case .Taurus: return "♉"
        case .Gemini: return "♊"
        case .Cancer: return "♋"
        case .Leo: return "♌"
        case .Virgo: return "♍"
        case .Libra: return "♎"
        case .Scorpio: return "♏"
        case .Sagittarius: return "♐"
        case .Capricorn: return "♑"
        case .Aquarius: return "♒"
        case .Pisces: return "♓"
        }
    }

    var element: Element {
        switch self {
        case .Aries, .Leo, .Sagittarius: return .fire
        case .Taurus, .Virgo, .Capricorn: return .earth
        case .Gemini, .Libra, .Aquarius: return .air
        case .Cancer, .Scorpio, .Pisces: return .water
        }
    }

    var startDegree: Double {
        Double(ZodiacSign.allCases.firstIndex(of: self)! * 30)
    }
}

enum Element: String, Codable {
    case fire, earth, air, water

    var color: String {
        switch self {
        case .fire: return "cosmicFire"
        case .earth: return "cosmicEarth"
        case .air: return "cosmicAir"
        case .water: return "cosmicWater"
        }
    }
}

// MARK: - Relationship Profile (for Connect list)

struct RelationshipProfile: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let avatarUrl: String?
    let sunSign: String
    let moonSign: String
    let risingSign: String?
    let birthDate: Date
    let sharedSignature: String?
    let lastPulse: RelationshipPulse?
    let lastViewed: Date?

    var signSummary: String {
        if let rising = risingSign {
            return "☉\(sunSign) ☽\(moonSign) ↑\(rising)"
        }
        return "☉\(sunSign) ☽\(moonSign)"
    }
}

// MARK: - Mock Data for Development

extension CompatibilitySnapshot {
    static var mock: CompatibilitySnapshot {
        CompatibilitySnapshot(
            pair: RelationshipPair(
                idA: "user-1",
                idB: "partner-1",
                nameA: "Sankalp",
                nameB: "Niharika",
                avatarUrlA: nil,
                avatarUrlB: nil,
                sharedSignature: "Warmth + honesty, watch power dynamics"
            ),
            natalA: .mockA,
            natalB: .mockB,
            synastry: .mock,
            composite: .mock,
            now: .mock,
            next: .mock,
            journey: .mock,
            share: .mock
        )
    }
}

extension NatalPlacements {
    static var mockA: NatalPlacements {
        NatalPlacements(
            sun: Placement(sign: "Taurus", degree: 15.5, longitude: 45.5, house: 1),
            moon: Placement(sign: "Cancer", degree: 22.3, longitude: 112.3, house: 3),
            mercury: Placement(sign: "Aries", degree: 8.7, longitude: 8.7, house: 12),
            venus: Placement(sign: "Gemini", degree: 3.2, longitude: 63.2, house: 2),
            mars: Placement(sign: "Virgo", degree: 19.8, longitude: 169.8, house: 5),
            jupiter: Placement(sign: "Aquarius", degree: 27.1, longitude: 327.1, house: 10),
            saturn: Placement(sign: "Aries", degree: 11.4, longitude: 11.4, house: 12),
            ascendant: Placement(sign: "Gemini", degree: 5.0, longitude: 65.0, house: nil)
        )
    }

    static var mockB: NatalPlacements {
        NatalPlacements(
            sun: Placement(sign: "Capricorn", degree: 25.2, longitude: 295.2, house: 7),
            moon: Placement(sign: "Cancer", degree: 18.9, longitude: 108.9, house: 1),
            mercury: Placement(sign: "Sagittarius", degree: 12.4, longitude: 252.4, house: 6),
            venus: Placement(sign: "Scorpio", degree: 7.8, longitude: 217.8, house: 5),
            mars: Placement(sign: "Leo", degree: 23.1, longitude: 143.1, house: 2),
            jupiter: Placement(sign: "Aries", degree: 14.6, longitude: 14.6, house: 10),
            saturn: Placement(sign: "Capricorn", degree: 29.3, longitude: 299.3, house: 7),
            ascendant: Placement(sign: "Cancer", degree: 12.0, longitude: 102.0, house: nil)
        )
    }
}

extension SynastryData {
    static var mock: SynastryData {
        SynastryData(
            topAspects: [
                SynastryAspect(
                    planetA: "Sun",
                    planetB: "Moon",
                    aspectType: .trine,
                    orb: 3.4,
                    strength: 0.92,
                    isHarmonious: true,
                    isActivatedNow: true,
                    interpretation: AspectInterpretation(
                        title: "Soul Recognition",
                        oneLiner: "You see each other clearly and feel understood",
                        deepDive: "This is one of the most harmonious aspects in synastry. Your conscious self (Sun) naturally flows with their emotional nature (Moon), creating a sense of mutual understanding.",
                        suggestedAction: "Share your true feelings openly this week",
                        avoidAction: "Don't assume you know what they're thinking"
                    )
                ),
                SynastryAspect(
                    planetA: "Venus",
                    planetB: "Mars",
                    aspectType: .conjunction,
                    orb: 1.2,
                    strength: 0.95,
                    isHarmonious: true,
                    isActivatedNow: true,
                    interpretation: AspectInterpretation(
                        title: "Magnetic Attraction",
                        oneLiner: "Powerful chemistry draws you together",
                        deepDive: "Venus-Mars conjunction is the classic indicator of physical and romantic attraction. This creates an almost magnetic pull between you.",
                        suggestedAction: "Plan a romantic evening together",
                        avoidAction: "Don't let passion override important conversations"
                    )
                ),
                SynastryAspect(
                    planetA: "Mercury",
                    planetB: "Mercury",
                    aspectType: .square,
                    orb: 4.3,
                    strength: 0.68,
                    isHarmonious: false,
                    isActivatedNow: false,
                    interpretation: AspectInterpretation(
                        title: "Different Wavelengths",
                        oneLiner: "Your communication styles may clash",
                        deepDive: "Mercury square Mercury can create misunderstandings. You may process information differently or have conflicting communication rhythms.",
                        suggestedAction: "Practice active listening and ask clarifying questions",
                        avoidAction: "Don't send important messages when frustrated"
                    )
                ),
                SynastryAspect(
                    planetA: "Moon",
                    planetB: "Moon",
                    aspectType: .conjunction,
                    orb: 3.4,
                    strength: 0.88,
                    isHarmonious: true,
                    isActivatedNow: false,
                    interpretation: AspectInterpretation(
                        title: "Emotional Twins",
                        oneLiner: "You feel each other's moods intuitively",
                        deepDive: "Moon conjunct Moon creates deep emotional resonance. You instinctively understand each other's needs and moods.",
                        suggestedAction: "Create a cozy ritual together",
                        avoidAction: "Don't absorb each other's bad moods"
                    )
                ),
                SynastryAspect(
                    planetA: "Saturn",
                    planetB: "Sun",
                    aspectType: .opposition,
                    orb: 2.1,
                    strength: 0.75,
                    isHarmonious: false,
                    isActivatedNow: false,
                    interpretation: AspectInterpretation(
                        title: "The Teacher Dynamic",
                        oneLiner: "One may feel restricted by the other",
                        deepDive: "Saturn opposite Sun can create a dynamic where one person feels judged or limited. This aspect requires conscious work to avoid power imbalances.",
                        suggestedAction: "Acknowledge each other's growth openly",
                        avoidAction: "Don't criticize their core identity"
                    )
                )
            ],
            domainBreakdown: [
                DomainScore(domain: .identity, score: 72, signA: "Taurus", signB: "Capricorn", aspectsInDomain: ["Sun-trine-Moon"]),
                DomainScore(domain: .emotion, score: 88, signA: "Cancer", signB: "Cancer", aspectsInDomain: ["Moon-conjunction-Moon"]),
                DomainScore(domain: .communication, score: 58, signA: "Aries", signB: "Sagittarius", aspectsInDomain: ["Mercury-square-Mercury"]),
                DomainScore(domain: .love, score: 85, signA: "Gemini", signB: "Scorpio", aspectsInDomain: ["Venus-conjunction-Mars"]),
                DomainScore(domain: .desire, score: 91, signA: "Virgo", signB: "Leo", aspectsInDomain: ["Venus-conjunction-Mars"]),
                DomainScore(domain: .growth, score: 76, signA: "Aquarius", signB: "Aries", aspectsInDomain: []),
                DomainScore(domain: .commitment, score: 65, signA: "Aries", signB: "Capricorn", aspectsInDomain: ["Saturn-opposition-Sun"])
            ],
            overallScore: 78
        )
    }
}

extension CompositePlacements {
    static var mock: CompositePlacements {
        CompositePlacements(
            sun: Placement(sign: "Pisces", degree: 5.3, longitude: 335.3, house: 4),
            moon: Placement(sign: "Cancer", degree: 20.6, longitude: 110.6, house: 8),
            venus: Placement(sign: "Capricorn", degree: 20.5, longitude: 290.5, house: 2),
            mars: Placement(sign: "Virgo", degree: 6.4, longitude: 156.4, house: 10),
            ascendant: Placement(sign: "Scorpio", degree: 8.5, longitude: 218.5, house: nil)
        )
    }
}

extension RelationshipNowInsight {
    static var mock: RelationshipNowInsight {
        RelationshipNowInsight(
            pulse: RelationshipPulse(
                state: .flowing,
                score: 78,
                label: "Flowing",
                topActivations: ["Venus trine Moon activated", "Mercury enters harmony"]
            ),
            sharedInsight: SharedInsight(
                title: "Clear communication window",
                sentence: "Your Mercurys are finding common ground this week. Conversations that felt stuck may suddenly flow.",
                suggestedAction: "Have that talk you've been postponing",
                avoidAction: "Don't bring up old grievances",
                whyExpanded: "Transiting Mercury is activating your composite Venus, creating a window for heartfelt communication. This aspect lasts until December 26th.",
                linkedAspectIds: ["Mercury-square-Mercury", "Venus-conjunction-Mars"]
            )
        )
    }
}

extension NextShift {
    static var mock: NextShift {
        NextShift(
            date: Calendar.current.date(byAdding: .day, value: 12, to: Date())!,
            daysUntil: 12,
            whatChanges: "Mars enters friction with your composite Venus",
            newState: .friction,
            planForIt: "Good week to resolve lingering tensions before they escalate"
        )
    }
}

extension JourneyForecast {
    static var mock: JourneyForecast {
        let today = Date()
        let calendar = Calendar.current

        return JourneyForecast(
            dailyMarkers: (0..<30).map { dayOffset in
                let date = calendar.date(byAdding: .day, value: dayOffset, to: today)!
                let intensity: DayIntensity
                switch dayOffset % 7 {
                case 0, 1: intensity = .peak
                case 2, 3: intensity = .elevated
                case 4: intensity = .neutral
                case 5: intensity = .challenging
                default: intensity = .quiet
                }
                return DayMarker(
                    date: date,
                    intensity: intensity,
                    reason: intensity == .peak ? "Venus activation" : nil
                )
            },
            peakWindows: [
                PeakWindow(
                    startDate: calendar.date(byAdding: .day, value: 3, to: today)!,
                    endDate: calendar.date(byAdding: .day, value: 7, to: today)!,
                    label: "Harmony window",
                    suggestion: "Great for important conversations or romantic plans"
                ),
                PeakWindow(
                    startDate: calendar.date(byAdding: .day, value: 18, to: today)!,
                    endDate: calendar.date(byAdding: .day, value: 22, to: today)!,
                    label: "Connection peak",
                    suggestion: "Ideal for deepening emotional bonds"
                )
            ]
        )
    }
}

extension ShareModel {
    static var mock: ShareModel {
        ShareModel(
            cardTitle: "Today's Theme",
            cardSentence: "Clear communication window opens. Conversations that felt stuck may suddenly flow.",
            cardAction: "Have that talk you've been postponing",
            cardAvoid: "Don't bring up old grievances",
            highlightedAspectId: "Mercury-square-Mercury",
            deepLinkToken: "abc123xyz"
        )
    }
}
