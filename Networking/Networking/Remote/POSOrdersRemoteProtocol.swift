import Foundation

public protocol POSReceiptsRemoteProtocol {
    func sendPOSReceipt(siteID: Int64, orderID: Int64) async throws
}

public protocol POSOrdersRemoteProtocol {
    func updatePOSOrder(siteID: Int64,
                        order: Order,
                        fields: [OrdersRemote.UpdateOrderField]) async throws -> Order

    func createPOSOrder(siteID: Int64,
                        order: Order,
                        fields: [OrdersRemote.CreateOrderField]) async throws -> Order
}
