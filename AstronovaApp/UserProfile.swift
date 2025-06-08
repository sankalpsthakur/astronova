import Foundation
import CoreLocation

struct UserProfile: Codable {
    var fullName: String
    var birthDate: Date
    var birthTime: Date?
    var birthPlace: String?
    var birthCoordinates: CLLocationCoordinate2D?
    var timezone: String?
    
    // Additional profile information
    var profileImageURL: String?
    var bio: String?
    var sunSign: String?
    var moonSign: String?
    var risingSign: String?
    
    init(fullName: String = "", birthDate: Date = Date(), birthTime: Date? = nil, birthPlace: String? = nil, birthCoordinates: CLLocationCoordinate2D? = nil, timezone: String? = nil) {
        self.fullName = fullName
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.birthPlace = birthPlace
        self.birthCoordinates = birthCoordinates
        self.timezone = timezone
    }
}

extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
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
        profile = newProfile
        do {
            try saveProfile()
            // Clear cached chart when profile changes significantly
            if profileSignificantlyChanged(newProfile) {
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
            let response = try await apiServices.searchLocations(query: query, limit: 10)
            return response.locations
        } catch {
            print("Failed to search locations: \(error)")
            return []
        }
    }
    
    /// Set birth location from location result
    func setBirthLocation(_ location: LocationResult) {
        profile.birthPlace = location.fullName
        profile.birthCoordinates = location.coordinate
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
        return !profile.fullName.isEmpty && 
               profile.birthTime != nil && 
               profile.birthPlace != nil &&
               profile.birthCoordinates != nil &&
               profile.timezone != nil
    }
    
    /// Check if profile changes require new chart generation
    private func profileSignificantlyChanged(_ newProfile: UserProfile) -> Bool {
        return newProfile.birthDate != profile.birthDate ||
               newProfile.birthTime != profile.birthTime ||
               newProfile.birthCoordinates?.latitude != profile.birthCoordinates?.latitude ||
               newProfile.birthCoordinates?.longitude != profile.birthCoordinates?.longitude
    }
}