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
    
    init(fullName: String = "", birthDate: Date = Date(), birthTime: Date? = nil, birthPlace: String? = nil, birthLatitude: Double? = nil, birthLongitude: Double? = nil, timezone: String? = nil) {
        self.fullName = fullName
        self.birthDate = birthDate
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
    
    private let userDefaults = UserDefaults.standard
    private let profileKey = "user_profile"
    private let chartKey = "last_chart"
    private let apiServices = APIServices.shared
    
    init() {
        if let data = userDefaults.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = profile
        } else {
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
            let data = try JSONEncoder().encode(profile)
            userDefaults.set(data, forKey: profileKey)
        } catch {
            print("Error saving user profile: \(error)")
            throw error
        }
    }
    
    func updateProfile(_ newProfile: UserProfile) {
        let oldProfile = profile
        profile = newProfile
        do {
            try saveProfile()
            // Clear cached chart when profile changes significantly
            if profileSignificantlyChanged(old: oldProfile, new: newProfile) {
                lastChart = nil
                userDefaults.removeObject(forKey: chartKey)
            }
        } catch {
            print("Failed to save updated profile: \(error)")
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
            print("Failed to generate chart: \(error)")
        }
    }
    
    /// Search for locations using real API
    func searchLocations(query: String) async -> [LocationResult] {
        do {
            let locations = try await apiServices.searchLocations(query: query)
            return locations
        } catch {
            print("Failed to search locations: \(error)")
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
        } catch {
            print("Failed to save profile after setting location: \(error)")
        }
    }
    
    /// Get daily horoscope for user's sun sign
    func getDailyHoroscope() async -> HoroscopeResponse? {
        guard let sunSign = profile.sunSign else { return nil }
        
        do {
            return try await apiServices.getDailyHoroscope(for: sunSign)
        } catch {
            print("Failed to get daily horoscope: \(error)")
            return nil
        }
    }
    
    /// Check API connectivity
    func checkAPIConnectivity() async -> Bool {
        do {
            let health = try await apiServices.healthCheck()
            return health.status == "ok"
        } catch {
            print("API connectivity check failed: \(error)")
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