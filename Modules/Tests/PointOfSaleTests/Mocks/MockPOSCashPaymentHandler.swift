import Foundation
@testable import PointOfSale
import struct Yosemite.Order

final class MockPOSCashPaymentHandler: POSCashPaymentHandling {
    var completeCashPaymentCalled = false
    var completeCashPaymentReceivedOrder: Order?
    var completeCashPaymentReceivedChangeDue: String?
    var errorToThrow: Error?

    func completeCashPayment(for order: Order, changeDueAmount: String?) async throws {
        completeCashPaymentCalled = true
        completeCashPaymentReceivedOrder = order
        completeCashPaymentReceivedChangeDue = changeDueAmount
        if let error = errorToThrow { throw error }
    }
}
