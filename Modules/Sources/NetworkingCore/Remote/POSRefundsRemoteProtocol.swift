import Foundation

public protocol POSRefundsRemoteProtocol {
    func loadRefunds(for siteID: Int64, by orderID: Int64, with refundIDs: [Int64]) async throws -> [Refund]

    /// Creates a refund for the specified order.
    /// - Note: Values should be sent as positive. The WooCommerce API (wc_create_refund) negates them internally.
    func createRefund(for siteID: Int64, by orderID: Int64, refund: Refund) async throws -> Refund
}
