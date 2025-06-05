import Foundation
import CloudKit

/// Product listing from the public shop zone.
public struct Product: CKRecordConvertible, Codable {
    public static let recordType = "Product"
    public let sku: String
    public let name: String
    public let price: Double
    public let currency: String
    public let stock: Int
    public let photoAsset: CKAsset?
    public let tags: [String]
    public let isActive: Bool

    // Identifiable conformance for SwiftUI lists/grids.
    public var id: String { sku }

    public init(record: CKRecord) throws {
        guard let sku = record["sku"] as? String,
              let name = record["name"] as? String,
              let price = record["price"] as? Double,
              let currency = record["currency"] as? String,
              let stock = record["stock"] as? Int,
              let tags = record["tags"] as? [String],
              let active = record["active"] as? Bool else {
            throw NSError(domain: "DataModels",
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Missing required Product fields"])
        }
        self.sku = sku
        self.name = name
        self.price = price
        self.currency = currency
        self.stock = stock
        self.photoAsset = record["photo"] as? CKAsset
        self.tags = tags
        self.isActive = active
    }

    public func toRecord(in zone: CKRecordZone.ID?) -> CKRecord {
        let record: CKRecord
        if let zoneID = zone {
            let id = CKRecord.ID(recordName: UUID().uuidString, zoneID: zoneID)
            record = CKRecord(recordType: Product.recordType, recordID: id)
        } else {
            record = CKRecord(recordType: Product.recordType)
        }
        record["sku"] = sku as CKRecordValue
        record["name"] = name as CKRecordValue
        record["price"] = price as CKRecordValue
        record["currency"] = currency as CKRecordValue
        record["stock"] = stock as CKRecordValue
        if let asset = photoAsset {
            record["photo"] = asset
        }
        record["tags"] = tags as CKRecordValue
        record["active"] = isActive as CKRecordValue
        return record
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case sku, name, price, currency, stock, tags, isActive
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sku = try container.decode(String.self, forKey: .sku)
        name = try container.decode(String.self, forKey: .name)
        price = try container.decode(Double.self, forKey: .price)
        currency = try container.decode(String.self, forKey: .currency)
        stock = try container.decode(Int.self, forKey: .stock)
        tags = try container.decode([String].self, forKey: .tags)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        photoAsset = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sku, forKey: .sku)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)
        try container.encode(currency, forKey: .currency)
        try container.encode(stock, forKey: .stock)
        try container.encode(tags, forKey: .tags)
        try container.encode(isActive, forKey: .isActive)
    }
}