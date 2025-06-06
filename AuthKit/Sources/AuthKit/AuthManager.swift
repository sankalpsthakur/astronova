import Foundation
import CloudKit
import CloudKitKit
import AuthenticationServices
import Combine

// MARK: – Public Types

/// High-level authentication state exposed to the SwiftUI layer.
public enum AuthState {
    case loading
    case signedOut
    case needsProfileSetup
    case signedIn
}

/// Manages Sign-in with Apple, persists credentials in Keychain, and guarantees the
/// user has a private CloudKit `UserProfile` record.  Publishes the current
/// `AuthState` so that UI can reactively present the onboarding or main tabs.
public final class AuthManager: ObservableObject {
    // MARK: Published State

    @Published public private(set) var state: AuthState = .loading

    // MARK: Init

    public init() {
        Task { @MainActor in
            await bootstrap()
        }
    }

    // MARK: Public API

    /// Triggers the Sign in with Apple flow and transitions to **signed-in** on success.
    @MainActor
    public func requestSignIn() async {
        do {
            // Start Apple flow.
            let credential = try await AppleSignInCoordinator().signIn()

            // Persist tokens in the Keychain.
            try KeychainHelper.store(credential.idToken, for: Self.kIDTokenKey)
            try KeychainHelper.store(credential.userID, for: Self.kUserIDKey)

            // Check if profile setup is needed.
            do {
                let needsSetup = try await checkProfileSetupNeeded()
                state = needsSetup ? .needsProfileSetup : .signedIn
            } catch {
                print("[AuthManager] Profile check failed: \(error)")
                throw error
            }
        } catch {
            // Fall back to signed-out so user can retry.
            state = .signedOut
            print("[AuthManager] Sign-in failed: \(error)")
        }
    }

    /// Signs the user out, wipes private CloudKit data, and clears Keychain.
    @MainActor
    public func signOut() async {
        do {
            try KeychainHelper.delete(Self.kIDTokenKey)
            try KeychainHelper.delete(Self.kUserIDKey)
            try await CKContainer.cosmic.wipePrivateZone()
        } catch {
            print("[AuthManager] Sign-out error: \(error)")
        }
        state = .signedOut
    }

    /// Checks if the saved Apple credential is still valid; if it was revoked we force sign-out.
    @MainActor
    public func refreshCredentialState() async {
        guard let userID = try? KeychainHelper.retrieve(Self.kUserIDKey) else {
            state = .signedOut
            return
        }

        do {
            let credentialState = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorizationAppleIDProvider.CredentialState, Error>) in
                ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { s, err in
                    if let err = err { continuation.resume(throwing: err) }
                    else { continuation.resume(returning: s) }
                }
            }

            switch credentialState {
            case .authorized: 
                let needsSetup = try await checkProfileSetupNeeded()
                state = needsSetup ? .needsProfileSetup : .signedIn
            default:          
                await signOut()
            }
        } catch {
            print("[AuthManager] Credential check failed: \(error)")
            state = .signedOut
        }
    }

    /// Convenience.
    public var isSignedIn: Bool { state == .signedIn }
    
    /// Call this after the user completes profile setup to transition to signed-in state.
    @MainActor
    public func completeProfileSetup() {
        state = .signedIn
    }

    // MARK: – Private helpers

    private static let kUserIDKey  = "astronova.userID"
    private static let kIDTokenKey = "astronova.idToken"

    /// Determines initial state on launch.
    @MainActor
    private func bootstrap() async {
        // If we have no stored userID we’re definitely signed-out.
        guard (try? KeychainHelper.retrieve(Self.kUserIDKey)) != nil else {
            state = .signedOut
            return
        }

        // Check state asynchronously; default to loading while it happens.
        state = .loading
        await refreshCredentialState()
    }

    /// Checks if the user needs to complete their profile setup.
    @MainActor
    private func checkProfileSetupNeeded() async throws -> Bool {
        let container = CKContainer.cosmic
        let accountStatus = try await container.accountStatus()
        guard accountStatus == .available else {
            throw CKError(.notAuthenticated)
        }
        let recordID = try await container.fetchUserRecordID()

        do {
            let record = try await CKDatabaseProxy.private.fetchRecord(id: recordID)
            // Check if essential profile fields are missing
            return record["fullName"] == nil || 
                   record["birthDate"] == nil || 
                   record["birthPlace"] == nil ||
                   record["sunSign"] == nil
        } catch let error as CKError where error.code == .unknownItem {
            // First launch – create stub profile and indicate setup is needed.
            let record = CKRecord(recordType: "UserProfile", recordID: recordID)
            record["createdAt"] = Date() as CKRecordValue
            record["updatedAt"] = Date() as CKRecordValue
            try await CKDatabaseProxy.private.saveRecord(record)
            return true
        }
    }
}
