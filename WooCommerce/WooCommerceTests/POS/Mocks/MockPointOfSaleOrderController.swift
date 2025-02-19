import Foundation
import Combine

@testable import WooCommerce
import struct Yosemite.Order

final class MockPointOfSaleOrderController: PointOfSaleOrderControllerProtocol {
    func collectCashPayment() async throws {
        // no-op
    }

    var orderStatePublisher: AnyPublisher<PointOfSaleInternalOrderState, Never> {
        $orderState.eraseToAnyPublisher()
    }
    @Published var orderState: PointOfSaleInternalOrderState = .idle
    var orderStateToReturn: PointOfSaleInternalOrderState?

    var syncOrderWasCalled: Bool = false
    var spyCartProducts: [CartItem]?
    var spyRetryHandler: (() async -> Void)?
    var syncOrderResultToReturn: Result<SyncOrderState, Error> = .success(.newOrder)

    @discardableResult
    func syncOrder(for cartProducts: [CartItem],
                   retryHandler: @escaping () async -> Void) async -> Result<SyncOrderState, Error> {
        syncOrderWasCalled = true
        spyCartProducts = cartProducts
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

    func sendReceipt(recipientEmail: String) async { }
}
