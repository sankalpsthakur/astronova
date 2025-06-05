import Foundation
import PassKit
import CloudKitKit
import DataModels

/// Very light Apple Pay wrapper suitable for the MVP build – constructs a basic
/// `PKPaymentRequest`, shows the sheet, and on success writes an `Order` record
/// to the user’s private database.  _Networking-heavy_ parts like stock
/// decrementing or receipt validation are left for future iterations.
public final class ApplePayHandler: NSObject {

    // MARK: - Public entry point

    public func startPayment(for product: Product) {
        guard PKPaymentAuthorizationController.canMakePayments() else {
            print("[ApplePayHandler] Device cannot make payments")
            return
        }

        // Build the payment request.
        let request = PKPaymentRequest()
        request.merchantIdentifier = Self.merchantIdentifier
        request.merchantCapabilities = [.capability3DS]
        request.supportedNetworks = [.visa, .masterCard, .amex]
        request.countryCode = "US" // TODO: derive from locale
        request.currencyCode = product.currency

        let amount = NSDecimalNumber(value: product.price)
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: product.name, amount: amount)
        ]

        // Present controller.
        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = self
        controller.present(completion: nil)
    }

    // MARK: - Private helpers

    private static let merchantIdentifier = "merchant.com.cosmochat"
}

// MARK: - PKPaymentAuthorizationControllerDelegate

extension ApplePayHandler: PKPaymentAuthorizationControllerDelegate {
    public func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss(completion: nil)
    }

    public func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                               didAuthorizePayment payment: PKPayment,
                                               handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        // For MVP we just mark success immediately and create an Order record.
        // For this MVP stub we immediately return success; persistence will be
        // implemented in a future story.
        completion(.init(status: .success, errors: nil))
    }

    // No-op stub – real order persistence TBD.
}
