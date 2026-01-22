@testable import Yosemite

final class MockPOSRefundsService: POSRefundsServiceProtocol {
    var spyProvidePointOfSaleRefundsOrder: Yosemite.POSOrder?
    var providePointOfSaleRefundsResultToReturn: Yosemite.POSRefundsResult = POSRefundsResult(refunds: [], isFullyRefunded: false)
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

    func createRefund(orderID: Int64, items: [Yosemite.POSRefundableItem], reason: String?) async throws {}
}
