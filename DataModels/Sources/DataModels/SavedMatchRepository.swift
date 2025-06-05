import Foundation
import CloudKit
import CloudKitKit

/// Repository for saving and retrieving `KundaliMatch` records in the private database.
public final class SavedMatchRepository: ObservableObject {
    @Published public private(set) var matches: [KundaliMatch] = []

    private let database: CKDatabaseProxy

    public init(database: CKDatabaseProxy = .private) {
        self.database = database
    }

    /// Persists a match to the user's private CloudKit zone.
    public func save(_ match: KundaliMatch) async throws {
        _ = try await database.save(match, zone: CKRecordZone.default().zoneID)
    }

    /// Fetches a specific saved match by record ID.
    public func load(id: CKRecord.ID) async throws -> KundaliMatch {
        try await database.fetch(type: KundaliMatch.self, id: id)
    }

    /// Refresh the list of saved matches ordered by creation time.
    @MainActor
    public func refresh() async {
        do {
            let items: [KundaliMatch] = try await database.query(
                type: KundaliMatch.self,
                predicate: NSPredicate(value: true),
                sortDescriptors: [NSSortDescriptor(key: "creationDate", ascending: false)],
                zoneID: CKRecordZone.default().zoneID
            )
            matches = items
        } catch {
            print("[SavedMatchRepository] fetch error: \(error)")
        }
    }

    /// Deletes a saved match by its record ID.
    public func delete(id: CKRecord.ID) async throws {
        try await database.delete(type: KundaliMatch.self, id: id)
    }
}
