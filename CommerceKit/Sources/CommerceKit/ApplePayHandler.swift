import Foundation
import PassKit
import CloudKit
import CloudKitKit
import DataModels

/// Very light Apple Pay wrapper suitable for the MVP build – constructs a basic
/// `PKPaymentRequest`, shows the sheet, and on success writes an `Order` record
/// to the user’s private database.  _Networking-heavy_ parts like stock
/// decrementing or receipt validation are left for future iterations.
public final class ApplePayHandler: NSObject {

    private let orderRepository: OrderRepository
    private var currentProduct: Product?
    private var resultHandler: ((Result<Void, Error>) -> Void)?

    public init(orderRepository: OrderRepository = OrderRepository()) {
        self.orderRepository = orderRepository
    }

    // MARK: - Public entry point

    public func startPayment(for product: Product,
                             completion: @escaping (Result<Void, Error>) -> Void) {
        self.currentProduct = product
        self.resultHandler = completion
        guard PKPaymentAuthorizationController.canMakePayments() else {
            print("[ApplePayHandler] Device cannot make payments")
            completion(.failure(NSError(domain: "ApplePay", code: 0, userInfo: [NSLocalizedDescriptionKey: "Device cannot make payments"])))
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

    private func decrementStock(for product: Product) async throws {
        let zone = CKRecordZone.ID(zoneName: "Shop", ownerName: CKCurrentUserDefaultName)
        let id = CKRecord.ID(recordName: product.sku, zoneID: zone)
        var attempts = 0

        while true {
            attempts += 1
            var record = try await CKDatabaseProxy.public.fetchRecord(id: id)
            let current = record["stock"] as? Int ?? 0
            record["stock"] = max(current - 1, 0) as CKRecordValue

            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    let op = CKModifyRecordsOperation(recordsToSave: [record])
                    op.savePolicy = .ifServerRecordUnchanged
                    op.modifyRecordsResultBlock = { result in
                        switch result {
                        case .success:
                            continuation.resume(returning: ())
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                    CKContainer.cosmic.publicCloudDatabase.add(op)
                }
                break
            } catch let ckError as CKError where ckError.code == .serverRecordChanged && attempts < 3 {
                continue
            } catch {
                throw error
            }
        }
    }
}

// MARK: - PKPaymentAuthorizationControllerDelegate

extension ApplePayHandler: PKPaymentAuthorizationControllerDelegate {
    public func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss(completion: nil)
        currentProduct = nil
        resultHandler = nil
    }

    public func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                               didAuthorizePayment payment: PKPayment,
                                               handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        guard let product = currentProduct else {
            completion(.init(status: .failure, errors: nil))
            resultHandler?(.failure(NSError(domain: "ApplePay", code: 1, userInfo: nil)))
            return
        }

        Task {
            do {
                try await decrementStock(for: product)

                var record = CKRecord(recordType: Order.recordType)
                record["productSKU"] = product.sku as CKRecordValue
                record["quantity"] = 1 as CKRecordValue
                record["totalAmount"] = product.price as CKRecordValue
                record["currency"] = product.currency as CKRecordValue

                let order = try Order(record: record)
                try await orderRepository.save(order)

                completion(.init(status: .success, errors: nil))
                resultHandler?(.success(()))
            } catch {
                completion(.init(status: .failure, errors: [error]))
                resultHandler?(.failure(error))
            }
        }
    }

}
