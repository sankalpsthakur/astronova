import Foundation
import CloudKit
import CloudKitKit
import DataModels

/// Repository for creating Order records in the private DB.
public final class OrderRepository {
    public init() {}

    /// Persists an Order model to CloudKit private database.
    public func save(_ order: Order) async throws {
        // Convert the model into a CKRecord located in the default private zone.
        let record = order.toRecord(in: CKRecordZone.default().zoneID)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let operation = CKModifyRecordsOperation(recordsToSave: [record])
            operation.savePolicy = .ifServerRecordUnchanged
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            CKContainer.cosmic.privateCloudDatabase.add(operation)
        }
    }
}