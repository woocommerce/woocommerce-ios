@testable import WooCommerce

final class MockReceiptEligibilityUseCase: ReceiptEligibilityUseCaseProtocol {
    var isEligibleForBackendReceipts: Bool = true
    var isEligibleSendingReceiptAfterPayment: Bool = false

    func isEligibleForBackendReceipts(onCompletion: @escaping (Bool) -> Void) {
        onCompletion(isEligibleForBackendReceipts)
    }

    func isEligibleSendingReceiptAfterPayment(onCompletion: @escaping (Bool) -> Void) {
        onCompletion(isEligibleSendingReceiptAfterPayment)
    }
}
