#if DEBUG
import enum Yosemite.OrderFactory
import struct Yosemite.Order
import Combine

class PointOfSalePreviewOrderController: PointOfSaleOrderControllerProtocol {
    var orderStatePublisher: AnyPublisher<PointOfSaleInternalOrderState, Never> = Just(
        .loaded(
            .init(cartTotal: "$10.50",
                  orderTotal: "$12.00",
                  taxTotal: "$1.50"),
            OrderFactory.emptyNewOrder
        )
    ).eraseToAnyPublisher()

    var order: Yosemite.Order?

    func syncOrder(for cartProducts: [CartItem],
                   retryHandler: @escaping () async -> Void) async { }

    func sendReceipt(recipientEmail: String) async throws { }

    func clearOrder() { }
}
#endif
