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
    
    private let userDefaults = UserDefaults.standard
    private let profileKey = "user_profile"
    
    init() {
        if let data = userDefaults.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = profile
        } else {
            self.profile = UserProfile()
        }
    }
    
    func saveProfile() {
        if let data = try? JSONEncoder().encode(profile) {
            userDefaults.set(data, forKey: profileKey)
        }
    }
    
    func updateProfile(_ newProfile: UserProfile) {
        profile = newProfile
        saveProfile()
    }
    
    var isProfileComplete: Bool {
        return !profile.fullName.isEmpty && 
               profile.birthTime != nil && 
               profile.birthPlace != nil
    }
}