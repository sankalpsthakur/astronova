import CloudKit

/// Builds typed CKQuery operations with common defaults.
public final class CKQueryBuilder {
    public init() {}

    /// Placeholder for a typed query builder API.
    public func buildQuery(recordType: String, predicate: NSPredicate) -> CKQuery {
        CKQuery(recordType: recordType, predicate: predicate)
    }
}