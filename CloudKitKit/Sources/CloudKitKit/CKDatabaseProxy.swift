import CloudKit

/// A typed proxy over a CKDatabase instance (public or private).
@available(iOS 13.0, *)
public final class CKDatabaseProxy: @unchecked Sendable {
    /// Public database proxy.
    public static let `public` = CKDatabaseProxy(database: CKContainer.cosmic.publicCloudDatabase)

    /// Private (per-user) database proxy.
    public static let `private` = CKDatabaseProxy(database: CKContainer.cosmic.privateCloudDatabase)

    private let database: CKDatabase

    public init(database: CKDatabase) {
        self.database = database
    }
}

@available(iOS 13.0, *)
public extension CKDatabaseProxy {
    /// Fetches a CKRecord by ID asynchronously.
    func fetchRecord(id: CKRecord.ID) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKRecord, Error>) in
            database.fetch(withRecordID: id) { record, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let record = record {
                    continuation.resume(returning: record)
                } else {
                    let err = NSError(domain: "CloudKitKit",
                                      code: 0,
                                      userInfo: [NSLocalizedDescriptionKey: "Failed to fetch record"])
                    continuation.resume(throwing: err)
                }
            }
        }
    }

    /// Saves a CKRecord asynchronously.
    func saveRecord(_ record: CKRecord) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKRecord, Error>) in
            database.save(record) { saved, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let saved = saved {
                    continuation.resume(returning: saved)
                } else {
                    let err = NSError(domain: "CloudKitKit",
                                      code: 0,
                                      userInfo: [NSLocalizedDescriptionKey: "Failed to save record"])
                    continuation.resume(throwing: err)
                }
            }
        }
    }

    /// Deletes a CKRecord by its record ID asynchronously.
    func deleteRecord(id: CKRecord.ID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            database.delete(withRecordID: id) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// Queries records matching the given predicate, sort descriptors, and optional zone.
    func queryRecords(recordType: String,
                      predicate: NSPredicate,
                      sortDescriptors: [NSSortDescriptor]? = nil,
                      zoneID: CKRecordZone.ID? = nil) async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        if let sorts = sortDescriptors {
            query.sortDescriptors = sorts
        }
        let operation = CKQueryOperation(query: query)
        if let zoneID = zoneID {
            operation.zoneID = zoneID
        }
        var results: [CKRecord] = []
        operation.recordFetchedBlock = { record in
            results.append(record)
        }
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CKRecord], Error>) in
            operation.queryCompletionBlock = { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: results)
                }
            }
            database.add(operation)
        }
    }
}
