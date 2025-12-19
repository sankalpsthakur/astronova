import Foundation
import SwiftUI

// MARK: - Self Data Service
// Fetches and manages dasha, nakshatra, and energy data for the Self tab

@MainActor
class SelfDataService: ObservableObject {
    @Published var currentDasha: DashaInfo?
    @Published var moonNakshatra: String?
    @Published var nakshatraLord: String?
    @Published var lagna: String?
    @Published var planetaryStrengths: [PlanetaryStrength] = []
    @Published var dominantPlanet: String?
    @Published var isLoading = false
    @Published var error: String?

    // Reports
    @Published var userReports: [DetailedReport] = []
    @Published var isLoadingReports = false
    private var reportPollTimer: Timer?

    private var cachedResponse: DashaCompleteResponse?
    private var lastFetchDate: Date?
    private let cacheValidityMinutes: Int = 60

    /// Device-based user ID for anonymous users
    var currentUserId: String {
        let key = "client_user_id"
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let created = UUID().uuidString
        UserDefaults.standard.set(created, forKey: key)
        return created
    }

    // MARK: - Fetch Data

    func fetchData(for profile: UserProfile) async {
        // Check cache validity
        if let lastFetch = lastFetchDate,
           Date().timeIntervalSince(lastFetch) < Double(cacheValidityMinutes * 60),
           cachedResponse != nil {
            return
        }

        guard let request = buildRequest(from: profile) else {
            error = "Incomplete birth data"
            return
        }

        isLoading = true
        error = nil

        do {
            let response = try await APIServices.shared.fetchCompleteDasha(request: request)
            cachedResponse = response
            lastFetchDate = Date()
            parseResponse(response)
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("[SelfDataService] Error fetching dasha: \(error)")
            #endif
        }

        isLoading = false
    }

    // MARK: - Build Request

    private func buildRequest(from profile: UserProfile) -> DashaCompleteRequest? {
        guard let birthTime = profile.birthTime,
              let latitude = profile.birthLatitude,
              let longitude = profile.birthLongitude,
              let timezone = profile.timezone else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let birthData = DashaCompleteRequest.BirthDataPayload(
            date: dateFormatter.string(from: profile.birthDate),
            time: timeFormatter.string(from: birthTime),
            timezone: timezone,
            latitude: latitude,
            longitude: longitude
        )

        return DashaCompleteRequest(
            birthData: birthData,
            targetDate: dateFormatter.string(from: Date()),
            includeTransitions: true,
            includeEducation: true
        )
    }

    // MARK: - Parse Response

    private func parseResponse(_ response: DashaCompleteResponse) {
        // Extract current dasha
        let mahadasha = response.currentPeriod.mahadasha
        currentDasha = DashaInfo(
            planet: mahadasha.lord.capitalized,
            startDate: parseDate(mahadasha.start) ?? Date(),
            endDate: parseDate(mahadasha.end) ?? Date(),
            currentYear: calculateCurrentYear(start: mahadasha.start, end: mahadasha.end),
            totalYears: Int(mahadasha.durationYears ?? DashaConstants.totalYears(for: mahadasha.lord).doubleValue)
        )

        // Extract nakshatra from education content
        if let education = response.education,
           let calculation = education.calculationExplanation {
            moonNakshatra = calculation.nakshatra
            nakshatraLord = calculation.nakshatraLord
        }

        // Extract lagna (we'll need to get this from chart data or add to API)
        // For now, derive from impact analysis tone or leave nil
        lagna = nil // TODO: Add lagna to API response

        // Build planetary strengths from impact analysis
        buildPlanetaryStrengths(from: response.impactAnalysis)

        // Set dominant planet
        dominantPlanet = planetaryStrengths.first?.planet
    }

    // MARK: - Build Planetary Strengths

    private func buildPlanetaryStrengths(from impact: DashaCompleteResponse.ImpactAnalysis) {
        var strengths: [PlanetaryStrength] = []

        // Mahadasha lord strength
        let mahaStrength = impact.mahadashaImpact.strength.overallScore / 100.0
        strengths.append(PlanetaryStrength(
            planet: impact.mahadashaImpact.lord.capitalized,
            value: min(1.0, max(0.0, mahaStrength))
        ))

        // Antardasha lord strength (if different)
        if impact.antardashaImpact.lord != impact.mahadashaImpact.lord {
            let antarStrength = impact.antardashaImpact.strength.overallScore / 100.0
            strengths.append(PlanetaryStrength(
                planet: impact.antardashaImpact.lord.capitalized,
                value: min(1.0, max(0.0, antarStrength))
            ))
        }

        // Add derived strengths from domain scores
        let scores = impact.combinedScores
        let allScores = [
            ("Career", scores.career),
            ("Relations", scores.relationships),
            ("Health", scores.health),
            ("Spiritual", scores.spiritual)
        ]

        // Map domain scores to planetary associations
        let planetDomains: [(String, Double)] = [
            ("Sun", (scores.career + scores.spiritual) / 2 / 100.0),
            ("Moon", (scores.relationships + scores.health) / 2 / 100.0),
            ("Mercury", scores.career / 100.0 * 0.8),
            ("Venus", scores.relationships / 100.0),
            ("Mars", (scores.career + scores.health) / 2 / 100.0 * 0.9),
            ("Jupiter", (scores.spiritual + scores.career) / 2 / 100.0),
            ("Saturn", scores.career / 100.0 * 0.7)
        ]

        for (planet, value) in planetDomains {
            // Don't duplicate mahadasha/antardasha lords
            if !strengths.contains(where: { $0.planet.lowercased() == planet.lowercased() }) {
                strengths.append(PlanetaryStrength(
                    planet: planet,
                    value: min(1.0, max(0.0, value))
                ))
            }
        }

        // Sort by strength descending
        planetaryStrengths = strengths.sorted { $0.value > $1.value }
    }

    // MARK: - Helpers

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    private func calculateCurrentYear(start: String, end: String) -> Int {
        guard let startDate = parseDate(start) else { return 1 }
        let now = Date()
        let calendar = Calendar.current
        let years = calendar.dateComponents([.year], from: startDate, to: now).year ?? 0
        return max(1, years + 1) // 1-indexed
    }

    // MARK: - Refresh

    func refresh(for profile: UserProfile) async {
        lastFetchDate = nil
        cachedResponse = nil
        await fetchData(for: profile)
    }

    // MARK: - Clear Cache

    func clearCache() {
        cachedResponse = nil
        lastFetchDate = nil
        currentDasha = nil
        moonNakshatra = nil
        nakshatraLord = nil
        lagna = nil
        planetaryStrengths = []
        dominantPlanet = nil
        stopReportPolling()
    }

    // MARK: - Reports

    /// Fetch user's reports
    func fetchReports() async {
        isLoadingReports = true

        do {
            let reports = try await APIServices.shared.getUserReports(userId: currentUserId)
            userReports = reports.sorted { ($0.generatedAt ?? "") > ($1.generatedAt ?? "") }

            // Check if any reports are still processing
            let hasProcessing = reports.contains { $0.status?.lowercased() == "processing" }
            if hasProcessing {
                startReportPolling()
            } else {
                stopReportPolling()
            }
        } catch {
            #if DEBUG
            print("[SelfDataService] Error fetching reports: \(error)")
            #endif
        }

        isLoadingReports = false
    }

    /// Start polling for processing reports
    private func startReportPolling() {
        guard reportPollTimer == nil else { return }

        reportPollTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchReports()
            }
        }
    }

    /// Stop polling
    func stopReportPolling() {
        reportPollTimer?.invalidate()
        reportPollTimer = nil
    }

    /// Check if there are processing reports
    var hasProcessingReports: Bool {
        userReports.contains { $0.status?.lowercased() == "processing" }
    }

    /// Get completed reports only
    var completedReports: [DetailedReport] {
        userReports.filter { $0.status?.lowercased() == "completed" }
    }

    /// Get processing reports only
    var processingReports: [DetailedReport] {
        userReports.filter { $0.status?.lowercased() == "processing" }
    }
}

// MARK: - Int Extension for Double

private extension Int {
    var doubleValue: Double { Double(self) }
}
