import Foundation
@testable import PointOfSale
import struct Yosemite.Order

final class MockPOSMarkAsPaidHandler: POSMarkAsPaidHandling {
    var markOrderAsPaidCalled = false
    var markOrderAsPaidReceivedOrder: Order?
    var markOrderAsPaidReceivedNote: String?
    var errorToThrow: Error?

    func markOrderAsPaid(for order: Order, note: String?) async throws {
        markOrderAsPaidCalled = true
        markOrderAsPaidReceivedOrder = order
        markOrderAsPaidReceivedNote = note
        if let error = errorToThrow { throw error }
    }
}
