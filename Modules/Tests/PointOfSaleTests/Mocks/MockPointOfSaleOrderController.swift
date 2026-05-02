import Foundation
import Combine

@testable import PointOfSale
import struct Yosemite.Order

final class MockPointOfSaleOrderController: PointOfSaleOrderControllerProtocol {
    func collectCashPayment(changeDueAmount: String?) async throws {
        // no-op
    }

    var orderState: PointOfSaleInternalOrderState = .idle
    var orderStateToReturn: PointOfSaleInternalOrderState?
    var syncOrderWasCalled: Bool = false
    var spyCartProducts: [Cart.PurchasableItem]?
    var spyRetryHandler: (() async -> Void)?
    var syncOrderResultToReturn: Result<SyncOrderState, Error> = .success(.newOrder)

    @discardableResult
    func syncOrder(for cart: Cart,
                   retryHandler: @escaping () async -> Void) async -> Result<SyncOrderState, Error> {
        syncOrderWasCalled = true
        spyCartProducts = cart.purchasableItems
        spyRetryHandler = retryHandler

        guard let orderStateToReturn else {
            orderState = .syncing
            return syncOrderResultToReturn
        }

        orderState = orderStateToReturn
        return syncOrderResultToReturn
    }

    var clearOrderWasCalled: Bool = false
    func clearOrder() {
        clearOrderWasCalled = true
    }

    var sendReceiptErrorToThrow: Error?
    var sendReceiptWasCalled: Bool = false
    func sendReceipt(recipientEmail: String) async throws {
        sendReceiptWasCalled = true
        if let sendReceiptErrorToThrow {
            throw sendReceiptErrorToThrow
        }
    }

    var markOrderAsPaidManuallyWasCalled = false
    var markOrderAsPaidManuallyErrorToThrow: Error?
    func markOrderAsPaidManually() async throws {
        markOrderAsPaidManuallyWasCalled = true
        if let markOrderAsPaidManuallyErrorToThrow {
            throw markOrderAsPaidManuallyErrorToThrow
        }
    }
}
