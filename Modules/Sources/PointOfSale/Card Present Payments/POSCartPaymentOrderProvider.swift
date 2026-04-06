import struct Yosemite.Order

/// Provides the already-synced order from the POS cart order controller.
struct POSCartPaymentOrderProvider: POSPaymentOrderProviding {
    let orderController: PointOfSaleOrderControllerProtocol

    func provideOrder() async throws -> POSPaymentOrder {
        guard case let .loaded(totals, order) = orderController.orderState else {
            throw POSPaymentError.noOrder
        }
        return POSPaymentOrder(order: order,
                               formattedTotal: totals.orderTotal,
                               totalDecimal: totals.orderTotalDecimal)
    }
}
