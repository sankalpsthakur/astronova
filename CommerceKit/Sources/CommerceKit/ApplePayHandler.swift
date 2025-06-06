import Foundation
import PassKit
import DataModels

/// Apple Pay handler for product display only - no actual purchases.
public final class ApplePayHandler: NSObject {

    public init() {}

    // MARK: - Public entry point

    public func startPayment(for product: Product,
                             completion: ((Result<Void, Error>) -> Void)? = nil) {
        // Payments disabled - display only mode
        completion?(.failure(NSError(domain: "ApplePay", code: 0, userInfo: [NSLocalizedDescriptionKey: "Purchase functionality disabled"])))
    }
}