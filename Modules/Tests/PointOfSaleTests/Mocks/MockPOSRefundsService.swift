@testable import Yosemite

final class MockPOSRefundsService: POSRefundsServiceProtocol {
    var spyProvidePointOfSaleRefundsOrder: Yosemite.POSOrder?
    var providePointOfSaleRefundsResultToReturn: Yosemite.POSRefundsResult = POSRefundsResult(refunds: [], isFullyRefunded: false, supportsAutomaticRefund: true)
    var errorToThrow: Error?

    private var continuation: CheckedContinuation<Yosemite.POSOrder, Never>?

    var shouldSuspendProvidePointOfSaleRefunds = false
    private var refundsContinuation: CheckedContinuation<Void, Never>?

    func awaitProvidePointOfSaleRefundsCall() async -> Yosemite.POSOrder {
        await withCheckedContinuation { cont in
            continuation = cont
        }
    }

    func resumeProvidePointOfSaleRefunds() {
        refundsContinuation?.resume()
        refundsContinuation = nil
    }

    func providePointOfSaleRefunds(for order: Yosemite.POSOrder) async throws -> Yosemite.POSRefundsResult {
        spyProvidePointOfSaleRefundsOrder = order
        continuation?.resume(returning: order)
        continuation = nil

        if shouldSuspendProvidePointOfSaleRefunds {
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                refundsContinuation = cont
            }
        }

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
