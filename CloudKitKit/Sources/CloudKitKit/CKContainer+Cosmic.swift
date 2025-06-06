import CloudKit

/// Provides the shared CloudKit container for Astronova.
@available(iOS 13.0, *)
public extension CKContainer {
    /// Astronova CloudKit container (iCloud.com.sankalp.astronova).
    static var cosmic: CKContainer {
        CKContainer(identifier: "iCloud.com.sankalp.astronova")
    }
    /// Fetches the current user's record ID asynchronously.
    func fetchUserRecordID() async throws -> CKRecord.ID {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKRecord.ID, Error>) in
            self.fetchUserRecordID { recordID, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let recordID = recordID {
                    continuation.resume(returning: recordID)
                } else {
                    let err = NSError(domain: "CloudKitKit",
                                      code: 0,
                                      userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user record ID"])
                    continuation.resume(throwing: err)
                }
            }
        }
    }
    /// Deletes the user's private zone and its data (for sign-out or GDPR purge).
    func wipePrivateZone() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let zoneID = CKRecordZone.default().zoneID
            privateCloudDatabase.delete(withRecordZoneID: zoneID) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}