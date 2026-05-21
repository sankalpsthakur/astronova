import Foundation

/// Deterministic stub compute engines. v1 returns plausible results so the UI can ship.
/// v2 will pull real transits + dasha + natal chart features from the existing astrology
/// backend (`ephemeris_service.py` + dasha service) and replace these implementations.

final class PatternMatcher {
    static let shared = PatternMatcher()

    /// Returns the top-N patterns ranked by activation, weighted by the day-of-week
    /// (deterministic but varies) so the UI feels alive until the real chart-aware
    /// matcher lands. v2 will compute from natal chart + transits + dasha.
    func topActive(limit: Int = 3, date: Date = Date()) -> [PatternActivation] {
        let patterns = TopoContentLoader.shared.patterns
        guard !patterns.isEmpty else { return [] }

        let day = (Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1)
        return patterns.map { pattern in
            let baseScore: Double
            switch pattern.activationLevel {
            case .high:   baseScore = 0.7
            case .medium: baseScore = 0.5
            case .low:    baseScore = 0.3
            }
            // Add a deterministic per-day jitter so different days surface different orderings.
            let jitter = Double((day &+ pattern.id.hashValue) % 30) / 100.0
            let score = min(1.0, baseScore + jitter)
            let reasons = Array(pattern.activationScoreInputs.prefix(2))
            return PatternActivation(pattern: pattern, score: score, reasons: reasons)
        }
        .sorted { $0.score > $1.score }
        .prefix(limit)
        .map { $0 }
    }

    func activation(for patternId: String, date: Date = Date()) -> PatternActivation? {
        topActive(limit: TopoContentLoader.shared.patterns.count, date: date)
            .first { $0.pattern.id == patternId }
    }
}

final class TerrainComputer {
    static let shared = TerrainComputer()

    /// Computes today's terrain by picking the highest-relevance driver for the day
    /// and filling its `{var}` placeholders with reasonable defaults. v2 wires to live
    /// transits + dasha service.
    func todaysTerrain(date: Date = Date()) -> TerrainSnapshot {
        let loader = TopoContentLoader.shared
        guard let bundle = loader.terrain, !bundle.drivers.isEmpty else {
            return TerrainSnapshot(
                date: date,
                drivers: [],
                dasha: nil,
                axes: TerrainAxes(
                    currentWeather: "Conditions normal.",
                    mostLikelyDefault: "Run your usual scripts.",
                    highestAgencyMove: "Pick the one thing that matters and start.",
                    bestUse: "Steady execution.",
                    avoid: "Multitasking that fragments attention."
                ),
                dominantPatternId: nil
            )
        }

        let day = (Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1)
        let primaryIndex = day % bundle.drivers.count
        let primary = bundle.drivers[primaryIndex]
        let secondaryIndex = (day + 3) % bundle.drivers.count
        let secondary = bundle.drivers[secondaryIndex]
        // Preserve primary-first order while still deduping if both indices collide.
        // (Set-based dedupe lost ordering, causing the Today subtitle to flicker.)
        let drivers: [TerrainDriver] = (primary.id == secondary.id) ? [primary] : [primary, secondary]

        let dasha = bundle.dashaOverlays[(day) % max(1, bundle.dashaOverlays.count)]

        let axes = TerrainAxes(
            currentWeather: substitute(primary.axes.currentWeather, dashaLord: dasha.graha),
            mostLikelyDefault: substitute(primary.axes.mostLikelyDefault, dashaLord: dasha.graha),
            highestAgencyMove: substitute(primary.axes.highestAgencyMove, dashaLord: dasha.graha),
            bestUse: substitute(primary.axes.bestUse, dashaLord: dasha.graha),
            avoid: substitute(primary.axes.avoid, dashaLord: dasha.graha)
        )

        let dominantHint = bundle.patternActivationHints
            .sorted { $0.patternId.hashValue < $1.patternId.hashValue }[day % max(1, bundle.patternActivationHints.count)]

        return TerrainSnapshot(
            date: date,
            drivers: drivers,
            dasha: dasha,
            axes: axes,
            dominantPatternId: dominantHint.patternId
        )
    }

    /// Replace `{var}` placeholders in terrain templates with deterministic, plausible
    /// values until the v2 chart-aware engine lands. Any token not handled explicitly
    /// is stripped by the final regex pass so raw `{...}` never leaks to the UI.
    private func substitute(_ template: String, dashaLord: String, date: Date = Date()) -> String {
        let cal = Calendar.current
        let day = cal.ordinality(of: .day, in: .year, for: date) ?? 1

        // Moon void-of-course end: pick a believable time-of-day that is always
        // in the user's *future*, regardless of when they open the app. The
        // earlier implementation chose 14:00–21:00 for every day, so a user
        // checking the app at 22:00 would see "Moon void until 19:27" — already
        // in the past, which destroys trust.
        //
        // v1 (here): land 4-8 hours after the user opens the app, snapped to
        //            the next quarter hour. Deterministic-by-day so two reads
        //            on the same calendar day show the same time.
        // v2 (TODO): swap for /api/v1/ephemeris/topo-substitutions which will
        //            compute the actual moon sign-change time from Swiss
        //            Ephemeris and return it server-side.
        let hoursAhead = 4 + (day % 5)                 // 4–8 hour window
        let voidEndDate = cal.date(byAdding: .hour, value: hoursAhead, to: date) ?? date
        let snappedMinute = (cal.component(.minute, from: voidEndDate) / 15) * 15
        let snapped = cal.date(bySetting: .minute, value: snappedMinute, of: voidEndDate) ?? voidEndDate
        let voidFormatter = DateFormatter()
        voidFormatter.dateFormat = "h:mm a"     // 7:30 PM
        voidFormatter.locale = Locale.current
        let voidEndTime = voidFormatter.string(from: snapped)

        // Pick a deterministic aspect for the day.
        let aspectTable: [(type: String, angle: String)] = [
            ("conjunction", "0°"),
            ("sextile", "60°"),
            ("square", "90°"),
            ("trine", "120°"),
            ("opposition", "180°")
        ]
        let aspect = aspectTable[day % aspectTable.count]

        // Distance (in days) to the next eclipse — clamped to a believable range.
        // TODO(v2): pull from server-side ephemeris service which can compute
        // the actual next solar/lunar eclipse date from Swiss Ephemeris.
        let eclipseDistanceDays = String(((day * 11) % 27) + 3)  // 3–29 days

        var out = template
            .replacingOccurrences(of: "{dasha_lord}", with: dashaLord)
            .replacingOccurrences(of: "{antardasha_lord}", with: dashaLord)
            .replacingOccurrences(of: "{house}", with: "10H")
            .replacingOccurrences(of: "{aspect_partner}", with: "Saturn")
            .replacingOccurrences(of: "{retrograde_planet}", with: dashaLord)
            .replacingOccurrences(of: "{void_end_time}", with: voidEndTime)
            .replacingOccurrences(of: "{aspect_type}", with: aspect.type)
            .replacingOccurrences(of: "{aspect_angle}", with: aspect.angle)
            .replacingOccurrences(of: "{eclipse_distance_days}", with: eclipseDistanceDays)

        // Defensive sweep: never let an unhandled `{token}` reach the UI.
        // Replace with a tasteful neutral noun so the sentence remains readable.
        if out.range(of: #"\{[a-z_]+\}"#, options: .regularExpression) != nil {
            out = out.replacingOccurrences(
                of: #"\{[a-z_]+\}"#,
                with: "now",
                options: .regularExpression
            )
        }
        // Collapse any whitespace double-spaces left after substitution.
        out = out.replacingOccurrences(of: "  ", with: " ")
        return out
    }
}

final class TopoDomainScorer {
    static let shared = TopoDomainScorer()

    /// Returns a deterministic score per domain. Future v2 reads the user's
    /// computed chart features. Today: domain hash + day-of-year jitter.
    func snapshot(date: Date = Date()) -> DomainSnapshot {
        let domains = TopoContentLoader.shared.domains
        let day = (Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1)
        let year = Calendar.current.component(.year, from: date)
        let seed = (day &+ year)

        let scores = domains.map { domain -> TopoDomainScore in
            let hash = abs(domain.id.hashValue)
            let intensity = Self.norm(hash &+ seed, salt: 1)
            let friction = Self.norm(hash &+ seed, salt: 2) * 0.7
            let opportunity = Self.norm(hash &+ seed, salt: 3)
            return TopoDomainScore(
                domainId: domain.id,
                intensity: intensity,
                friction: friction,
                opportunity: opportunity
            )
        }
        return DomainSnapshot(date: date, domains: scores)
    }

    private static func norm(_ value: Int, salt: Int) -> Double {
        let mixed = (abs(value) &* 2654435761) &+ (salt &* 1597334677)
        return Double(abs(mixed) % 100) / 100.0
    }
}

final class DecisionEngine {
    static let shared = DecisionEngine()

    /// Produces a 6-axis decision output by combining current terrain + top patterns.
    /// v2 will weight the user's NavigationRules and recent journal entries too.
    @MainActor
    func simulate(_ decision: Decision) -> DecisionOutput {
        let terrain = TerrainComputer.shared.todaysTerrain()
        let topPatterns = PatternMatcher.shared.topActive(limit: 3)
        let activeRules = NavigationRuleStore.shared.rules(forContext: contextFor(decision.decisionClass))

        let dominant = topPatterns.first?.pattern

        let weather = terrain.axes.currentWeather
        let defaultPattern = dominant.map { "Your default under these conditions: \($0.loop.defaultScript)" }
            ?? "Default script unclear — assume habituated response."
        let risk = riskLine(decision: decision, pattern: dominant)
        let opportunity = opportunityLine(decision: decision, terrain: terrain)
        let bestRoute = bestRouteLine(decision: decision, pattern: dominant, rules: activeRules)
        let question = questionToAnswer(decision: decision, pattern: dominant)

        return DecisionOutput(
            currentWeather: weather,
            defaultPattern: defaultPattern,
            risk: risk,
            opportunity: opportunity,
            bestRoute: bestRoute,
            questionToAnswer: question,
            citedPatternIds: topPatterns.map { $0.pattern.id },
            citedTransitDrivers: terrain.drivers.map { $0.id },
            generatedAt: Date()
        )
    }

    private func contextFor(_ klass: Decision.DecisionClass) -> NavigationRule.TriggerContext {
        switch klass {
        case .career:       return .work
        case .relationship: return .love
        case .family:       return .family
        case .money:        return .money
        case .health:       return .health
        case .creative, .other: return .generic
        }
    }

    private func riskLine(decision: Decision, pattern: Pattern?) -> String {
        let reversibility: String
        switch decision.reversibility {
        case .oneWayDoor: reversibility = "This is a one-way door. Treat it accordingly."
        case .low:        reversibility = "Low reversibility — slow it down by one notch."
        case .medium:     reversibility = "Medium reversibility."
        case .high:       reversibility = "High reversibility — bias toward action."
        }
        if let pattern {
            return "\(reversibility) Your \(pattern.name) script may make this look more urgent than it is."
        }
        return reversibility
    }

    private func opportunityLine(decision: Decision, terrain: TerrainSnapshot) -> String {
        "Open window: \(terrain.axes.bestUse)"
    }

    private func bestRouteLine(decision: Decision, pattern: Pattern?, rules: [NavigationRule]) -> String {
        if let rule = rules.first {
            return "Your rule says: \(rule.text)"
        }
        if let pattern {
            return pattern.loop.highConsciousnessRoute
        }
        return "Wait \(waitDuration(for: decision.timeHorizon)). If you still want it, do it."
    }

    private func questionToAnswer(decision: Decision, pattern: Pattern?) -> String {
        if let pattern {
            return "Am I choosing this from clarity, or from \(pattern.loop.hiddenNeed.lowercased().trimmingCharacters(in: .punctuationCharacters))?"
        }
        return "Am I choosing this from clarity, or from restlessness?"
    }

    private func waitDuration(for horizon: Decision.TimeHorizon) -> String {
        switch horizon {
        case .hours:  return "60 minutes"
        case .days:   return "until tomorrow morning"
        case .weeks:  return "a sleep cycle"
        case .months: return "a week"
        case .years:  return "30 days"
        }
    }
}
