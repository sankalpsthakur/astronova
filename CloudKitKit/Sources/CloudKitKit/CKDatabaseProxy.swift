import CloudKit
import Foundation

/// Configuration controlling retry and cooldown behaviour of `CKDatabaseProxy`.
public struct CKDatabaseProxyConfiguration {
    /// Maximum number of retry attempts for transient errors.
    public var maxRetries: Int
    /// Minimal time to wait between write operations.
    public var cooldown: TimeInterval

    public init(maxRetries: Int = 3, cooldown: TimeInterval = 1.0) {
        self.maxRetries = maxRetries
        self.cooldown = cooldown
    }
}

/// A typed proxy over a CKDatabase instance (public or private).
@available(iOS 13.0, *)
public final class CKDatabaseProxy: @unchecked Sendable {
    /// Public database proxy.
    public static let `public` = CKDatabaseProxy(database: CKContainer.cosmic.publicCloudDatabase)

    /// Private (per-user) database proxy.
    public static let `private` = CKDatabaseProxy(database: CKContainer.cosmic.privateCloudDatabase)

    private let database: CKDatabase
    private var configuration: CKDatabaseProxyConfiguration
    private var lastWriteDate: Date?
    private let lock = NSLock()

    public init(database: CKDatabase,
                configuration: CKDatabaseProxyConfiguration = .init()) {
        self.database = database
        self.configuration = configuration
    }
}

// MARK: - Private helpers
@available(iOS 13.0, *)
private extension CKDatabaseProxy {
    func markWrite() {
        lock.lock()
        lastWriteDate = Date()
        lock.unlock()
    }

    func enforceCooldown() async {
        lock.lock()
        let last = lastWriteDate
        lock.unlock()

        guard let last else { return }
        let elapsed = Date().timeIntervalSince(last)
        let wait = configuration.cooldown - elapsed
        if wait > 0 {
            try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
        }
    }

    func performWithRetry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var attempt = 0
        var backoff: TimeInterval = 1

        while true {
            do {
                return try await operation()
            } catch let error as CKError {
                let retryAfter = error.userInfo[CKErrorRetryAfterKey] as? TimeInterval
                if attempt < configuration.maxRetries, retryAfter != nil {
                    let delay = max(retryAfter ?? 0, backoff)
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    backoff *= 2
                    attempt += 1
                    continue
                }
                throw error
            } catch {
                throw error
            }
        }
    }
}

@available(iOS 13.0, *)
public extension CKDatabaseProxy {
    /// Fetches a CKRecord by ID asynchronously with retry support.
    func fetchRecord(id: CKRecord.ID) async throws -> CKRecord {
        try await performWithRetry {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKRecord, Error>) in
                self.database.fetch(withRecordID: id) { record, error in
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
    }

    /// Saves a CKRecord asynchronously respecting cooldowns and retries.
    func saveRecord(_ record: CKRecord) async throws -> CKRecord {
        await enforceCooldown()
        let result: CKRecord = try await performWithRetry {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKRecord, Error>) in
                self.database.save(record) { saved, error in
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
        markWrite()
        return result
    }

    /// Deletes a CKRecord by its record ID asynchronously with cooldown and retry.
    func deleteRecord(id: CKRecord.ID) async throws {
        await enforceCooldown()
        try await performWithRetry {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                self.database.delete(withRecordID: id) { _, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
        }
        markWrite()
    }

    /// Queries records matching the given predicate, sort descriptors, and optional zone with retry support.
    func queryRecords(recordType: String,
                      predicate: NSPredicate,
                      sortDescriptors: [NSSortDescriptor]? = nil,
                      zoneID: CKRecordZone.ID? = nil) async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: predicate)
        if let sorts = sortDescriptors { query.sortDescriptors = sorts }
        let operation = CKQueryOperation(query: query)
        if let zoneID = zoneID { operation.zoneID = zoneID }
        var results: [CKRecord] = []
        operation.recordFetchedBlock = { results.append($0) }
        return try await performWithRetry {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CKRecord], Error>) in
                operation.queryCompletionBlock = { _, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: results)
                    }
                }
                self.database.add(operation)
            }
        }
    }
}
