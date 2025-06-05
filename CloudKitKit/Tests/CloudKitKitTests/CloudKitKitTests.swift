import XCTest
@testable import CloudKitKit

final class CloudKitKitTests: XCTestCase {
    func testExample() throws {
        XCTAssertTrue(true)
    }

    /// Ensures transient errors are retried.
    func testRetryLogic() async throws {
        class MockDatabase: CKDatabase {
            var attempts = 0
            override func save(_ record: CKRecord, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
                attempts += 1
                if attempts == 1 {
                    let err = NSError(domain: CKErrorDomain,
                                      code: CKError.Code.serviceUnavailable.rawValue,
                                      userInfo: [CKErrorRetryAfterKey: 0.0])
                    completionHandler(nil, err)
                } else {
                    completionHandler(record, nil)
                }
            }
        }

        let db = MockDatabase(databaseScope: .private)
        let proxy = CKDatabaseProxy(database: db, configuration: .init(maxRetries: 2, cooldown: 0))
        let record = CKRecord(recordType: "Test")
        let saved = try await proxy.saveRecord(record)
        XCTAssertEqual(saved.recordID.recordName, record.recordID.recordName)
        XCTAssertEqual(db.attempts, 2)
    }
}
