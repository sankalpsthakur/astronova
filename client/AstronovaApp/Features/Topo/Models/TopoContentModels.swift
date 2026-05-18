import Foundation

// MARK: - Pattern Library

struct PatternBundle: Decodable {
    let version: Int
    let patterns: [Pattern]
}

struct Pattern: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let activationLevel: ActivationLevel
    let summary: String
    let westernDrivers: [Driver]
    let vedicDrivers: [Driver]
    let detectionCues: [String]
    let loop: PatternLoop
    let bodySignature: [String]
    let activationScoreInputs: [String]

    enum ActivationLevel: String, Decodable {
        case high, medium, low
    }

    struct Driver: Decodable, Hashable {
        let planet: String?
        let graha: String?
        let house: Int?
        let bhava: Int?
        let dashaLord: String?
        let role: String

        enum CodingKeys: String, CodingKey {
            case planet, graha, house, bhava, role
            case dashaLord = "dasha_lord"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, summary, loop
        case activationLevel = "activation_level"
        case westernDrivers = "western_drivers"
        case vedicDrivers = "vedic_drivers"
        case detectionCues = "detection_cues"
        case bodySignature = "body_signature"
        case activationScoreInputs = "activation_score_inputs"
    }

    static func == (lhs: Pattern, rhs: Pattern) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct PatternLoop: Decodable, Hashable {
    let stimulus: String
    let defaultScript: String
    let hiddenNeed: String
    let lowConsciousnessOutput: String
    let highConsciousnessRoute: String
    let optimalAction: String

    enum CodingKeys: String, CodingKey {
        case stimulus
        case defaultScript = "default_script"
        case hiddenNeed = "hidden_need"
        case lowConsciousnessOutput = "low_consciousness_output"
        case highConsciousnessRoute = "high_consciousness_route"
        case optimalAction = "optimal_action"
    }
}

// MARK: - Consciousness Levels

struct ConsciousnessBundle: Decodable {
    let version: Int
    let planets: [ConsciousnessPlanet]
}

struct ConsciousnessPlanet: Decodable, Identifiable, Hashable {
    let id: String
    let westernName: String
    let vedicName: String?
    let westernTheme: String
    let vedicTheme: String?
    let levels: [ConsciousnessLevel]
    let growthEdge2to3: String?
    let growthEdge3to4: String?
    let regressionTrigger: String?

    enum CodingKeys: String, CodingKey {
        case id, levels
        case westernName = "western_name"
        case vedicName = "vedic_name"
        case westernTheme = "western_theme"
        case vedicTheme = "vedic_theme"
        case growthEdge2to3 = "growth_edge_2_to_3"
        case growthEdge3to4 = "growth_edge_3_to_4"
        case regressionTrigger = "regression_trigger"
    }

    static func == (lhs: ConsciousnessPlanet, rhs: ConsciousnessPlanet) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct ConsciousnessLevel: Decodable, Identifiable, Hashable {
    let level: Int
    let name: String
    let keywords: [String]
    let bodyCue: String
    let behavior: String

    var id: Int { level }

    enum CodingKeys: String, CodingKey {
        case level, name, keywords, behavior
        case bodyCue = "body_cue"
    }
}

// MARK: - Terrain Templates

struct TerrainBundle: Decodable {
    let version: Int
    let drivers: [TerrainDriver]
    let dashaOverlays: [DashaOverlay]
    let patternActivationHints: [PatternActivationHint]
    let toneRules: [String]

    enum CodingKeys: String, CodingKey {
        case version, drivers
        case dashaOverlays = "dasha_overlays"
        case patternActivationHints = "pattern_activation_hints"
        case toneRules = "tone_rules"
    }
}

struct TerrainDriver: Decodable, Identifiable, Hashable {
    let id: String
    let label: String
    let vedicOverlay: String?
    let axes: TerrainAxes

    enum CodingKeys: String, CodingKey {
        case id, label, axes
        case vedicOverlay = "vedic_overlay"
    }
}

struct TerrainAxes: Decodable, Hashable {
    let currentWeather: String
    let mostLikelyDefault: String
    let highestAgencyMove: String
    let bestUse: String
    let avoid: String

    enum CodingKeys: String, CodingKey {
        case currentWeather = "current_weather"
        case mostLikelyDefault = "most_likely_default"
        case highestAgencyMove = "highest_agency_move"
        case bestUse = "best_use"
        case avoid = "avoid"
    }
}

struct DashaOverlay: Decodable, Identifiable, Hashable {
    let graha: String
    let context: String
    var id: String { graha }
}

struct PatternActivationHint: Decodable, Hashable {
    let patternId: String
    let transitSignature: String

    enum CodingKeys: String, CodingKey {
        case patternId = "pattern_id"
        case transitSignature = "transit_signature"
    }
}

// MARK: - Domain Mappings

struct DomainBundle: Decodable {
    let version: Int
    let domains: [DomainMapping]
}

struct DomainMapping: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let tagline: String
    let terrainMetaphor: String
    let iconSfSymbol: String
    let colorHint: String
    let westernFactors: [DomainFactor]
    let vedicFactors: [DomainFactor]
    let intensityHighSignature: String
    let frictionSignature: String
    let opportunitySignature: String
    let associatedPatterns: [String]

    enum CodingKeys: String, CodingKey {
        case id, name, tagline
        case terrainMetaphor = "terrain_metaphor"
        case iconSfSymbol = "icon_sf_symbol"
        case colorHint = "color_hint"
        case westernFactors = "western_factors"
        case vedicFactors = "vedic_factors"
        case intensityHighSignature = "intensity_high_signature"
        case frictionSignature = "friction_signature"
        case opportunitySignature = "opportunity_signature"
        case associatedPatterns = "associated_patterns"
    }

    static func == (lhs: DomainMapping, rhs: DomainMapping) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct DomainFactor: Decodable, Hashable {
    let factor: String
    let weight: Double
}
