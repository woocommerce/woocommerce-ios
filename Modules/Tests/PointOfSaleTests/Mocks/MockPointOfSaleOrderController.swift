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

    var confirmScanToPayPaymentWasCalled = false
    var confirmScanToPayPaymentErrorToThrow: Error?
    func confirmScanToPayPayment() async throws {
        confirmScanToPayPaymentWasCalled = true
        if let confirmScanToPayPaymentErrorToThrow {
            throw confirmScanToPayPaymentErrorToThrow
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

    var reloadCurrentOrderWasCalled = false
    var reloadCurrentOrderResult: Result<Order, Error> = .success(.fake())
    func reloadCurrentOrder() async throws -> Order {
        reloadCurrentOrderWasCalled = true
        switch reloadCurrentOrderResult {
        case .success(let order):
            return order
        case .failure(let error):
            throw error
        }
    }

    var promoteCurrentOrderToPendingWasCalled = false
    var promoteCurrentOrderToPendingResult: Result<Order, Error> = .success(.fake())
    func promoteCurrentOrderToPending() async throws -> Order {
        promoteCurrentOrderToPendingWasCalled = true
        switch promoteCurrentOrderToPendingResult {
        case .success(let order):
            return order
        case .failure(let error):
            throw error
        }
    }
}
