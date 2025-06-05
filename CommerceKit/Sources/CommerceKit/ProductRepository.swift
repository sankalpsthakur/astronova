import Foundation
import CloudKit
import CloudKitKit
import Combine
import DataModels

/// Simple repository that loads `Product` items from the public CloudKit database and caches them in-memory.
public final class ProductRepository: ObservableObject {
    @Published public private(set) var products: [Product] = []

    public init() {}

    /// Fetches active catalog items.
    @MainActor
    public func refresh() async {
        do {
            let fetched: [Product] = try await CKDatabaseProxy.public.query(
                type: Product.self,
                predicate: NSPredicate(format: "active == TRUE"),
                sortDescriptors: [NSSortDescriptor(key: "sku", ascending: true)],
                zoneID: CKRecordZone.ID(zoneName: "Shop", ownerName: CKCurrentUserDefaultName)
            )
            products = fetched
        } catch {
            print("[ProductRepository] fetch error: \(error)")
        }
    }
}
