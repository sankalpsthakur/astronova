import Foundation
import Combine
import CloudKit
import CloudKitKit
import DataModels

/// Repository for persisting `KundaliMatch` records in the user's private database.
@available(iOS 13.0, *)
public final class SavedMatchRepository: ObservableObject {
    /// Published list of saved matches loaded from CloudKit.
    @Published public private(set) var matches: [KundaliMatch] = []

    public init() {}

    /// Reloads the matches from the private database.
    @MainActor
    public func refresh() async {
        do {
            let fetchedRecords = try await CKDatabaseProxy.private.queryRecords(
                recordType: KundaliMatch.recordType,
                predicate: NSPredicate(value: true)
            )
            let items = try fetchedRecords.map { try KundaliMatch(record: $0) }
            matches = items
        } catch {
            print("[SavedMatchRepository] fetch error: \(error)")
        }
    }

    /// Saves a new match result.
    @MainActor
    public func create(_ match: KundaliMatch) async {
        do {
            _ = try await CKDatabaseProxy.private.save(match)
            await refresh()
        } catch {
            print("[SavedMatchRepository] create error: \(error)")
        }
    }

    /// Updates an existing match by record ID.
    @MainActor
    public func update(id: CKRecord.ID, with newValue: KundaliMatch) async {
        do {
            let record = try await CKDatabaseProxy.private.fetchRecord(id: id)
            record["partnerName"] = newValue.partnerName as CKRecordValue
            record["partnerDOB"] = newValue.partnerDOB as CKRecordValue
            record["scoreTotal"] = newValue.scoreTotal as CKRecordValue
            record["aspectJSON"] = newValue.aspectJSON as CKRecordValue
            _ = try await CKDatabaseProxy.private.saveRecord(record)
            await refresh()
        } catch {
            print("[SavedMatchRepository] update error: \(error)")
        }
    }

    /// Deletes a match by record ID.
    @MainActor
    public func delete(id: CKRecord.ID) async {
        do {
            try await CKDatabaseProxy.private.delete(type: KundaliMatch.self, id: id)
            await refresh()
        } catch {
            print("[SavedMatchRepository] delete error: \(error)")
        }
    }
}
