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

    // MARK: - createRefund

    var createRefundCalled = false
    var spyCreateRefundOrderID: Int64?
    var spyCreateRefundItems: [Yosemite.POSRefundableItem]?
    var spyCreateRefundReason: String?
    var spyCreateRefundAutomaticRefund: Bool?
    var createRefundErrorToThrow: Error?

    func createRefund(orderID: Int64, items: [Yosemite.POSRefundableItem], reason: String?, isAutomaticRefund: Bool) async throws {
        createRefundCalled = true
        spyCreateRefundOrderID = orderID
        spyCreateRefundItems = items
        spyCreateRefundReason = reason
        spyCreateRefundAutomaticRefund = isAutomaticRefund

        if let error = createRefundErrorToThrow {
            throw error
        }
    }
}
