import Foundation
@testable import PointOfSale
import struct Yosemite.Order

final class MockPOSPaymentOrderProvider: POSPaymentOrderProviding {
    var orderToReturn: Order?
    var errorToThrow: Error?
    var provideOrderCallCount = 0

    func provideOrder() async throws -> Order {
        provideOrderCallCount += 1
        if let error = errorToThrow { throw error }
        guard let order = orderToReturn else { throw POSPaymentError.noOrder }
        return order
    }
}
