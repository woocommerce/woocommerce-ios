import Foundation
import enum Yosemite.OrderStatusEnum
@testable import WooCommerce

final class MockReceiptEligibilityUseCase: ReceiptEligibilityUseCaseProtocol {
    var isEligibleForBackendReceipts: Bool = true
    var isEligibleForSuccessfulPaymentEmailReceipts: Bool = false
    var isEligibleForFailedPaymentEmailReceipts: Bool = false
    var isEligibleForReceipt: Bool = true

    var mockIsEligibleForBackendReceiptsHandler: ((@escaping (Bool) -> Void) -> Void)?

    func isEligibleForBackendReceipts(onCompletion: @escaping (Bool) -> Void) {
        if let handler = mockIsEligibleForBackendReceiptsHandler {
            handler(onCompletion)
        } else {
            onCompletion(isEligibleForBackendReceipts)
        }
    }

    func isEligibleForSuccessfulPaymentEmailReceipts(onCompletion: @escaping (Bool) -> Void) {
        onCompletion(isEligibleForSuccessfulPaymentEmailReceipts)
    }

    func isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: String, onCompletion: @escaping (Bool) -> Void) {
        onCompletion(isEligibleForFailedPaymentEmailReceipts)
    }

    func isEligibleForReceipt(_ orderStatus: OrderStatusEnum, datePaid: Date?, onCompletion: @escaping (Bool) -> Void) {
        onCompletion(isEligibleForReceipt)
    }
}
