import Foundation
@testable import PointOfSale
import struct Yosemite.Order

final class MockPOSScanToPayHandler: POSScanToPayHandling {
    var completeScanToPayPaymentCalled = false
    var completeScanToPayPaymentReceivedOrder: Order?
    var errorToThrow: Error?

    func completeScanToPayPayment(for order: Order) async throws {
        completeScanToPayPaymentCalled = true
        completeScanToPayPaymentReceivedOrder = order
        if let error = errorToThrow { throw error }
    }

    var recordScanToPayPaymentMethodCalled = false
    var recordScanToPayPaymentMethodReceivedOrder: Order?
    func recordScanToPayPaymentMethod(for order: Order) async {
        recordScanToPayPaymentMethodCalled = true
        recordScanToPayPaymentMethodReceivedOrder = order
    }
}
