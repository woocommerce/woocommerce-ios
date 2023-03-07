@testable import WooCommerce

struct MockPaymentCaptureCelebration: PaymentCaptureCelebrationProtocol {
    func celebrate() {
        // no-op
    }
}
