import Foundation
import Combine

@testable import WooCommerce
import struct Yosemite.Order

final class MockPointOfSaleOrderController: PointOfSaleOrderControllerProtocol {
    func collectCashPayment(changeDueAmount: String?) async throws {
        // no-op
    }

    var orderStatePublisher: AnyPublisher<PointOfSaleInternalOrderState, Never> {
        $orderState.eraseToAnyPublisher()
    }
    @Published var orderState: PointOfSaleInternalOrderState = .idle
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
    func clearOrder() async {
        clearOrderWasCalled = true
    }

    var shouldThrowReceiptError: Bool = false
    var sendReceiptWasCalled: Bool = false
    func sendReceipt(recipientEmail: String) async throws {
        sendReceiptWasCalled = true
        if shouldThrowReceiptError {
            throw NSError(domain: "some error", code: -1)
        }
    }
}
