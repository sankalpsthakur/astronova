import CloudKit

/// Types that can convert to/from CKRecord.
public protocol CKRecordConvertible {
    /// The CloudKit record type (used for queries and record creation).
    static var recordType: String { get }

    /// Initialize from an existing CKRecord.
    init(record: CKRecord) throws

    /// Produce a CKRecord for saving, optionally in the given zone.
    func toRecord(in zone: CKRecordZone.ID?) -> CKRecord
}