@testable import Yosemite

final class MockPOSRefundsService: POSRefundsServiceProtocol {
    var spyProvidePointOfSaleRefundsOrder: Yosemite.POSOrder?
    var providePointOfSaleRefundsResultToReturn: Yosemite.POSRefundsResult = POSRefundsResult(refunds: [], isFullyRefunded: false, supportsAutomaticRefund: true)
    var errorToThrow: Error?
    private(set) var providePointOfSaleRefundsCallCount = 0

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
        providePointOfSaleRefundsCallCount += 1
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
