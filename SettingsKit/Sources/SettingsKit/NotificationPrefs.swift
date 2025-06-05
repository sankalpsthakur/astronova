import Foundation
import CloudKit
import DataModels

/// CloudKit record representing user notification preferences.
public struct NotificationPrefs: Codable, CKRecordConvertible {
    /// CloudKit record type name.
    public static let recordType = "NotificationPrefs"

    public var dailyEnabled: Bool

    public init(dailyEnabled: Bool = true) {
        self.dailyEnabled = dailyEnabled
    }

    // MARK: - CKRecordConvertible

    public init(record: CKRecord) throws {
        guard let enabled = record["dailyEnabled"] as? Int else {
            throw NSError(domain: "SettingsKit",
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Missing dailyEnabled field"])
        }
        self.dailyEnabled = enabled == 1
    }

    public func toRecord(in zone: CKRecordZone.ID?) -> CKRecord {
        let record: CKRecord
        if let zoneID = zone {
            let id = CKRecord.ID(recordName: "prefs", zoneID: zoneID)
            record = CKRecord(recordType: Self.recordType, recordID: id)
        } else {
            record = CKRecord(recordType: Self.recordType)
        }
        record["dailyEnabled"] = (dailyEnabled ? 1 : 0) as CKRecordValue
        return record
    }
}