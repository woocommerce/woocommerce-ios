import Networking

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
    var spyCreatePOSOrder: Order?
    var spyCreatePOSOrderFields: [OrdersRemote.CreateOrderField]?
    func createPOSOrder(siteID: Int64,
                        order: Networking.Order,
                        fields: [OrdersRemote.CreateOrderField]) async throws -> Order {
        createPOSOrderCalled = true
        spyCreatePOSOrder = order
        spyCreatePOSOrderFields = fields
        return Order.fake()
    }
}
