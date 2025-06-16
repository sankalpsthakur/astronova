import Foundation
import CoreLocation

// MARK: - Location Models

/// Location search request
struct LocationSearchRequest: Codable {
    let query: String
    let limit: Int?
}

/// Location result from search
struct LocationResult: Codable, Hashable {
    let name: String
    let displayName: String
    let latitude: Double
    let longitude: Double
    let country: String
    let state: String?
    let timezone: String
    
    // Computed property for compatibility with UI
    var fullName: String {
        return displayName
    }
    
    // Computed property for coordinates
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Initializer for location service compatibility
    init(fullName: String, coordinate: CLLocationCoordinate2D, timezone: String) {
        // Parse the full name to extract city/state/country components
        let components = fullName.components(separatedBy: ", ").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        self.displayName = fullName
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.timezone = timezone
        
        // Extract city name (first component, or fallback to full name)
        self.name = components.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? fullName
        
        // Extract country (usually last component, with validation)
        if let lastComponent = components.last?.trimmingCharacters(in: .whitespacesAndNewlines), !lastComponent.isEmpty {
            self.country = lastComponent
        } else {
            self.country = "Unknown"
        }
        
        // Extract state (usually second to last if more than 2 components)
        if components.count > 2,
           let stateComponent = components.dropLast().last?.trimmingCharacters(in: .whitespacesAndNewlines),
           !stateComponent.isEmpty {
            self.state = stateComponent
        } else {
            self.state = nil
        }
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(displayName)
        hasher.combine(latitude)
        hasher.combine(longitude)
        hasher.combine(timezone)
    }
    
    // Equatable conformance
    static func == (lhs: LocationResult, rhs: LocationResult) -> Bool {
        return lhs.displayName == rhs.displayName &&
               lhs.latitude == rhs.latitude &&
               lhs.longitude == rhs.longitude &&
               lhs.timezone == rhs.timezone
    }
}

/// Location search response
struct LocationSearchResponse: Codable {
    let locations: [LocationResult]
}