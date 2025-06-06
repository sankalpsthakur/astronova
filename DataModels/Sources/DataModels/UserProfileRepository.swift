import Foundation
import CloudKit
import CloudKitKit
import Combine

/// Repository for accessing the current user's profile data.
public final class UserProfileRepository: ObservableObject {
    @Published public private(set) var currentProfile: UserProfile?
    @Published public private(set) var isLoading = false
    
    public init() {}
    
    /// Fetches the current user's profile from CloudKit.
    @MainActor
    public func fetchCurrentProfile() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let recordID = try await CKContainer.cosmic.fetchUserRecordID()
        let profile: UserProfile = try await CKDatabaseProxy.private.fetch(type: UserProfile.self, id: recordID)
        currentProfile = profile
    }
    
    /// Updates the current user's profile in CloudKit.
    @MainActor
    public func updateProfile(_ profile: UserProfile) async throws {
        let recordID = try await CKContainer.cosmic.fetchUserRecordID()
        let record = CKRecord(recordType: UserProfile.recordType, recordID: recordID)
        
        // Copy profile data to the record
        record["fullName"] = profile.fullName as CKRecordValue
        record["birthDate"] = profile.birthDate as CKRecordValue
        if let time = profile.birthTime {
            record["birthTime"] = time as? CKRecordValue
        }
        record["birthPlace"] = profile.birthPlace as CKRecordValue
        record["sunSign"] = profile.sunSign as CKRecordValue
        record["moonSign"] = profile.moonSign as CKRecordValue
        record["risingSign"] = profile.risingSign as CKRecordValue
        if let expiry = profile.plusExpiry {
            record["plusExpiry"] = expiry as CKRecordValue
        }
        
        try await CKDatabaseProxy.private.saveRecord(record)
        currentProfile = profile
    }
}