import Foundation
@testable import PointOfSale
import struct Yosemite.Order

final class MockPOSPaymentOrderProvider: POSPaymentOrderProviding {
    var orderToReturn: Order?
    var formattedTotalToReturn: String = "$0.00"
    var totalDecimalToReturn: Decimal = 0
    var errorToThrow: Error?
    var provideOrderCallCount = 0

    func provideOrder() async throws -> POSPaymentOrder {
        provideOrderCallCount += 1
        if let error = errorToThrow { throw error }
        guard let order = orderToReturn else { throw POSPaymentError.noOrder }
        return POSPaymentOrder(order: order,
                               formattedTotal: formattedTotalToReturn,
                               totalDecimal: totalDecimalToReturn)
    }
}
