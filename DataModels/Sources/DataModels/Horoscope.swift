import Foundation
import CloudKit

/// Daily horoscope content from the public database.
public struct Horoscope: CKRecordConvertible, Codable {
    public static let recordType = "Horoscope"
    public let sign: String
    public let date: Date
    public let language: String
    public let shortText: String
    public let extendedText: String?

    public init(record: CKRecord) throws {
        guard let sign = record["sign"] as? String,
              let date = record["date"] as? Date,
              let language = record["language"] as? String,
              let shortText = record["shortText"] as? String else {
            throw NSError(domain: "DataModels",
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Missing required Horoscope fields"])
        }
        self.sign = sign
        self.date = date
        self.language = language
        self.shortText = shortText
        self.extendedText = record["extendedText"] as? String
    }

    public func toRecord(in zone: CKRecordZone.ID?) -> CKRecord {
        let record: CKRecord
        if let zoneID = zone {
            let id = CKRecord.ID(recordName: UUID().uuidString, zoneID: zoneID)
            record = CKRecord(recordType: Horoscope.recordType, recordID: id)
        } else {
            record = CKRecord(recordType: Horoscope.recordType)
        }
        record["sign"] = sign as CKRecordValue
        record["date"] = date as CKRecordValue
        record["language"] = language as CKRecordValue
        record["shortText"] = shortText as CKRecordValue
        if let ext = extendedText {
            record["extendedText"] = ext as CKRecordValue
        }
        return record
    }
}