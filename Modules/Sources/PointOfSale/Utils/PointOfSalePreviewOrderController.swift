#if DEBUG
import enum Yosemite.OrderFactory
import struct Yosemite.Order
import Combine

class PointOfSalePreviewOrderController: PointOfSaleOrderControllerProtocol {
    var orderState: PointOfSaleInternalOrderState = .loaded(
        .init(cartTotal: "$10.50",
              orderTotal: "$12.00",
              taxTotal: "$1.50",
              orderTotalDecimal: 12.00),
        OrderFactory.newOrder(currency: .USD)
    )

    func syncOrder(for cart: Cart, retryHandler: @escaping () async -> Void) async -> Result<SyncOrderState, Error> {
        return .success(.newOrder)
    }

    func sendReceipt(recipientEmail: String) async throws { }

    func clearOrder() { }

    func collectCashPayment(changeDueAmount: String?) async throws {}
}
#endif
