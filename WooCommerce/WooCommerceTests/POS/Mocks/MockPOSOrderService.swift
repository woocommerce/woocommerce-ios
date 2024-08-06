import Foundation
@testable import Yosemite

class MockPOSOrderService: POSOrderServiceProtocol {
    var orderToReturn: Order?
    func syncOrder(cart: [Yosemite.POSCartItem], order: Yosemite.Order?, allProducts: [any Yosemite.POSItem]) async throws -> Yosemite.Order {
        guard let order = orderToReturn else {
            throw MockPOSOrderServiceError.noOrderToReturn
        }
        return order
    }
}

enum MockPOSOrderServiceError: Error {
    case noOrderToReturn
}
