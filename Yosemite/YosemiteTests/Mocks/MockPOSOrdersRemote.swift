import Networking

final class MockReceiptsOrderRemote: POSReceiptsRemoteProtocol {
    func sendReceipt(siteID: Int64, orderID: Int64) async throws { }
}

final class MockPOSOrdersRemote: POSOrdersRemoteProtocol {
    var updatePOSOrderCalled: Bool = false
    var spyUpdatePOSOrder: Order?
    func updatePOSOrder(siteID: Int64,
                        order: Order,
                        fields: [OrdersRemote.UpdateOrderField]) async throws -> Order {
        updatePOSOrderCalled = true
        spyUpdatePOSOrder = order
        return Order.fake()
    }

    var createPOSOrderCalled: Bool = false
    func createPOSOrder(siteID: Int64,
                        order: Networking.Order,
                        fields: [OrdersRemote.CreateOrderField]) async throws -> Order {
        createPOSOrderCalled = true
        return Order.fake()
    }
}
