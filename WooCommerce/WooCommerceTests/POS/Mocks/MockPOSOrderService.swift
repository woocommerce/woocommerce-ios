import Foundation
@testable import Yosemite

class MockPOSOrderService: POSOrderServiceProtocol {
    var simulateSyncing = false
    var orderToReturn: Order?
    func syncOrder(cart: [Yosemite.POSCartItem], order: Yosemite.Order?) async throws -> Yosemite.Order {
        if simulateSyncing {
            try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
        }

        guard let order = orderToReturn else {
            throw MockPOSOrderServiceError.noOrderToReturn
        }
        return order
    }
}

enum MockPOSOrderServiceError: Error {
    case noOrderToReturn
}
