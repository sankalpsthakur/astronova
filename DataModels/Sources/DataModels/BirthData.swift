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
}
