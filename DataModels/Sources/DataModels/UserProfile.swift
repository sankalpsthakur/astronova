import Foundation
import CoreLocation
import CloudKit

/// Private per-user profile information stored in user's private CloudKit zone.
public struct UserProfile: CKRecordConvertible, Codable {
    /// The CloudKit record type for UserProfile.
    public static let recordType = "UserProfile"

    public let fullName: String
    public let birthDate: Date
    public let birthTime: DateComponents?
    public let birthPlace: CLLocation
    public let sunSign: String
    public let moonSign: String
    public let risingSign: String
    public let plusExpiry: Date?
    public let createdAt: Date
    public let updatedAt: Date

    public init(record: CKRecord) throws {
        guard let fullName = record["fullName"] as? String,
              let birthDate = record["birthDate"] as? Date,
              let birthPlace = record["birthPlace"] as? CLLocation,
              let sunSign = record["sunSign"] as? String,
              let moonSign = record["moonSign"] as? String,
              let risingSign = record["risingSign"] as? String else {
            throw NSError(domain: "DataModels",
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Missing required UserProfile fields"])
        }
        self.fullName = fullName
        self.birthDate = birthDate
        self.birthTime = record["birthTime"] as? DateComponents
        self.birthPlace = birthPlace
        self.sunSign = sunSign
        self.moonSign = moonSign
        self.risingSign = risingSign
        self.plusExpiry = record["plusExpiry"] as? Date
        self.createdAt = record.creationDate ?? Date()
        self.updatedAt = record.modificationDate ?? Date()
    }

    public func toRecord(in zone: CKRecordZone.ID?) -> CKRecord {
        let record: CKRecord
        if let zoneID = zone {
            let id = CKRecord.ID(recordName: UUID().uuidString, zoneID: zoneID)
            record = CKRecord(recordType: UserProfile.recordType, recordID: id)
        } else {
            record = CKRecord(recordType: UserProfile.recordType)
        }
        record["fullName"] = fullName as CKRecordValue
        record["birthDate"] = birthDate as CKRecordValue
        if let time = birthTime {
            record["birthTime"] = time as? CKRecordValue
        }
        record["birthPlace"] = birthPlace as CKRecordValue
        record["sunSign"] = sunSign as CKRecordValue
        record["moonSign"] = moonSign as CKRecordValue
        record["risingSign"] = risingSign as CKRecordValue
        if let expiry = plusExpiry {
            record["plusExpiry"] = expiry as CKRecordValue
        }
        return record
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case fullName, birthDate, birthTime, birthLatitude, birthLongitude, sunSign, moonSign, risingSign, plusExpiry, createdAt, updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fullName = try container.decode(String.self, forKey: .fullName)
        birthDate = try container.decode(Date.self, forKey: .birthDate)
        birthTime = try container.decodeIfPresent(DateComponents.self, forKey: .birthTime)
        let lat = try container.decode(Double.self, forKey: .birthLatitude)
        let lon = try container.decode(Double.self, forKey: .birthLongitude)
        birthPlace = CLLocation(latitude: lat, longitude: lon)
        sunSign = try container.decode(String.self, forKey: .sunSign)
        moonSign = try container.decode(String.self, forKey: .moonSign)
        risingSign = try container.decode(String.self, forKey: .risingSign)
        plusExpiry = try container.decodeIfPresent(Date.self, forKey: .plusExpiry)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(birthDate, forKey: .birthDate)
        try container.encodeIfPresent(birthTime, forKey: .birthTime)
        try container.encode(birthPlace.coordinate.latitude, forKey: .birthLatitude)
        try container.encode(birthPlace.coordinate.longitude, forKey: .birthLongitude)
        try container.encode(sunSign, forKey: .sunSign)
        try container.encode(moonSign, forKey: .moonSign)
        try container.encode(risingSign, forKey: .risingSign)
        try container.encodeIfPresent(plusExpiry, forKey: .plusExpiry)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}