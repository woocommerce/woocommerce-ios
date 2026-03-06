import Foundation

public protocol POSReceiptsRemoteProtocol {
    func sendReceipt(siteID: Int64, orderID: Int64) async throws
    func sendPOSReceipt(siteID: Int64, orderID: Int64, emailAddress: String) async throws
}

public protocol POSOrdersRemoteProtocol {
    func updatePOSOrder(siteID: Int64,
                        order: Order,
                        cashPaymentChangeDueAmount: String?,
                        fields: [OrdersRemote.UpdateOrderField]) async throws -> Order

    func updatePOSOrderEmail(siteID: Int64,
                             orderID: Int64,
                             emailAddress: String) async throws

    func createPOSOrder(siteID: Int64,
                        order: Order,
                        fields: [OrdersRemote.CreateOrderField]) async throws -> Order

    func loadPOSOrder(siteID: Int64, orderID: Int64) async throws -> Order

    func loadPOSOrders(siteID: Int64, orderIDs: [Int64]) async throws -> [Order]

    func loadPOSOrders(siteID: Int64,
                       pageNumber: Int,
                       pageSize: Int) async throws -> PagedItems<Order>

    func searchPOSOrders(siteID: Int64,
                         searchTerm: String,
                         pageNumber: Int,
                         pageSize: Int) async throws -> PagedItems<Order>
}
