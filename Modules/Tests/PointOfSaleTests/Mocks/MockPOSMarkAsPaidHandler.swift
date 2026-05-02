import Foundation
@testable import PointOfSale
import struct Yosemite.Order

final class MockPOSMarkAsPaidHandler: POSMarkAsPaidHandling {
    var markOrderAsPaidCalled = false
    var markOrderAsPaidReceivedOrder: Order?
    var errorToThrow: Error?

    func markOrderAsPaid(for order: Order) async throws {
        markOrderAsPaidCalled = true
        markOrderAsPaidReceivedOrder = order
        if let error = errorToThrow { throw error }
    }
}
