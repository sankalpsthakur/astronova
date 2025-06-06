import Foundation
import StoreKit
import CloudKit
import CloudKitKit
import DataModels
import Combine

/// Manages StoreKit 2 subscription purchases and entitlement checks.
public final class StoreKitPlusManager: ObservableObject {
    @Published public private(set) var plusExpiry: Date?

    private var updatesTask: Task<Void, Never>?
    private static let productID = "com.sankalp.astronova.plus.yearly"

    public init() {
        updatesTask = Task { await listenForTransactions() }
        Task { await loadCurrentEntitlement() }
    }

    deinit { updatesTask?.cancel() }

    /// Starts subscription purchase flow using StoreKit 2.
    public func purchaseSubscription() async throws {
        let products = try await Product.products(for: [Self.productID])
        guard let product = products.first else { return }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateEntitlement(from: transaction)
            await transaction.finish()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    /// Returns true if the user currently has an active Plus entitlement.
    public func hasActiveEntitlement() -> Bool {
        guard let expiry = plusExpiry else { return false }
        return expiry > Date()
    }

    /// Publisher for entitlement changes.
    public var entitlementPublisher: AnyPublisher<Bool, Never> {
        $plusExpiry
            .map { expiry in
                guard let expiry = expiry else { return false }
                return expiry > Date()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private helpers

    private func listenForTransactions() async {
        for await update in Transaction.updates {
            do {
                let transaction = try checkVerified(update)
                await updateEntitlement(from: transaction)
                await transaction.finish()
            } catch {
                print("[StoreKitPlusManager] transaction update error: \(error)")
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    private func updateEntitlement(from transaction: Transaction) async {
        let expiry = transaction.expirationDate
        do {
            try await saveExpiry(expiry)
        } catch {
            print("[StoreKitPlusManager] failed to save expiry: \(error)")
        }
    }

    private func saveExpiry(_ expiry: Date?) async throws {
        let id = try await CKContainer.cosmic.fetchUserRecordID()
        let record = try await CKDatabaseProxy.private.fetchRecord(id: id)
        if let expiry = expiry {
            record["plusExpiry"] = expiry as CKRecordValue
        } else {
            record["plusExpiry"] = nil as CKRecordValue?
        }
        _ = try await CKDatabaseProxy.private.saveRecord(record)
        await MainActor.run { self.plusExpiry = expiry }
    }

    private func loadCurrentEntitlement() async {
        do {
            let id = try await CKContainer.cosmic.fetchUserRecordID()
            let profile: UserProfile = try await CKDatabaseProxy.private.fetch(type: UserProfile.self, id: id)
            await MainActor.run { self.plusExpiry = profile.plusExpiry }
        } catch {
            print("[StoreKitPlusManager] failed to load entitlement: \(error)")
        }
    }
}

