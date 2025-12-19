import Foundation
import CoreLocation

struct UserProfile: Codable {
    var fullName: String
    var birthDate: Date
    var birthTime: Date?
    var birthPlace: String?
    var birthLatitude: Double?
    var birthLongitude: Double?
    var timezone: String?
    
    // Additional profile information
    var profileImageURL: String?
    var bio: String?
    var sunSign: String?
    var moonSign: String?
    var risingSign: String?
    
    // Computed property for birth coordinates
    var birthCoordinates: CLLocationCoordinate2D? {
        guard let lat = birthLatitude, let lon = birthLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    /// Default birth date is 25 years ago to make it obvious user should set their actual date
    private static var defaultBirthDate: Date {
        Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    }

    init(fullName: String = "", birthDate: Date? = nil, birthTime: Date? = nil, birthPlace: String? = nil, birthLatitude: Double? = nil, birthLongitude: Double? = nil, timezone: String? = nil) {
        self.fullName = fullName
        self.birthDate = birthDate ?? Self.defaultBirthDate
        self.birthTime = birthTime
        self.birthPlace = birthPlace
        self.birthLatitude = birthLatitude
        self.birthLongitude = birthLongitude
        self.timezone = timezone
    }
}

class UserProfileManager: ObservableObject {
    @Published var profile: UserProfile
    @Published var isLoading = false
    @Published var lastChart: ChartResponse?
    @Published var errorMessage: String?
    @Published var isSyncing = false

    private let userDefaults = UserDefaults.standard
    private let profileKey = "user_profile"
    private let chartKey = "last_chart"
    private let deviceIdKey = "device_user_id"
    private let apiServices = APIServices.shared

    /// Device-based user ID for anonymous users
    var deviceUserId: String {
        if let existingId = userDefaults.string(forKey: deviceIdKey) {
            return existingId
        }
        let newId = "device-\(UUID().uuidString.lowercased())"
        userDefaults.set(newId, forKey: deviceIdKey)
        return newId
    }

    init() {
        if let data = userDefaults.data(forKey: profileKey) {
            do {
                let decodedProfile = try JSONDecoder().decode(UserProfile.self, from: data)
                self.profile = decodedProfile
                #if DEBUG
                debugPrint("[Profile] Loaded profile from UserDefaults - birthTime: \(String(describing: decodedProfile.birthTime))")
                #endif
            } catch {
                #if DEBUG
                debugPrint("[Profile] Failed to decode profile from UserDefaults: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    debugPrint("[Profile] Raw JSON: \(jsonString)")
                }
                #endif
                self.profile = UserProfile()
            }
        } else {
            #if DEBUG
            debugPrint("[Profile] No saved profile found, creating new UserProfile")
            #endif
            self.profile = UserProfile()
        }

        // Load last cached chart
        if let chartData = userDefaults.data(forKey: chartKey),
           let chart = try? JSONDecoder().decode(ChartResponse.self, from: chartData) {
            self.lastChart = chart
        }
    }
    
    func saveProfile() throws {
        do {
            #if DEBUG
            debugPrint("[Profile] Saving profile - birthTime: \(String(describing: profile.birthTime))")
            #endif

            let data = try JSONEncoder().encode(profile)
            userDefaults.set(data, forKey: profileKey)

            #if DEBUG
            // Verify the save by reading it back
            if let savedData = userDefaults.data(forKey: profileKey),
               let verifyProfile = try? JSONDecoder().decode(UserProfile.self, from: savedData) {
                debugPrint("[Profile] Verified save - birthTime: \(String(describing: verifyProfile.birthTime))")
            } else {
                debugPrint("[Profile] WARNING: Failed to verify saved profile!")
            }
            #endif

            // Trigger server sync in background (fire and forget)
            Task {
                await syncBirthDataToServer()
            }
        } catch {
            #if DEBUG
            debugPrint("[Profile] Error saving user profile: \(error.localizedDescription)")
            #endif
            throw error
        }
    }

    /// Sync birth data to server for features that require server-side data (Time Travel, Oracle, etc.)
    func syncBirthDataToServer(userId: String? = nil) async {
        // Only sync if we have complete location data
        guard hasCompleteLocationData else {
            #if DEBUG
            debugPrint("[Profile] Skipping server sync - incomplete location data")
            #endif
            return
        }

        await MainActor.run {
            isSyncing = true
        }

        let effectiveUserId = userId ?? deviceUserId

        do {
            try await apiServices.syncBirthData(userId: effectiveUserId, profile: profile)
            #if DEBUG
            debugPrint("[Profile] Birth data synced to server successfully for user: \(effectiveUserId)")
            #endif
        } catch {
            #if DEBUG
            debugPrint("[Profile] Failed to sync birth data to server: \(error.localizedDescription)")
            #endif
        }

        await MainActor.run {
            isSyncing = false
        }
    }
    
    func updateProfile(_ newProfile: UserProfile) {
        #if DEBUG
        debugPrint("[Profile] updateProfile called - incoming birthTime: \(String(describing: newProfile.birthTime))")
        #endif

        let oldProfile = profile
        profile = newProfile

        #if DEBUG
        debugPrint("[Profile] Profile updated in memory - current birthTime: \(String(describing: profile.birthTime))")
        #endif

        do {
            try saveProfile()
            // Clear cached chart when profile changes significantly
            if profileSignificantlyChanged(old: oldProfile, new: newProfile) {
                lastChart = nil
                userDefaults.removeObject(forKey: chartKey)
            }
        } catch {
            #if DEBUG
            debugPrint("[Profile] Failed to save updated profile: \(error.localizedDescription)")
            #endif
        }
    }
    
    /// Generate astrological chart using real API
    func generateChart() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let chartResponse = try await apiServices.generateChart(from: profile)
            
            await MainActor.run {
                self.lastChart = chartResponse
                
                // Update profile with calculated signs
                if let westernChart = chartResponse.westernChart {
                    self.profile.sunSign = westernChart.positions["sun"]?.sign
                    self.profile.moonSign = westernChart.positions["moon"]?.sign
                    // Note: Rising sign calculation might need ascendant data
                }
                
                // Cache the chart
                if let chartData = try? JSONEncoder().encode(chartResponse) {
                    self.userDefaults.set(chartData, forKey: self.chartKey)
                }
                
                self.isLoading = false
                
                // Save updated profile
                try? self.saveProfile()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            #if DEBUG
            debugPrint("[Profile] Failed to generate chart: \(error.localizedDescription)")
            #endif
        }
    }

    /// Search for locations using real API
    func searchLocations(query: String) async -> [LocationResult] {
        do {
            let locations = try await apiServices.searchLocations(query: query)
            return locations
        } catch {
            #if DEBUG
            debugPrint("[Profile] Failed to search locations: \(error.localizedDescription)")
            #endif
            return []
        }
    }

    /// Set birth location from location result
    func setBirthLocation(_ location: LocationResult) {
        profile.birthPlace = location.fullName
        profile.birthLatitude = location.coordinate.latitude
        profile.birthLongitude = location.coordinate.longitude
        profile.timezone = location.timezone

        do {
            try saveProfile()
            // saveProfile() now triggers server sync automatically
        } catch {
            #if DEBUG
            debugPrint("[Profile] Failed to save profile after setting location: \(error.localizedDescription)")
            #endif
        }
    }

    /// Manually trigger a sync to server (useful for ensuring data is synced before using server-dependent features)
    func ensureServerSync() async {
        await syncBirthDataToServer()
    }

    /// Get daily horoscope for user's sun sign
    func getDailyHoroscope() async -> HoroscopeResponse? {
        guard let sunSign = profile.sunSign else { return nil }

        do {
            return try await apiServices.getDailyHoroscope(for: sunSign)
        } catch {
            #if DEBUG
            debugPrint("[Profile] Failed to get daily horoscope: \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    /// Check API connectivity
    func checkAPIConnectivity() async -> Bool {
        do {
            let health = try await apiServices.healthCheck()
            return health.status == "ok"
        } catch {
            #if DEBUG
            debugPrint("[Profile] API connectivity check failed: \(error.localizedDescription)")
            #endif
            return false
        }
    }
    
    var isProfileComplete: Bool {
        // Essential fields for basic functionality
        return !profile.fullName.isEmpty && profile.birthTime != nil
        // Birth place, coordinates, and timezone are optional and can be added later
    }
    
    /// Whether profile has minimal data needed for Quick Start functionality (just name and birth date)
    var hasMinimalProfileData: Bool {
        return !profile.fullName.isEmpty
    }
    
    /// Whether profile has all location data needed for advanced astrological calculations
    var hasCompleteLocationData: Bool {
        return profile.birthPlace != nil &&
               profile.birthLatitude != nil &&
               profile.birthLongitude != nil &&
               profile.timezone != nil
    }
    
    /// Check if profile changes require new chart generation
    private func profileSignificantlyChanged(old: UserProfile, new: UserProfile) -> Bool {
        return new.birthDate != old.birthDate ||
               new.birthTime != old.birthTime ||
               new.birthLatitude != old.birthLatitude ||
               new.birthLongitude != old.birthLongitude
    }
}