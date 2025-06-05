import Foundation
import CloudKit

/// Represents a merchandise order record in the private database.
public struct Order: CKRecordConvertible, Codable {
    public static let recordType = "Order"
    public let id: String
    public let productSKU: String
    public let quantity: Int
    public let totalAmount: Double
    public let currency: String
    public let createdAt: Date

    public init(record: CKRecord) throws {
        guard let productSKU = record["productSKU"] as? String,
              let quantity = record["quantity"] as? Int,
              let totalAmount = record["totalAmount"] as? Double,
              let currency = record["currency"] as? String else {
            throw NSError(domain: "DataModels",
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Missing required Order fields"])
        }
        self.id = record.recordID.recordName
        self.productSKU = productSKU
        self.quantity = quantity
        self.totalAmount = totalAmount
        self.currency = currency
        self.createdAt = record.creationDate ?? Date()
    }

    public func toRecord(in zone: CKRecordZone.ID?) -> CKRecord {
        let record: CKRecord
        if let zoneID = zone {
            let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
            record = CKRecord(recordType: Order.recordType, recordID: recordID)
        } else {
            record = CKRecord(recordType: Order.recordType)
        }
        record["productSKU"] = productSKU as CKRecordValue
        record["quantity"] = quantity as CKRecordValue
        record["totalAmount"] = totalAmount as CKRecordValue
        record["currency"] = currency as CKRecordValue
        return record
    }
}