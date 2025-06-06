import Foundation
import CloudKit

/// On-device Kundali match result to be saved as a private record.
public struct KundaliMatch: CKRecordConvertible, Identifiable {
    public static let recordType = "SavedMatch"
    public let id: String
    public let partnerName: String
    public let partnerDOB: Date
    public let scoreTotal: Int
    public let aspectJSON: String
    public let createdAt: Date
    public let recordID: CKRecord.ID?

    public init(record: CKRecord) throws {
        guard let partnerName = record["partnerName"] as? String,
              let partnerDOB = record["partnerDOB"] as? Date,
              let scoreTotal = record["scoreTotal"] as? Int,
              let aspectJSON = record["aspectJSON"] as? String else {
            throw NSError(domain: "DataModels",
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Missing required KundaliMatch fields"])
        }
        self.id = record["id"] as? String ?? record.recordID.recordName
        self.partnerName = partnerName
        self.partnerDOB = partnerDOB
        self.scoreTotal = scoreTotal
        self.aspectJSON = aspectJSON
        self.createdAt = record.creationDate ?? Date()
        self.recordID = record.recordID
    }

    public func toRecord(in zone: CKRecordZone.ID?) -> CKRecord {
        let record: CKRecord
        if let zoneID = zone {
            let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
            record = CKRecord(recordType: KundaliMatch.recordType, recordID: recordID)
        } else {
            let recordID = CKRecord.ID(recordName: id)
            record = CKRecord(recordType: KundaliMatch.recordType, recordID: recordID)
        }
        record["id"] = id as CKRecordValue
        record["partnerName"] = partnerName as CKRecordValue
        record["partnerDOB"] = partnerDOB as CKRecordValue
        record["scoreTotal"] = scoreTotal as CKRecordValue
        record["aspectJSON"] = aspectJSON as CKRecordValue
        return record
    }

    /// Convenience initializer for creating a match result on-device before it
    /// is persisted to CloudKit.
    public init(partnerName: String,
                partnerDOB: Date,
                scoreTotal: Int,
                aspectJSON: String,
                createdAt: Date) {
        self.id = UUID().uuidString
        self.partnerName = partnerName
        self.partnerDOB = partnerDOB
        self.scoreTotal = scoreTotal
        self.aspectJSON = aspectJSON
        self.createdAt = createdAt
        self.recordID = nil
    }
}