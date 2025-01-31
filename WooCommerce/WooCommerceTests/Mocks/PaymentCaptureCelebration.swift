@testable import WooCommerce

final class MockPaymentCaptureCelebration: PaymentCaptureCelebrationProtocol {
    private(set) var celebrationWasCalled: Bool = false
    
    func celebrate() {
        celebrationWasCalled = true
    }
}
