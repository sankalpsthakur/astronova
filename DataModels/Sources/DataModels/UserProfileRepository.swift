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
        let record = profile.toRecord(in: recordID.zoneID)
        record.recordID = recordID
        try await CKDatabaseProxy.private.saveRecord(record)
        currentProfile = profile
    }
}