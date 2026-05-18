import Foundation

// MARK: - Journal Entry (7-row reflective format)

struct JournalEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    var whatHappened: String
    var bodyRegions: [String]
    var bodyNotes: String
    var storyCreated: String
    var patternId: String?
    var whatIDid: String
    var higherRoute: String
    var learning: String
    var moodBefore: Int?
    var moodAfter: Int?
    var linkedPauseEntryId: UUID?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        whatHappened: String = "",
        bodyRegions: [String] = [],
        bodyNotes: String = "",
        storyCreated: String = "",
        patternId: String? = nil,
        whatIDid: String = "",
        higherRoute: String = "",
        learning: String = "",
        moodBefore: Int? = nil,
        moodAfter: Int? = nil,
        linkedPauseEntryId: UUID? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.whatHappened = whatHappened
        self.bodyRegions = bodyRegions
        self.bodyNotes = bodyNotes
        self.storyCreated = storyCreated
        self.patternId = patternId
        self.whatIDid = whatIDid
        self.higherRoute = higherRoute
        self.learning = learning
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.linkedPauseEntryId = linkedPauseEntryId
    }
}

// MARK: - Decision Simulation

struct Decision: Codable, Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    var promptText: String
    var decisionClass: DecisionClass
    var timeHorizon: TimeHorizon
    var reversibility: Reversibility
    var userInclination: Inclination
    var moodAtInput: Int
    var output: DecisionOutput?

    enum DecisionClass: String, Codable, CaseIterable, Identifiable {
        case career, relationship, money, health, creative, family, other
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    enum TimeHorizon: String, Codable, CaseIterable, Identifiable {
        case hours, days, weeks, months, years
        var id: String { rawValue }
        var label: String { rawValue }
    }

    enum Reversibility: String, Codable, CaseIterable, Identifiable {
        case high, medium, low, oneWayDoor = "one_way_door"
        var id: String { rawValue }
        var label: String {
            switch self {
            case .high: return "high"
            case .medium: return "medium"
            case .low: return "low"
            case .oneWayDoor: return "one-way door"
            }
        }
    }

    enum Inclination: String, Codable, CaseIterable, Identifiable {
        case leanYes = "lean_yes", leanNo = "lean_no", unclear
        var id: String { rawValue }
        var label: String {
            switch self {
            case .leanYes: return "lean yes"
            case .leanNo: return "lean no"
            case .unclear: return "unclear"
            }
        }
    }
}

struct DecisionOutput: Codable, Hashable {
    var currentWeather: String
    var defaultPattern: String
    var risk: String
    var opportunity: String
    var bestRoute: String
    var questionToAnswer: String
    var citedPatternIds: [String]
    var citedTransitDrivers: [String]
    var generatedAt: Date
}

// MARK: - Navigation Algorithm (Personal Rules)

struct NavigationRule: Codable, Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    var text: String
    var triggerPatternId: String?
    var triggerContext: TriggerContext
    var source: Source
    var confidence: Int
    var decayReviewDate: Date?
    var timesInvoked: Int
    var timesFollowed: Int
    var timesBroken: Int
    var active: Bool

    enum TriggerContext: String, Codable, CaseIterable, Identifiable {
        case work, love, family, money, health, decision, generic
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    enum Source: String, Codable {
        case manual = "manual_entry"
        case extractedFromJournal = "extracted_from_journal"
        case suggestedByApp = "suggested_by_app"
    }

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        text: String,
        triggerPatternId: String? = nil,
        triggerContext: TriggerContext = .generic,
        source: Source = .manual,
        confidence: Int = 3,
        decayReviewDate: Date? = Date().addingTimeInterval(60 * 60 * 24 * 90),
        timesInvoked: Int = 0,
        timesFollowed: Int = 0,
        timesBroken: Int = 0,
        active: Bool = true
    ) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
        self.triggerPatternId = triggerPatternId
        self.triggerContext = triggerContext
        self.source = source
        self.confidence = confidence
        self.decayReviewDate = decayReviewDate
        self.timesInvoked = timesInvoked
        self.timesFollowed = timesFollowed
        self.timesBroken = timesBroken
        self.active = active
    }
}

// MARK: - Snapshots used by the compute engines

struct TerrainSnapshot: Hashable {
    let date: Date
    let drivers: [TerrainDriver]
    let dasha: DashaOverlay?
    let axes: TerrainAxes
    let dominantPatternId: String?
}

struct DomainSnapshot: Hashable {
    let date: Date
    let domains: [TopoDomainScore]
}

struct TopoDomainScore: Identifiable, Hashable {
    let domainId: String
    let intensity: Double  // 0..1
    let friction: Double
    let opportunity: Double
    var id: String { domainId }
    var composite: Double { (intensity + opportunity - friction).clamped(to: 0...1) }
}

struct PatternActivation: Identifiable, Hashable {
    let pattern: Pattern
    let score: Double  // 0..1
    let reasons: [String]
    var id: String { pattern.id }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
