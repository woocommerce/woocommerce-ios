import Foundation

public protocol POSReceiptsRemoteProtocol {
    func sendReceipt(siteID: Int64, orderID: Int64) async throws
    func sendPOSReceipt(siteID: Int64, orderID: Int64, emailAddress: String, templateID: String?) async throws
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

    /// Adds a note to a POS order. Used by the Scan to Pay flow to record that a customer
    /// paid via QR (the actual payment-status flip happens via the gateway webhook; this
    /// note is just an audit trail visible in WP-Admin).
    func addPOSOrderNote(siteID: Int64,
                         orderID: Int64,
                         isCustomerNote: Bool,
                         note: String) async throws -> OrderNote
}

public enum POSOrdersRemoteError: Error {
    case addOrderNoteFailed
}
