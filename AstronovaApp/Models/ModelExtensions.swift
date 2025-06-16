import Foundation

// MARK: - Extensions for convenience

extension BirthData {
    /// Create BirthData from UserProfile
    init(from profile: UserProfile) throws {
        guard let birthTime = profile.birthTime,
              let birthPlace = profile.birthPlace,
              let coordinates = profile.birthCoordinates,
              let timezone = profile.timezone else {
            throw APIError(error: "Incomplete birth data", details: nil, code: "INCOMPLETE_DATA")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        self.name = profile.fullName
        self.date = dateFormatter.string(from: profile.birthDate)
        self.time = timeFormatter.string(from: birthTime)
        self.latitude = coordinates.latitude
        self.longitude = coordinates.longitude
        
        // Parse city, state, country from birthPlace
        let components = birthPlace.components(separatedBy: ", ")
        self.city = components.first ?? birthPlace
        self.state = components.count > 2 ? components[1] : nil
        self.country = components.last ?? "Unknown"
        self.timezone = timezone
    }
}

extension PlanetaryPosition {
    /// Format degree as readable string
    var formattedDegree: String {
        String(format: "%.2f°", degree)
    }
    
    /// Full position description
    var description: String {
        "\(sign) \(formattedDegree)"
    }
}