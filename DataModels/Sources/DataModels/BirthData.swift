import Foundation
import CoreLocation

/// Birth information used for astrological calculations.
public struct BirthData: Codable {
    public let date: Date
    public let time: DateComponents?
    public let location: CLLocation

    public init(date: Date, time: DateComponents? = nil, location: CLLocation) {
        self.date = date
        self.time = time
        self.location = location
    }

    // MARK: – Codable

    private enum CodingKeys: String, CodingKey {
        case date, time, latitude, longitude, altitude
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        time = try container.decodeIfPresent(DateComponents.self, forKey: .time)
        let lat = try container.decode(Double.self, forKey: .latitude)
        let lon = try container.decode(Double.self, forKey: .longitude)
        let alt = try container.decodeIfPresent(Double.self, forKey: .altitude) ?? 0
        location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), altitude: alt, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 0, timestamp: Date())
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(time, forKey: .time)
        try container.encode(location.coordinate.latitude, forKey: .latitude)
        try container.encode(location.coordinate.longitude, forKey: .longitude)
        let alt = location.altitude
        // Only encode altitude if it’s non-zero to save space.
        if alt != 0 {
            try container.encode(alt, forKey: .altitude)
        }
    }
}
