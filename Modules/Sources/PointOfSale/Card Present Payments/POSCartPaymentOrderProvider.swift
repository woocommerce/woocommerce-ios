import struct Yosemite.Order

/// Provides the already-synced order from the POS cart order controller.
struct POSCartPaymentOrderProvider: POSPaymentOrderProviding {
    let orderController: PointOfSaleOrderControllerProtocol

    func provideOrder() async throws -> Order {
        guard case let .loaded(_, order) = orderController.orderState else {
            throw POSPaymentError.noOrder
        }
        return order
    }
}
