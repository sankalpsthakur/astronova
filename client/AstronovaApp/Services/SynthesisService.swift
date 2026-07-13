import Foundation

// MARK: - Synthesis Service

/// Orchestrates the Cosmic Mirror synthesis API call — assembles the
/// multi-service request body from AuthState + UserProfile + cached chart data,
/// maps the response, and caches results (30-min TTL).
@MainActor
final class SynthesisService: ObservableObject {
    static let shared = SynthesisService()

    @Published var mirrorData: CosmicMirrorData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// When the last successful fetch completed.
    private(set) var lastFetchDate: Date?

    private let cacheTTL: TimeInterval = 1800 // 30 minutes
    private let cacheKey = "synthesis_mirror_cache"
    private let cacheTimestampKey = "synthesis_mirror_timestamp"
    private let api = APIServices.shared

    private init() {}

    // MARK: - Public API

    /// Load the Cosmic Mirror from the synthesis endpoint.
    ///
    /// Uses cached data if available and not expired. Falls back to a live
    /// API call otherwise, caching the result on success.
    ///
    /// - Parameters:
    ///   - profile: The user's birth profile (required for the request body).
    ///   - chart: An optional already-generated chart (for planet positions &
    ///     dasha data).
    ///   - dashaState: Pre-computed dasha state request (if available).
    ///   - userPriors: Optional user priors for personalization.
    func loadMirror(
        profile: UserProfile,
        chart: ChartResponse? = nil,
        dashaState: DashaStateRequest? = nil,
        userPriors: UserPriorsRequest? = nil
    ) async {
        // 1) Return cached data if fresh
        if !isCacheExpired, let cached = loadCachedMirror() {
            mirrorData = cached
            errorMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let data = try await fetchAndMap(
                profile: profile,
                chart: chart,
                dashaState: dashaState,
                userPriors: userPriors
            )
            mirrorData = data
            cacheMirror(data)
            lastFetchDate = Date()
        } catch {
            // If we have a stale cache, use it as fallback
            if let stale = loadCachedMirror() {
                mirrorData = stale
            }
            errorMessage = "Unable to align the mirror. Pull to retry."
        }

        isLoading = false
    }

    /// Invalidate the cache so the next call always hits the network.
    func invalidateCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
        lastFetchDate = nil
        mirrorData = nil
    }

    // MARK: - Fetch + Map

    private func fetchAndMap(
        profile: UserProfile,
        chart: ChartResponse?,
        dashaState: DashaStateRequest?,
        userPriors: UserPriorsRequest?
    ) async throws -> CosmicMirrorData {
        // Build BirthDataRequest
        guard let birthReq = buildBirthDataRequest(from: profile) else {
            throw SynthesisError.incompleteBirthData
        }

        // Build planet positions dict from chart
        let planetData = buildPlanetData(from: chart)

        // Determine lagna (ascendant sign) from chart
        let lagna: String
        if let vedicLagna = chart?.vedicChart?.positions["ascendant"]?.sign {
            lagna = vedicLagna
        } else if let westernLagna = chart?.westernChart?.positions["ascendant"]?.sign {
            lagna = westernLagna
        } else if let westernLagna = chart?.westernChart?.positions["sun"]?.sign {
            // Fallback: use Sun sign
            lagna = westernLagna
        } else {
            lagna = "aries"
        }

        // Build dasha state request
        let effectiveDashaState: DashaStateRequest
        if let ds = dashaState {
            effectiveDashaState = ds
        } else {
            effectiveDashaState = buildDashaState(from: chart, profile: profile)
        }

        let effectiveUserPriors = userPriors ?? UserPriorsRequest.fromStoredOnboarding()
        let phoneDigitSum = UserPriorsRequest.storedPhoneDigitSum()

        let response = try await api.fetchCosmicMirror(
            birthData: birthReq,
            planetData: planetData,
            lagna: lagna,
            dashaState: effectiveDashaState,
            userPriors: effectiveUserPriors,
            phoneDigitSum: phoneDigitSum
        )

        // The Rajayoga / constraints counts come from the response itself
        let rajayogaCount = response.matrix?.exaltedCount
        let constraintCount = response.constraints?.count

        return response.toMirrorData(
            rajayogaCount: rajayogaCount,
            constraintCount: constraintCount
        )
    }

    // MARK: - Request Builders

    private func buildBirthDataRequest(from profile: UserProfile) -> BirthDataRequest? {
        guard let latitude = profile.birthLatitude,
              let longitude = profile.birthLongitude,
              let timezone = profile.timezone else {
            return nil
        }

        let dateFmt = DateFormatter()
        dateFmt.locale = Locale(identifier: "en_US_POSIX")
        dateFmt.dateFormat = "yyyy-MM-dd"

        let timeFmt = DateFormatter()
        timeFmt.locale = Locale(identifier: "en_US_POSIX")
        timeFmt.dateFormat = "HH:mm"

        let timeStr: String
        if let birthTime = profile.birthTime {
            timeStr = timeFmt.string(from: birthTime)
        } else {
            timeStr = "12:00"
        }

        return BirthDataRequest(
            date: dateFmt.string(from: profile.birthDate),
            time: timeStr,
            timezone: timezone,
            latitude: latitude,
            longitude: longitude
        )
    }

    /// Build the planet_data dict from a cached chart response.
    ///
    /// Maps every planet name to its `PlanetPositionData` (sign, degree, house, retrograde).
    private func buildPlanetData(from chart: ChartResponse?) -> [String: PlanetPositionData] {
        guard let westernChart = chart?.westernChart else {
            // Return a minimal Sun-only entry so the backend has something
            return [
                "sun": PlanetPositionData(
                    sign: "aries", degree: 0, house: 1, retrograde: false
                )
            ]
        }

        var result: [String: PlanetPositionData] = [:]

        for (planetName, position) in westernChart.positions {
            // Position already carries the house number
            let house = position.house
            result[planetName.lowercased()] = PlanetPositionData(
                sign: position.sign,
                degree: position.degree,
                house: house,
                retrograde: false // motion state is determined server-side from birth data
            )
        }

        // Also pull positions from Vedic chart if available (may have additional planets)
        if let vedicChart = chart?.vedicChart {
            for (planetName, position) in vedicChart.positions {
                let key = planetName.lowercased()
                if result[key] == nil {
                    result[key] = PlanetPositionData(
                        sign: position.sign,
                        degree: position.degree,
                        house: position.house,
                        retrograde: false
                    )
                }
            }
        }

        return result
    }

    /// Build a DashaStateRequest from cached chart data.
    ///
    /// Falls back to a reasonable default if no dasha data is available.
    private func buildDashaState(
        from chart: ChartResponse?,
        profile: UserProfile
    ) -> DashaStateRequest {
        // Try to extract from Vedic chart dashas
        if let dashas = chart?.vedicChart?.dashas, let firstDasha = dashas.first {
            let isoFmt = ISO8601DateFormatter()
            isoFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let simpleFmt = DateFormatter()
            simpleFmt.locale = Locale(identifier: "en_US_POSIX")
            simpleFmt.dateFormat = "yyyy-MM-dd"

            let startStr = firstDasha.startDate
            let endStr = firstDasha.endDate

            let startDate = simpleFmt.date(from: startStr) ?? isoFmt.date(from: startStr)
            let endDate = simpleFmt.date(from: endStr) ?? isoFmt.date(from: endStr)

            let start = startDate.map { simpleFmt.string(from: $0) } ?? startStr
            let end = endDate.map { simpleFmt.string(from: $0) } ?? endStr

            let antardashaLord = dashas.count > 1 ? dashas[1].planet : firstDasha.planet

            return DashaStateRequest(
                mahadashaLord: firstDasha.planet,
                antardashaLord: antardashaLord,
                mahadashaStart: start,
                mahadashaEnd: end
            )
        }

        // Fallback: estimate from birth date
        let dateFmt = DateFormatter()
        dateFmt.locale = Locale(identifier: "en_US_POSIX")
        dateFmt.dateFormat = "yyyy-MM-dd"
        let birthStr = dateFmt.string(from: profile.birthDate)

        let defaultEnd = dateFmt.string(
            from: Calendar.current.date(byAdding: .year, value: 16, to: profile.birthDate) ?? Date()
        )

        return DashaStateRequest(
            mahadashaLord: "jupiter",
            antardashaLord: "mercury",
            mahadashaStart: birthStr,
            mahadashaEnd: defaultEnd
        )
    }

    // MARK: - Caching

    private var isCacheExpired: Bool {
        let lastTimestamp = UserDefaults.standard.double(forKey: cacheTimestampKey)
        guard lastTimestamp > 0 else { return true }
        return Date().timeIntervalSince1970 - lastTimestamp > cacheTTL
    }

    private func loadCachedMirror() -> CosmicMirrorData? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let mirror = try? JSONDecoder().decode(CosmicMirrorData.self, from: data) else {
            return nil
        }
        return mirror
    }

    private func cacheMirror(_ data: CosmicMirrorData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
        }
    }
}

// MARK: - Synthesis Errors

enum SynthesisError: LocalizedError {
    case incompleteBirthData
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .incompleteBirthData:
            return "Birth location data is incomplete. Please complete your profile."
        case .networkUnavailable:
            return "Network unavailable. Please check your connection."
        }
    }
}
