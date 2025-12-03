import Foundation

public protocol POSRefundsRemoteProtocol {
    func loadRefunds(for siteID: Int64, by orderID: Int64, with refundIDs: [Int64]) async throws -> [Refund]
}
