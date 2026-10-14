@testable import PointOfSale
import struct Yosemite.Order

@MainActor
final class MockDeferredPOSCashPaymentHandler: POSCashPaymentHandling {
    var onStarted: (() -> Void)?
    var completion: CheckedContinuation<Void, Never>?

    func completeCashPayment(for order: Order, changeDueAmount: String?) async throws {
        await withCheckedContinuation { continuation in
            completion = continuation
            onStarted?()
        }
    }
}
