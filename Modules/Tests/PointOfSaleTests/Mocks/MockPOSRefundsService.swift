@testable import Yosemite

final class MockPOSRefundsService: POSRefundsServiceProtocol {
    var spyProvidePointOfSaleRefundsOrder: Yosemite.POSOrder?
    var providePointOfSaleRefundsResultToReturn: Yosemite.POSRefundsResult = POSRefundsResult(refunds: [], isFullyRefunded: false, supportsAutomaticRefund: true)
    var errorToThrow: Error?

    func providePointOfSaleRefunds(for order: Yosemite.POSOrder) async throws -> Yosemite.POSRefundsResult {
        spyProvidePointOfSaleRefundsOrder = order
        if let error = errorToThrow { throw error }
        return providePointOfSaleRefundsResultToReturn
    }

    // MARK: - calculateRefundAmounts

    var calculateRefundAmountsStub: POSRefundAmounts?
    private let calculator = POSRefundCalculator()

    func calculateRefundAmounts(for items: [Yosemite.POSRefundableItem]) -> POSRefundAmounts {
        if let stub = calculateRefundAmountsStub {
            return stub
        }
        return calculator.calculateRefundAmounts(for: items, numberOfDecimals: 2)
    }

    // MARK: - loadOrderRefunds

    var loadOrderRefundsResultToReturn: [POSOrderRefund] = []
    var loadOrderRefundsErrorToThrow: Error?
    var onLoadOrderRefundsCalled: (@MainActor (Yosemite.POSOrder) -> Void)?

    @MainActor
    func loadOrderRefunds(for order: Yosemite.POSOrder) async throws -> [POSOrderRefund] {
        onLoadOrderRefundsCalled?(order)
        if let error = loadOrderRefundsErrorToThrow {
            throw error
        }
        return loadOrderRefundsResultToReturn
    }

}
