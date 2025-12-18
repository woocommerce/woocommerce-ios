@testable import Yosemite

final class MockPOSRefundsService: POSRefundsServiceProtocol {
    var spyProvidePointOfSaleRefundsOrder: Yosemite.POSOrder?
    var providePointOfSaleRefundsToReturn: [Yosemite.POSRefund] = []
    var errorToThrow: Error?

    func providePointOfSaleRefunds(for order: Yosemite.POSOrder) async throws -> [Yosemite.POSRefund] {
        spyProvidePointOfSaleRefundsOrder = order
        if let error = errorToThrow {
            throw error
        }
        return providePointOfSaleRefundsToReturn
    }
}
