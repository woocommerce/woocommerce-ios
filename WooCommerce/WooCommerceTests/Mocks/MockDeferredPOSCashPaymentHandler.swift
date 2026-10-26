@testable import PointOfSale
import struct Yosemite.Order

@MainActor
final class MockDeferredPOSCashPaymentHandler: POSCashPaymentHandling {
    var onComplete: (@MainActor () async -> Void)?

    func completeCashPayment(for order: Order, changeDueAmount: String?) async throws {
        await onComplete?()
    }
}
