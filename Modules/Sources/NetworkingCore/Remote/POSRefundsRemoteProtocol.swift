import Foundation

public protocol POSRefundsRemoteProtocol {
    func loadRefunds(for siteID: Int64, by orderID: Int64, with refundIDs: [Int64]) async throws -> [Refund]

    /// Creates a refund for the specified order.
    /// - Note: The API expects negative values for refund items:
    ///   - negative quantity = items being returned
    ///   - negative total = money being refunded
    func createRefund(for siteID: Int64, by orderID: Int64, refund: Refund) async throws -> Refund
}
