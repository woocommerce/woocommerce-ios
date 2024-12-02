import Foundation

public protocol POSOrdersRemoteProtocol {
    func updatePOSOrder(siteID: Int64,
                        order: Order,
                        fields: [OrdersRemote.UpdateOrderField]) async throws -> Order

    func createPOSOrder(siteID: Int64,
                        order: Order,
                        fields: [OrdersRemote.CreateOrderField]) async throws -> Order
}
