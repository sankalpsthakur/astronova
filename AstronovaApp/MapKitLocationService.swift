import Foundation
import MapKit
import CoreLocation
import os.log

struct MapKitLocationService {
    static let shared = MapKitLocationService()
    private let logger = Logger(subsystem: "com.astronova.app", category: "MapKitLocationService")
    
    private init() {}
    
    func searchPlaces(query: String) async throws -> [LocationResult] {
        logger.info("Searching places with query: \(query)")
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MapKitLocationError.invalidQuery
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.pointOfInterest, .address]
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            
            let results = response.mapItems.compactMap { item -> LocationResult? in
                let coordinate = item.placemark.coordinate
                
                // Skip invalid coordinates
                guard coordinate.latitude != 0 || coordinate.longitude != 0 else {
                    return nil
                }
                
                let fullName = formatPlacemarkName(item.placemark)
                let timezone = await getTimezoneForCoordinate(coordinate)
                
                return LocationResult(
                    fullName: fullName.isEmpty ? (item.name ?? "Unknown Location") : fullName,
                    coordinate: coordinate,
                    timezone: timezone
                )
            }
            
            logger.info("Found \(results.count) results for query: \(query)")
            return results
            
        } catch {
            logger.error("Search failed for query '\(query)': \(error.localizedDescription)")
            throw MapKitLocationError.searchFailed(error)
        }
    }
    
    func autocomplete(input: String) async throws -> [LocationSuggestion] {
        logger.info("Autocompleting input: \(input)")
        
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, input.count >= 2 else {
            return []
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let completer = MKLocalSearchCompleter()
            let delegate = SearchCompleterDelegate(continuation: continuation)
            
            completer.delegate = delegate
            completer.resultTypes = [.pointOfInterest, .address]
            completer.queryFragment = input
            
            // Store the delegate to prevent deallocation
            delegate.completer = completer
        }
    }
    
    func getLocationFromCompletion(_ completion: MKLocalSearchCompletion) async throws -> LocationResult {
        logger.info("Getting location details for completion: \(completion.title)")
        
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            
            guard let mapItem = response.mapItems.first else {
                throw MapKitLocationError.noPlacemarkFound
            }
            
            let coordinate = mapItem.placemark.coordinate
            let fullName = formatPlacemarkName(mapItem.placemark)
            let timezone = await getTimezoneForCoordinate(coordinate)
            
            return LocationResult(
                fullName: fullName.isEmpty ? (mapItem.name ?? completion.title) : fullName,
                coordinate: coordinate,
                timezone: timezone
            )
            
        } catch {
            logger.error("Failed to get location from completion: \(error.localizedDescription)")
            throw MapKitLocationError.searchFailed(error)
        }
    }
    
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async throws -> LocationResult {
        logger.info("Reverse geocoding coordinate: \(coordinate.latitude), \(coordinate.longitude)")
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            guard let placemark = placemarks.first else {
                throw MapKitLocationError.noPlacemarkFound
            }
            
            let fullName = formatPlacemarkName(placemark)
            let timezone = getTimezoneForCoordinate(coordinate)
            
            return LocationResult(
                fullName: fullName.isEmpty ? "Unknown Location" : fullName,
                coordinate: coordinate,
                timezone: timezone
            )
            
        } catch {
            logger.error("Reverse geocoding failed: \(error.localizedDescription)")
            throw MapKitLocationError.reverseGeocodeFailed(error)
        }
    }
    
    private func formatPlacemarkName(_ placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let name = placemark.name {
            components.append(name)
        }
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
    
    private func formatPlacemarkName(_ placemark: MKPlacemark) -> String {
        var components: [String] = []
        
        if let name = placemark.name {
            components.append(name)
        }
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
    
    private func getTimezoneForCoordinate(_ coordinate: CLLocationCoordinate2D) async -> String {
        // Use CoreLocation to get timezone information
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first,
               let timeZone = placemark.timeZone {
                return timeZone.identifier
            }
        } catch {
            logger.warning("Failed to get timezone for coordinate: \(error.localizedDescription)")
        }
        
        return TimeZone.current.identifier
    }
}

// MARK: - Models

struct LocationSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let completion: MKLocalSearchCompletion
    
    var displayText: String {
        if let subtitle = subtitle, !subtitle.isEmpty {
            return "\(title), \(subtitle)"
        }
        return title
    }
}

// MARK: - Search Completer Delegate

private class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    private let continuation: CheckedContinuation<[LocationSuggestion], Error>
    private var hasReturned = false
    var completer: MKLocalSearchCompleter?
    
    init(continuation: CheckedContinuation<[LocationSuggestion], Error>) {
        self.continuation = continuation
        super.init()
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        guard !hasReturned else { return }
        hasReturned = true
        
        let suggestions = completer.results.map { completion in
            LocationSuggestion(
                title: completion.title,
                subtitle: completion.subtitle,
                completion: completion
            )
        }
        
        continuation.resume(returning: suggestions)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        guard !hasReturned else { return }
        hasReturned = true
        
        continuation.resume(throwing: MapKitLocationError.autocompleteFailed(error))
    }
}

// MARK: - Errors

enum MapKitLocationError: Error, LocalizedError {
    case searchFailed(Error)
    case autocompleteFailed(Error)
    case reverseGeocodeFailed(Error)
    case noPlacemarkFound
    case invalidQuery
    
    var errorDescription: String? {
        switch self {
        case .searchFailed(let error):
            return "Location search failed: \(error.localizedDescription)"
        case .autocompleteFailed(let error):
            return "Autocomplete failed: \(error.localizedDescription)"
        case .reverseGeocodeFailed(let error):
            return "Reverse geocoding failed: \(error.localizedDescription)"
        case .noPlacemarkFound:
            return "No location found for the given coordinates"
        case .invalidQuery:
            return "Invalid search query"
        }
    }
}