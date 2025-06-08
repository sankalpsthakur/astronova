import Foundation
import CoreLocation

struct GooglePlacesService {
    static let shared = GooglePlacesService()
    private let baseURL = "https://maps.googleapis.com/maps/api/place"
    private let apiKey: String
    
    private init() {
        // Get API key from Info.plist or environment
        // NOTE: For production apps, consider proxying requests through your backend
        // to avoid exposing the API key in the client binary
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let key = plist["GooglePlacesAPIKey"] as? String,
           !key.isEmpty && key != "YOUR_GOOGLE_PLACES_API_KEY_HERE" {
            self.apiKey = key
        } else {
            // No API key configured - will fallback to MKLocalSearch
            self.apiKey = ""
            print("Warning: Google Places API key not configured. Using MKLocalSearch fallback.")
        }
    }
    
    func searchPlaces(query: String) async throws -> [LocationResult] {
        guard !apiKey.isEmpty else {
            throw GooglePlacesError.missingAPIKey
        }
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw GooglePlacesError.invalidQuery
        }
        
        let urlString = "\(baseURL)/textsearch/json?query=\(encodedQuery)&key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GooglePlacesError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
        
        if response.status != "OK" && response.status != "ZERO_RESULTS" {
            throw GooglePlacesError.apiError(response.status)
        }
        
        return response.results.map { place in
            LocationResult(
                fullName: place.formattedAddress,
                coordinate: CLLocationCoordinate2D(
                    latitude: place.geometry.location.lat,
                    longitude: place.geometry.location.lng
                ),
                timezone: place.timezone ?? TimeZone.current.identifier
            )
        }
    }
    
    func getPlaceDetails(placeId: String) async throws -> GooglePlaceDetails {
        guard !apiKey.isEmpty else {
            throw GooglePlacesError.missingAPIKey
        }
        
        let urlString = "\(baseURL)/details/json?place_id=\(placeId)&fields=formatted_address,geometry,utc_offset&key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GooglePlacesError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GooglePlaceDetailsResponse.self, from: data)
        
        if response.status != "OK" {
            throw GooglePlacesError.apiError(response.status)
        }
        
        return response.result
    }
    
    func autocomplete(input: String) async throws -> [GooglePlaceAutocomplete] {
        guard !apiKey.isEmpty else {
            throw GooglePlacesError.missingAPIKey
        }
        
        guard let encodedInput = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw GooglePlacesError.invalidQuery
        }
        
        let urlString = "\(baseURL)/autocomplete/json?input=\(encodedInput)&types=(cities)&key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GooglePlacesError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GooglePlacesAutocompleteResponse.self, from: data)
        
        if response.status != "OK" && response.status != "ZERO_RESULTS" {
            throw GooglePlacesError.apiError(response.status)
        }
        
        return response.predictions
    }
}

// MARK: - Response Models

struct GooglePlacesResponse: Codable {
    let results: [GooglePlace]
    let status: String
}

struct GooglePlace: Codable {
    let placeId: String
    let formattedAddress: String
    let geometry: GoogleGeometry
    let timezone: String?
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case formattedAddress = "formatted_address"
        case geometry
        case timezone
    }
}

struct GoogleGeometry: Codable {
    let location: GoogleLocation
}

struct GoogleLocation: Codable {
    let lat: Double
    let lng: Double
}

struct GooglePlaceDetailsResponse: Codable {
    let result: GooglePlaceDetails
    let status: String
}

struct GooglePlaceDetails: Codable {
    let formattedAddress: String
    let geometry: GoogleGeometry
    let utcOffset: Int?
    
    enum CodingKeys: String, CodingKey {
        case formattedAddress = "formatted_address"
        case geometry
        case utcOffset = "utc_offset"
    }
}

struct GooglePlacesAutocompleteResponse: Codable {
    let predictions: [GooglePlaceAutocomplete]
    let status: String
}

struct GooglePlaceAutocomplete: Codable {
    let placeId: String
    let description: String
    let structuredFormatting: GoogleStructuredFormatting?
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case description
        case structuredFormatting = "structured_formatting"
    }
}

struct GoogleStructuredFormatting: Codable {
    let mainText: String
    let secondaryText: String?
    
    enum CodingKeys: String, CodingKey {
        case mainText = "main_text"
        case secondaryText = "secondary_text"
    }
}

// MARK: - Errors

enum GooglePlacesError: Error, LocalizedError {
    case missingAPIKey
    case invalidQuery
    case invalidURL
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Google Places API key is missing"
        case .invalidQuery:
            return "Invalid search query"
        case .invalidURL:
            return "Invalid URL"
        case .apiError(let status):
            return "Google Places API error: \(status)"
        }
    }
}