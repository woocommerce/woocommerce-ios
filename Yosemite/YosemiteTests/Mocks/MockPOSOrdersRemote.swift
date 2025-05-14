import Networking

final class MockPOSOrdersRemote: POSOrdersRemoteProtocol {
    var updatePOSOrderCalled: Bool = false
    var spyUpdatePOSOrder: Order?
    var spyUpdatePOSOrderFields: [OrdersRemote.UpdateOrderField]?
    var spyUpdatePOSOrderCashPaymentChangeDueAmount: String?
    var updatePOSOrderResult: Result<Order, Error> = .success(Order.fake())
    func updatePOSOrder(siteID: Int64,
                        order: Order,
                        cashPaymentChangeDueAmount: String?,
                        fields: [OrdersRemote.UpdateOrderField]) async throws -> Order {
        updatePOSOrderCalled = true
        spyUpdatePOSOrder = order
        spyUpdatePOSOrderFields = fields
        spyUpdatePOSOrderCashPaymentChangeDueAmount = cashPaymentChangeDueAmount
        switch updatePOSOrderResult {
        case .success(let updatedOrder):
            return updatedOrder
        case .failure(let error):
            throw error
        }
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
