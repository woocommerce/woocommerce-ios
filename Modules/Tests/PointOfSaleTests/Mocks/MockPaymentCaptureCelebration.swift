@testable import PointOfSale
import protocol Yosemite.PaymentCaptureCelebrationProtocol

final class MockPaymentCaptureCelebration: PaymentCaptureCelebrationProtocol {
    private(set) var celebrationWasCalled: Bool = false

    func celebrate() {
        celebrationWasCalled = true
    }
}
