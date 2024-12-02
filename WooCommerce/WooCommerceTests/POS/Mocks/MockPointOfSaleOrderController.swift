import Foundation
import Combine

@testable import WooCommerce
import struct Yosemite.Order

final class MockPointOfSaleOrderController: PointOfSaleOrderControllerProtocol {
    var orderStatePublisher: AnyPublisher<PointOfSaleInternalOrderState, Never> {
        $orderState.eraseToAnyPublisher()
    }
    @Published var orderState: PointOfSaleInternalOrderState = .idle
    var orderStateToReturn: PointOfSaleInternalOrderState?

    @Published var order: Order?

    var syncOrderWasCalled: Bool = false
    var spyCartProducts: [CartItem]?
    var spyRetryHandler: (() async -> Void)?
    func syncOrder(for cartProducts: [CartItem],
                   retryHandler: @escaping () async -> Void) async {
        syncOrderWasCalled = true
        spyCartProducts = cartProducts
        spyRetryHandler = retryHandler

        guard let orderStateToReturn else {
            orderState = .syncing
            return
        }

        orderState = orderStateToReturn
        guard case .loaded(_, let orderToReturn) = orderState else {
            order = nil
            return
        }
        order = orderToReturn
    }

    var clearOrderWasCalled: Bool = false
    func clearOrder() {
        clearOrderWasCalled = true
    }

    func sendOrderReceipt(order: Yosemite.Order, toEmailAddress: String) async { }
}
