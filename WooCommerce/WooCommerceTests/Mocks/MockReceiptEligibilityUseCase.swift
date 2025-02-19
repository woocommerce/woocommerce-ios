@testable import WooCommerce

final class MockReceiptEligibilityUseCase: ReceiptEligibilityUseCaseProtocol {
    var isEligibleForBackendReceipts: Bool = true
    var isEligibleForSuccessfulPaymentEmailReceipts: Bool = false
    var isEligibleForFailedPaymentEmailReceipts: Bool = false

    func isEligibleForBackendReceipts(onCompletion: @escaping (Bool) -> Void) {
        onCompletion(isEligibleForBackendReceipts)
    }

    func isEligibleForSuccessfulPaymentEmailReceipts(onCompletion: @escaping (Bool) -> Void) {
        onCompletion(isEligibleForSuccessfulPaymentEmailReceipts)
    }

    func isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: String, onCompletion: @escaping (Bool) -> Void) {
        onCompletion(isEligibleForFailedPaymentEmailReceipts)
    }
}
