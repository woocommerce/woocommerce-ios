#if DEBUG
import Foundation
import enum Yosemite.OrderFactory
import struct Yosemite.Order
import Combine

class PointOfSalePreviewOrderController: PointOfSaleOrderControllerProtocol {
    var orderState: PointOfSaleInternalOrderState

    init(orderState: PointOfSaleInternalOrderState = .loaded(
        .init(cartTotal: "$10.50",
              orderTotal: "$12.00",
              taxTotal: "$1.50",
              orderTotalDecimal: 12.00),
        OrderFactory.newOrder(currency: .USD)
    )) {
        self.orderState = orderState
    }

    func syncOrder(for cart: Cart, retryHandler: @escaping () async -> Void) async -> Result<SyncOrderState, Error> {
        return .success(.newOrder)
    }

    func sendReceipt(recipientEmail: String) async throws { }

    func clearOrder() { }

    func collectCashPayment(changeDueAmount: String?) async throws {}

    func markOrderAsPaidManually(note: String?) async throws {}

    func confirmScanToPayPayment() async throws {}

    func reloadCurrentOrder() async throws -> Order {
        guard case let .loaded(_, order) = orderState else {
            throw NSError(domain: "PointOfSalePreviewOrderController", code: 0)
        }
        return order
    }

    func promoteCurrentOrderToPending() async throws -> Order {
        guard case let .loaded(_, order) = orderState else {
            throw NSError(domain: "PointOfSalePreviewOrderController", code: 0)
        }
        return order
    }
}
#endif
