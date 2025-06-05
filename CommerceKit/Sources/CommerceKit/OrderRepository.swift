import Foundation
import CloudKitKit
import DataModels

/// Repository for creating Order records in the private DB.
public final class OrderRepository {
    public init() {}

    /// Persists an Order model to CloudKit private database.
    public func save(_ order: Order) async throws {
        // TODO: implement CKModifyRecordsOperation logic
    }
}