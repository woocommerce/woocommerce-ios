import Foundation
import Networking
import protocol NetworkingCore.POSRefundsRemoteProtocol

final class MockPOSRefundsRemote: POSRefundsRemoteProtocol {
    private(set) var spySiteID: Int64?
    private(set) var spyOrderID: Int64?
    private(set) var spyRefundIDs: [Int64]?

    var result: Result<[Refund], Error> = .success([])

    func loadRefunds(for siteID: Int64, by orderID: Int64, with refundIDs: [Int64]) async throws -> [Refund] {
        spySiteID = siteID
        spyOrderID = orderID
        spyRefundIDs = refundIDs
        return try result.get()
    }
}
