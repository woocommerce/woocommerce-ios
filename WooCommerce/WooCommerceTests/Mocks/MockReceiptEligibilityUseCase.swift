@testable import WooCommerce

final class MockReceiptEligibilityUseCase: ReceiptEligibilityUseCaseProtocol {
    var isEligibleForBackendReceipts: Bool = true

    func isEligibleForBackendReceipts(onCompletion: @escaping (Bool) -> Void) {
        onCompletion(isEligibleForBackendReceipts)
    }
}
