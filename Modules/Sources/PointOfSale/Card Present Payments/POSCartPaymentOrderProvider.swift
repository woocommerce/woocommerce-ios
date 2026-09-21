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
                               totalDecimal: totals.orderTotalDecimal,
                               paymentURL: order.paymentURL)
    }

    /// Promotes the order to `.pending` so the backend populates `paymentURL`, then returns
    /// the refreshed order for scan-to-pay rendering.
    func provideOrderForScanToPay() async throws -> POSPaymentOrder {
        guard case let .loaded(totals, _) = orderController.orderState else {
            throw POSPaymentError.noOrder
        }
        let promoted = try await orderController.promoteCurrentOrderToPending()
        return POSPaymentOrder(order: promoted,
                               formattedTotal: totals.orderTotal,
                               totalDecimal: totals.orderTotalDecimal,
                               paymentURL: promoted.paymentURL)
    }
}
