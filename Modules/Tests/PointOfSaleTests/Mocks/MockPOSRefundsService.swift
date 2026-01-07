@testable import Yosemite

final class MockPOSRefundsService: POSRefundsServiceProtocol {
    var spyProvidePointOfSaleRefundsOrder: Yosemite.POSOrder?
    var providePointOfSaleRefundsToReturn: [Yosemite.POSRefund] = []
    var errorToThrow: Error?

    private var continuation: CheckedContinuation<Yosemite.POSOrder, Never>?

    func awaitProvidePointOfSaleRefundsCall() async -> Yosemite.POSOrder {
        await withCheckedContinuation { cont in
            continuation = cont
        }
    }

    func providePointOfSaleRefunds(for order: Yosemite.POSOrder) async throws -> [Yosemite.POSRefund] {
        spyProvidePointOfSaleRefundsOrder = order
        continuation?.resume(returning: order)
        continuation = nil

        if let error = errorToThrow { throw error }
        return providePointOfSaleRefundsToReturn
    }
}
