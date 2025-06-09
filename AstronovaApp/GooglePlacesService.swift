import Foundation
import CoreLocation
import os.log

struct GooglePlacesService {
    static let shared = GooglePlacesService()
    private let baseURL = "https://maps.googleapis.com/maps/api/place"
    private let apiKey: String
    private let logger = Logger(subsystem: "com.astronova.app", category: "GooglePlacesService")
    
    private init() {
        // Prefer environment variable for better security
        if let envKey = ProcessInfo.processInfo.environment["GOOGLE_PLACES_API_KEY"],
           !envKey.isEmpty {
            self.apiKey = envKey
        } else if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
                  let plist = NSDictionary(contentsOfFile: path),
                  let key = plist["GooglePlacesAPIKey"] as? String,
                  !key.isEmpty && key != "YOUR_GOOGLE_PLACES_API_KEY_HERE" {
            self.apiKey = key
        } else {
            // No API key configured - will fallback to MKLocalSearch
            self.apiKey = ""
            logger.info("Google Places API key not configured. Location search will use Apple's MKLocalSearch as fallback.")
        }
    }
    
    func searchPlaces(query: String) async throws -> [LocationResult] {
        guard !apiKey.isEmpty else {
            throw GooglePlacesError.missingAPIKey
        }
        
        
        var components = URLComponents(string: "\(baseURL)/textsearch/json")
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components?.url else {
            throw GooglePlacesError.invalidURL
        }
        
        let response: GooglePlacesResponse
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            response = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
            
            if response.status != "OK" && response.status != "ZERO_RESULTS" {
                logger.error("Google Places search failed with status: \(response.status)")
                throw GooglePlacesError.apiError(response.status)
            }
        } catch {
            logger.error("Google Places search error: \(error.localizedDescription)")
            throw error
        }
        
        // Return empty array for ZERO_RESULTS to allow fallback handling
        guard response.status == "OK" && !response.results.isEmpty else {
            return []
        }
        
        return response.results.compactMap { place in
            // Ensure we have valid coordinates
            guard place.geometry.location.lat != 0 || place.geometry.location.lng != 0 else {
                return nil
            }
            
            return LocationResult(
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
        
        var components = URLComponents(string: "\(baseURL)/details/json")
        components?.queryItems = [
            URLQueryItem(name: "place_id", value: placeId),
            URLQueryItem(name: "fields", value: "formatted_address,geometry,utc_offset"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components?.url else {
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
        
        
        var components = URLComponents(string: "\(baseURL)/autocomplete/json")
        components?.queryItems = [
            URLQueryItem(name: "input", value: input),
            URLQueryItem(name: "types", value: "(cities)"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components?.url else {
            throw GooglePlacesError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GooglePlacesAutocompleteResponse.self, from: data)
        
        if response.status != "OK" && response.status != "ZERO_RESULTS" {
            throw GooglePlacesError.apiError(response.status)
        }
        
        // Return empty array for ZERO_RESULTS to allow fallback handling
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