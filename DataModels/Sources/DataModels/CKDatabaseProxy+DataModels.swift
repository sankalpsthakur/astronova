import Foundation
import CloudKit
import CloudKitKit

@available(iOS 13.0, *)
public extension CKDatabaseProxy {
    /// Fetches and converts a record of the given model type by its record ID.
    func fetch<T: CKRecordConvertible>(type: T.Type, id: CKRecord.ID) async throws -> T {
        let record = try await fetchRecord(id: id)
        return try T(record: record)
    }

    /// Saves a model object and returns the saved instance.
    func save<T: CKRecordConvertible>(_ item: T, zone: CKRecordZone.ID? = nil) async throws -> T {
        let record = item.toRecord(in: zone)
        let saved = try await saveRecord(record)
        return try T(record: saved)
    }

    /// Deletes a record for the given model type by its record ID.
    func delete<T: CKRecordConvertible>(type: T.Type, id: CKRecord.ID) async throws {
        try await deleteRecord(id: id)
    }

    /// Queries and converts records matching the given predicate into model objects.
    func query<T: CKRecordConvertible>(
        type: T.Type,
        predicate: NSPredicate,
        sortDescriptors: [NSSortDescriptor]? = nil,
        zoneID: CKRecordZone.ID? = nil
    ) async throws -> [T] {
        let records = try await queryRecords(
            recordType: T.recordType,
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            zoneID: zoneID
        )
        return try records.map { try T(record: $0) }
    }
}