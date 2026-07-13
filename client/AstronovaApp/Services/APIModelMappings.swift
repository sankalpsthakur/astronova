import Foundation

// MARK: - API Response Type Stubs (until APIModels.swift is restored)

struct PlanetMatrixResponse: Codable {
    let planet: String; let sign: String; let house: Int; let degree: Double
    let status: String; let statusReason: String; let directionalNote: String?
    let rulingHouses: String?

    enum CodingKeys: String, CodingKey {
        case planet, sign, house, degree, status
        case statusReason = "status_reason"
        case directionalNote = "directional_strength_note"
        case rulingHouses = "ruling_houses"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        planet = try container.decodeIfPresent(String.self, forKey: .planet) ?? ""
        sign = try container.decodeIfPresent(String.self, forKey: .sign) ?? ""
        house = try container.decodeIfPresent(Int.self, forKey: .house) ?? 0
        degree = try container.decodeIfPresent(Double.self, forKey: .degree) ?? 0
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "neutral"
        statusReason = try container.decodeIfPresent(String.self, forKey: .statusReason) ?? ""
        directionalNote = try container.decodeIfPresent(String.self, forKey: .directionalNote)
        rulingHouses = try container.decodeIfPresent(String.self, forKey: .rulingHouses)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(planet, forKey: .planet)
        try container.encode(sign, forKey: .sign)
        try container.encode(house, forKey: .house)
        try container.encode(degree, forKey: .degree)
        try container.encode(status, forKey: .status)
        try container.encode(statusReason, forKey: .statusReason)
        try container.encodeIfPresent(directionalNote, forKey: .directionalNote)
        try container.encodeIfPresent(rulingHouses, forKey: .rulingHouses)
    }
}

struct ConstraintResponse: Codable {
    let title: String; let description: String; let guardrail: String
    let severity: String; let affectedPlanet: String; let affectedHouse: Int

    enum CodingKeys: String, CodingKey {
        case title, description, guardrail, severity
        case affectedPlanet = "affected_planet"
        case affectedHouse = "affected_house"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        guardrail = try container.decode(String.self, forKey: .guardrail)
        severity = try container.decode(String.self, forKey: .severity)
        affectedPlanet = try container.decodeIfPresent(String.self, forKey: .affectedPlanet) ?? "Saturn"
        affectedHouse = try container.decodeIfPresent(Int.self, forKey: .affectedHouse) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(guardrail, forKey: .guardrail)
        try container.encode(severity, forKey: .severity)
        try container.encode(affectedPlanet, forKey: .affectedPlanet)
        try container.encode(affectedHouse, forKey: .affectedHouse)
    }
}

struct ArchetypeResponse: Codable {
    let primary: String; let secondary: String; let synthesis: String
    let signalsDetected: [String]

    enum CodingKeys: String, CodingKey {
        case primary, secondary, synthesis
        case signalsDetected = "signals_detected"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        primary = try container.decodeIfPresent(String.self, forKey: .primary) ?? ""
        secondary = try container.decodeIfPresent(String.self, forKey: .secondary) ?? primary
        synthesis = try container.decodeIfPresent(String.self, forKey: .synthesis) ?? ""
        signalsDetected = try container.decodeIfPresent([String].self, forKey: .signalsDetected) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(primary, forKey: .primary)
        try container.encode(secondary, forKey: .secondary)
        try container.encode(synthesis, forKey: .synthesis)
        try container.encode(signalsDetected, forKey: .signalsDetected)
    }
}

struct PlaneInfoResponse: Codable {
    let name: String; let numbers: [Int]
    let isComplete: Bool; let description: String

    enum CodingKeys: String, CodingKey {
        case name, numbers, description
        case isComplete = "is_complete"
        case completed
    }

    init(name: String, numbers: [Int], isComplete: Bool, description: String) {
        self.name = name
        self.numbers = numbers
        self.isComplete = isComplete
        self.description = description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        numbers = try container.decodeIfPresent([Int].self, forKey: .numbers) ?? []
        isComplete = try container.decodeIfPresent(Bool.self, forKey: .isComplete)
            ?? container.decodeIfPresent(Bool.self, forKey: .completed)
            ?? false
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(numbers, forKey: .numbers)
        try container.encode(isComplete, forKey: .isComplete)
        try container.encode(description, forKey: .description)
    }
}

struct NumerologyReportResponse: Codable {
    let grid: [[Int]]; let counts: [String: Int]
    let missing: [Int]; let present: [Int]; let eigenvalues: [Double]
    let completedPlanes: [PlaneInfoResponse]
    let driverNumber: Int; let conductorNumber: Int

    enum CodingKeys: String, CodingKey {
        case grid, counts, missing, present, eigenvalues
        case completedPlanes = "completed_planes"
        case driverNumber = "driver_number"
        case conductorNumber = "conductor_number"
        case planes
        case driverConductor = "driver_conductor"
    }

    private enum GridKeys: String, CodingKey {
        case grid, counts, missing, present
    }

    private enum EigenvalueKeys: String, CodingKey {
        case eigenvalues
    }

    private enum PlanesKeys: String, CodingKey {
        case completedPlanes = "completed_planes"
    }

    private enum DriverConductorKeys: String, CodingKey {
        case driver, conductor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let nestedGrid = try? container.nestedContainer(keyedBy: GridKeys.self, forKey: .grid) {
            grid = try nestedGrid.decodeIfPresent([[Int]].self, forKey: .grid) ?? []
            counts = try nestedGrid.decodeIfPresent([String: Int].self, forKey: .counts) ?? [:]
            missing = try nestedGrid.decodeIfPresent([Int].self, forKey: .missing) ?? []
            present = try nestedGrid.decodeIfPresent([Int].self, forKey: .present) ?? []
        } else {
            grid = try container.decodeIfPresent([[Int]].self, forKey: .grid) ?? []
            counts = try container.decodeIfPresent([String: Int].self, forKey: .counts) ?? [:]
            missing = try container.decodeIfPresent([Int].self, forKey: .missing) ?? []
            present = try container.decodeIfPresent([Int].self, forKey: .present) ?? []
        }

        if let nestedEigenvalues = try? container.nestedContainer(keyedBy: EigenvalueKeys.self, forKey: .eigenvalues) {
            eigenvalues = try nestedEigenvalues.decodeIfPresent([Double].self, forKey: .eigenvalues) ?? []
        } else {
            eigenvalues = try container.decodeIfPresent([Double].self, forKey: .eigenvalues) ?? []
        }

        if let decodedPlanes = try container.decodeIfPresent([PlaneInfoResponse].self, forKey: .completedPlanes) {
            completedPlanes = decodedPlanes
        } else if let nestedPlanes = try? container.nestedContainer(keyedBy: PlanesKeys.self, forKey: .planes),
                  let names = try nestedPlanes.decodeIfPresent([String].self, forKey: .completedPlanes) {
            completedPlanes = names.map { PlaneInfoResponse(name: $0, numbers: [], isComplete: true, description: "") }
        } else {
            completedPlanes = []
        }

        if let nestedDriver = try? container.nestedContainer(keyedBy: DriverConductorKeys.self, forKey: .driverConductor) {
            driverNumber = try nestedDriver.decodeIfPresent(Int.self, forKey: .driver) ?? 0
            conductorNumber = try nestedDriver.decodeIfPresent(Int.self, forKey: .conductor) ?? 0
        } else {
            driverNumber = try container.decodeIfPresent(Int.self, forKey: .driverNumber) ?? 0
            conductorNumber = try container.decodeIfPresent(Int.self, forKey: .conductorNumber) ?? 0
        }
    }

    init(
        grid: [[Int]],
        counts: [String: Int],
        missing: [Int],
        present: [Int],
        eigenvalues: [Double],
        completedPlanes: [PlaneInfoResponse],
        driverNumber: Int,
        conductorNumber: Int
    ) {
        self.grid = grid
        self.counts = counts
        self.missing = missing
        self.present = present
        self.eigenvalues = eigenvalues
        self.completedPlanes = completedPlanes
        self.driverNumber = driverNumber
        self.conductorNumber = conductorNumber
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(grid, forKey: .grid)
        try container.encode(counts, forKey: .counts)
        try container.encode(missing, forKey: .missing)
        try container.encode(present, forKey: .present)
        try container.encode(eigenvalues, forKey: .eigenvalues)
        try container.encode(completedPlanes, forKey: .completedPlanes)
        try container.encode(driverNumber, forKey: .driverNumber)
        try container.encode(conductorNumber, forKey: .conductorNumber)
    }
}

struct MonthlyPredictionResponse: Codable {
    let month: String; let primaryTheme: String; let secondaryTheme: String
    let headline: String; let doAction: String; let avoidAction: String
    let triggerSummary: String; let eventClass: String; let probabilityBand: String
    let keyDates: [String]

    enum CodingKeys: String, CodingKey {
        case month, headline
        case primaryTheme = "primary_theme"
        case secondaryTheme = "secondary_theme"
        case doAction = "do_action"
        case avoidAction = "avoid_action"
        case actionGuidance = "action_guidance"
        case caution
        case triggerSummary = "trigger_summary"
        case eventClass = "event_class"
        case probabilityBand = "probability_band"
        case keyDates = "key_dates"
        case activeWindow = "active_window"
    }

    private enum ActiveWindowKeys: String, CodingKey {
        case start, end
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        month = try container.decode(String.self, forKey: .month)
        primaryTheme = try container.decode(String.self, forKey: .primaryTheme)
        secondaryTheme = try container.decodeIfPresent(String.self, forKey: .secondaryTheme) ?? ""
        headline = try container.decode(String.self, forKey: .headline)
        let actionGuidance = try container.decodeIfPresent(String.self, forKey: .actionGuidance)
        let caution = try container.decodeIfPresent(String.self, forKey: .caution)
        doAction = try container.decodeIfPresent(String.self, forKey: .doAction)
            ?? actionGuidance
            ?? "Take the next clean action."
        avoidAction = try container.decodeIfPresent(String.self, forKey: .avoidAction)
            ?? caution
            ?? "Avoid forcing the signal."
        triggerSummary = try container.decodeIfPresent(String.self, forKey: .triggerSummary)
            ?? primaryTheme
        eventClass = try container.decodeIfPresent(String.self, forKey: .eventClass)
            ?? primaryTheme
        probabilityBand = try container.decodeIfPresent(String.self, forKey: .probabilityBand)
            ?? "medium"
        if let decodedDates = try container.decodeIfPresent([String].self, forKey: .keyDates) {
            keyDates = decodedDates
        } else if let activeWindowString = try container.decodeIfPresent(String.self, forKey: .activeWindow) {
            keyDates = [activeWindowString]
        } else if let activeWindow = try? container.nestedContainer(keyedBy: ActiveWindowKeys.self, forKey: .activeWindow) {
            let start = try activeWindow.decodeIfPresent(String.self, forKey: .start)
            let end = try activeWindow.decodeIfPresent(String.self, forKey: .end)
            keyDates = [start, end].compactMap { $0 }
        } else {
            keyDates = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(month, forKey: .month)
        try container.encode(primaryTheme, forKey: .primaryTheme)
        try container.encode(secondaryTheme, forKey: .secondaryTheme)
        try container.encode(headline, forKey: .headline)
        try container.encode(doAction, forKey: .doAction)
        try container.encode(avoidAction, forKey: .avoidAction)
        try container.encode(triggerSummary, forKey: .triggerSummary)
        try container.encode(eventClass, forKey: .eventClass)
        try container.encode(probabilityBand, forKey: .probabilityBand)
        try container.encode(keyDates, forKey: .keyDates)
    }
}

struct PeakWindowResponse: Codable {
    let dateRange: String; let theme: String; let probability: String

    enum CodingKeys: String, CodingKey {
        case theme, probability
        case dateRange = "date_range"
    }
}

struct DashaPulseResponse: Codable {
    let currentLord: String; let daysRemaining: Int?
    let transitionHint: String?; let antardashaLord: String?
    let nextTransitionDate: String?

    enum CodingKeys: String, CodingKey {
        case currentLord = "current_lord"
        case daysRemaining = "days_remaining"
        case transitionHint = "transition_hint"
        case antardashaLord = "antardasha_lord"
        case nextTransitionDate = "next_transition_date"
    }
}

struct MatrixContainer: Codable {
    let planets: [PlanetMatrixResponse]?; let exaltedCount: Int?

    enum CodingKeys: String, CodingKey {
        case planets
        case exaltedCount = "exalted_count"
    }
}

struct CosmicMirrorResponse: Codable {
    let archetype: ArchetypeResponse?; let matrix: MatrixContainer?
    let constraints: [ConstraintResponse]?; let loshu: NumerologyReportResponse?
    let currentMonth: MonthlyPredictionResponse?
    let peakWindows: [PeakWindowResponse]?; let dashaPulse: DashaPulseResponse?
    let synthesisNarrative: String?

    enum CodingKeys: String, CodingKey {
        case archetype, matrix, constraints, loshu
        case currentMonth = "current_month"
        case peakWindows = "peak_windows"
        case dashaPulse = "dasha_pulse"
        case synthesisNarrative = "synthesis_narrative"
    }
}

struct PredictionTimelineResponse: Codable {
    let monthlyTimeline: [MonthlyPredictionResponse]
    let peakWindows: [PeakWindowResponse]; let summary: String?

    enum CodingKeys: String, CodingKey {
        case monthlyTimeline = "monthly_timeline"
        case peakWindows = "peak_windows"
        case summary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        monthlyTimeline = try container.decodeIfPresent([MonthlyPredictionResponse].self, forKey: .monthlyTimeline) ?? []
        peakWindows = try container.decodeIfPresent([PeakWindowResponse].self, forKey: .peakWindows) ?? []
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(monthlyTimeline, forKey: .monthlyTimeline)
        try container.encode(peakWindows, forKey: .peakWindows)
        try container.encodeIfPresent(summary, forKey: .summary)
    }
}

// MARK: - Mapping Extensions: API Response Types → View Model Types

/// Shared planet symbol lookup used across mappings.
func sharedPlanetSymbol(for planet: String) -> String {
    switch planet.lowercased() {
    case "sun", "surya":     return "\u{2609}"
    case "moon", "chandra":  return "\u{263D}"
    case "mercury", "budha": return "\u{263F}"
    case "venus", "shukra":  return "\u{2640}"
    case "mars", "mangal":   return "\u{2642}"
    case "jupiter", "guru":  return "\u{2643}"
    case "saturn", "shani":  return "\u{2644}"
    case "uranus":           return "\u{2645}"
    case "neptune":          return "\u{2646}"
    case "pluto":            return "\u{2647}"
    case "rahu":             return "\u{260A}"
    case "ketu":             return "\u{260B}"
    default:                 return "\u{25CF}"
    }
}

/// Map API status string (e.g. "exalted", "own_sign") → OptimizationStatus enum.
func optimizationStatus(from apiStatus: String) -> OptimizationStatus {
    switch apiStatus.lowercased() {
    case "exalted":      return .exalted
    case "own_sign":     return .ownSign
    case "friendly":     return .friendly
    case "neutral":      return .neutral
    case "debilitated":  return .debilitated
    default:             return .neutral
    }
}

/// Map API severity string → ConstraintSeverity enum.
func constraintSeverity(from apiSeverity: String) -> ConstraintSeverity {
    switch apiSeverity.lowercased() {
    case "critical": return .critical
    case "high":     return .high
    default:         return .moderate
    }
}

// MARK: - PlanetMatrixResponse → PlanetMatrixEntry

extension PlanetMatrixResponse {
    func toViewEntry() -> PlanetMatrixEntry {
        PlanetMatrixEntry(
            planet: planet,
            symbol: sharedPlanetSymbol(for: planet),
            sign: sign,
            house: house,
            degree: degree,
            status: optimizationStatus(from: status),
            statusReason: statusReason,
            directionalNote: directionalNote,
            rulingHouse: rulingHouses
        )
    }
}

// MARK: - ConstraintResponse → ChartConstraint

extension ConstraintResponse {
    func toChartConstraint() -> ChartConstraint {
        ChartConstraint(
            title: title,
            description: description,
            guardrail: guardrail,
            severity: constraintSeverity(from: severity),
            affectedPlanet: affectedPlanet,
            affectedHouse: affectedHouse
        )
    }
}

// MARK: - ArchetypeResponse → ChartArchetype

extension ArchetypeResponse {
    func toChartArchetype(rajayogaCount: Int = 0, constraintCount: Int = 0) -> ChartArchetype {
        // Infer dominant element from signalsDetected
        let elements = ["fire", "earth", "air", "water"]
        let detectedElement = signalsDetected.first { signal in
            elements.contains(where: { signal.lowercased().contains($0) })
        } ?? "unknown"

        let dominantElement: String
        if detectedElement.lowercased().contains("fire") {
            dominantElement = "Fire"
        } else if detectedElement.lowercased().contains("earth") {
            dominantElement = "Earth"
        } else if detectedElement.lowercased().contains("air") {
            dominantElement = "Air"
        } else if detectedElement.lowercased().contains("water") {
            dominantElement = "Water"
        } else {
            dominantElement = "Unknown"
        }

        // Infer dominant planet from signalsDetected
        let planetNames = [
            "sun", "moon", "mercury", "venus", "mars",
            "jupiter", "saturn", "uranus", "neptune", "pluto",
            "rahu", "ketu"
        ]
        let detectedPlanet = signalsDetected.first { signal in
            planetNames.contains(where: { signal.lowercased().contains($0) })
        } ?? primary.components(separatedBy: " ").first ?? "Unknown"

        let dominantPlanet = detectedPlanet.capitalized

        return ChartArchetype(
            primary: primary,
            secondary: secondary,
            synthesis: synthesis,
            dominantElement: dominantElement,
            dominantPlanet: dominantPlanet,
            rajayogaCount: rajayogaCount,
            constraintCount: constraintCount
        )
    }
}

// MARK: - PlaneInfoResponse → PlaneInfo

extension PlaneInfoResponse {
    func toPlaneInfo() -> PlaneInfo {
        PlaneInfo(
            name: name,
            numbers: numbers,
            isComplete: isComplete,
            description: description
        )
    }
}

// MARK: - NumerologyReportResponse → LoshuData

extension NumerologyReportResponse {
    func toLoshuData() -> LoshuData {
        LoshuData(
            grid: grid,
            counts: counts,
            missing: missing,
            present: present,
            eigenvalues: eigenvalues,
            completedPlanes: completedPlanes.map { $0.toPlaneInfo() },
            driverNumber: driverNumber,
            conductorNumber: conductorNumber
        )
    }
}

// MARK: - MonthlyPredictionResponse → MonthlyPrediction

extension MonthlyPredictionResponse {
    /// Convert to MonthlyPrediction (used in PredictionTimelineView).
    /// The `id` is derived from the month string (assumed format like "June 2026").
    func toMonthlyPrediction() -> MonthlyPrediction {
        // Derive a stable id from the month string
        let id = monthToID(month)
        return MonthlyPrediction(
            id: id,
            month: month,
            primaryTheme: primaryTheme,
            secondaryTheme: secondaryTheme,
            headline: headline,
            doAction: doAction,
            avoidAction: avoidAction,
            triggerSummary: triggerSummary,
            eventClass: eventClass,
            probabilityBand: probabilityBand,
            keyDates: keyDates
        )
    }

    /// Convert to MonthPrediction (used in CosmicMirrorView).
    func toMonthPrediction() -> MonthPrediction {
        MonthPrediction(
            id: monthToID(month),
            month: month,
            headline: headline,
            doAction: doAction,
            avoidAction: avoidAction,
            transitTriggers: keyDates
        )
    }

    private func monthToID(_ monthStr: String) -> String {
        // Parse "June 2026" → "2026-06"
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        if let date = formatter.date(from: monthStr) {
            let cal = Calendar.current
            let year = cal.component(.year, from: date)
            let monthNum = cal.component(.month, from: date)
            return String(format: "%d-%02d", year, monthNum)
        }
        // Fallback: sanitize the string
        return monthStr.replacingOccurrences(of: " ", with: "-").lowercased()
    }
}

// MARK: - PeakWindowResponse → MirrorPeakWindow

extension PeakWindowResponse {
    func toMirrorPeakWindow() -> MirrorPeakWindow {
        MirrorPeakWindow(
            id: UUID().uuidString,
            dateRange: dateRange,
            theme: theme,
            headline: nil,
            probability: probability
        )
    }

    func toPeakWindow() -> TimelinePeakWindow {
        TimelinePeakWindow(
            id: UUID().uuidString,
            dateRange: dateRange,
            theme: theme,
            headline: nil,
            probability: probability
        )
    }
}

// MARK: - DashaPulseResponse → DashaPulseData

extension DashaPulseResponse {
    /// Build a DashaPulseData from the pulse response and optional dasha context.
    /// - Parameters:
    ///   - chartDasha: Optional Vedic chart dasha data from a prior chart response.
    func toDashaPulseData(chartDashas: [Dasha]? = nil) -> DashaPulseData {
        // Vimshottari dasha durations (years)
        let vimshottariDurations: [String: Int] = [
            "sun": 6, "moon": 10, "mars": 7, "rahu": 18,
            "jupiter": 16, "saturn": 19, "mercury": 17,
            "ketu": 7, "venus": 20
        ]

        // Try to find the matching dasha from chart data
        let lordKey = currentLord.lowercased()
        let matchingDasha = chartDashas?.first { $0.planet.lowercased() == lordKey }

        let totalYears = vimshottariDurations[lordKey] ?? 7

        // Parse dates from chart dasha if available
        let isoFmt = ISO8601DateFormatter()
        isoFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let simpleFmt = DateFormatter()
        simpleFmt.locale = Locale(identifier: "en_US_POSIX")
        simpleFmt.dateFormat = "yyyy-MM-dd"

        let startDate: Date
        let endDate: Date
        let currentYear: Int

        if let dasha = matchingDasha {
            // Parse start/end from string dates
            startDate = simpleFmt.date(from: dasha.startDate)
                ?? isoFmt.date(from: dasha.startDate)
                ?? Date()
            endDate = simpleFmt.date(from: dasha.endDate)
                ?? isoFmt.date(from: dasha.endDate)
                ?? Calendar.current.date(byAdding: .year, value: totalYears, to: startDate)
                ?? Date()

            // Compute how many years into the current dasha
            let elapsedDays = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
            currentYear = min(max(Int(Double(elapsedDays) / 365.25) + 1, 1), totalYears)
        } else {
            // No chart data — estimate from daysRemaining
            let remainingDays = daysRemaining ?? (totalYears * 365)
            let elapsedDays = (totalYears * 365) - remainingDays
            startDate = Calendar.current.date(byAdding: .day, value: -elapsedDays, to: Date()) ?? Date()
            endDate = Calendar.current.date(byAdding: .day, value: remainingDays, to: Date()) ?? Date()
            currentYear = max(Int(Double(elapsedDays) / 365.25) + 1, 1)
        }

        // Parse next transition date (avoid shadowing self.nextTransitionDate)
        let parsedNextDate: Date?
        if let nextStr = self.nextTransitionDate {
            parsedNextDate = simpleFmt.date(from: nextStr)
                ?? isoFmt.date(from: nextStr)
        } else {
            parsedNextDate = endDate
        }

        let nextTransitionLabel = transitionHint ?? antardashaLord

        return DashaPulseData(
            currentPlanet: currentLord,
            currentYear: currentYear,
            totalYears: totalYears,
            startDate: startDate,
            endDate: endDate,
            nextTransitionLabel: nextTransitionLabel,
            nextTransitionDate: parsedNextDate
        )
    }
}

// MARK: - CosmicMirrorResponse → CosmicMirrorData

extension CosmicMirrorResponse {
    /// Map the full synthesis API response to the view's CosmicMirrorData.
    func toMirrorData(rajayogaCount: Int? = nil, constraintCount: Int? = nil) -> CosmicMirrorData {
        // Archetype
        let chartArchetype: ChartArchetype?
        if let arch = archetype {
            let rc = rajayogaCount ?? matrix?.exaltedCount ?? 0
            let cc = constraintCount ?? constraints?.count ?? 0
            chartArchetype = arch.toChartArchetype(rajayogaCount: rc, constraintCount: cc)
        } else {
            chartArchetype = nil
        }

        // Matrix entries
        let entries: [PlanetMatrixEntry]?
        if let planets = matrix?.planets, !planets.isEmpty {
            entries = planets.map { $0.toViewEntry() }
        } else {
            entries = nil
        }

        // Constraints
        let chartConstraints: [ChartConstraint]?
        if let cons = constraints, !cons.isEmpty {
            chartConstraints = cons.map { $0.toChartConstraint() }
        } else {
            chartConstraints = nil
        }

        // Loshu
        let loshuData = loshu?.toLoshuData()

        // Current month
        let monthPred: MonthPrediction?
        if let cm = currentMonth {
            monthPred = cm.toMonthPrediction()
        } else {
            monthPred = nil
        }

        // Peak windows
        let windows: [MirrorPeakWindow]?
        if let pws = peakWindows, !pws.isEmpty {
            windows = pws.map { $0.toMirrorPeakWindow() }
        } else {
            windows = nil
        }

        // Dasha pulse
        let pulse = dashaPulse?.toDashaPulseData()

        return CosmicMirrorData(
            archetype: chartArchetype,
            matrixEntries: entries,
            constraints: chartConstraints,
            loshu: loshuData,
            currentMonthPrediction: monthPred,
            peakWindows: windows,
            dashaPulse: pulse,
            journeyProgress: nil,
            synthesisNarrative: synthesisNarrative
        )
    }
}

// MARK: - PredictionTimelineResponse → PredictionTimelineData

extension PredictionTimelineResponse {
    func toTimelineData() -> PredictionTimelineData {
        let predictions = monthlyTimeline.map { $0.toMonthlyPrediction() }
        let windows = peakWindows.map { $0.toPeakWindow() }
        return PredictionTimelineData(
            monthlyPredictions: predictions,
            peakWindows: windows,
            summary: summary ?? ""
        )
    }
}
