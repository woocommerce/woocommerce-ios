import Foundation
import Networking
import protocol NetworkingCore.POSRefundsRemoteProtocol

final class MockPOSRefundsRemote: POSRefundsRemoteProtocol {
    private(set) var spySiteID: Int64?
    private(set) var spyOrderID: Int64?
    private(set) var spyRefundIDs: [Int64]?
    private(set) var spyRefund: Refund?

    var result: Result<[Refund], Error> = .success([])
    var createRefundResult: Result<Refund, Error> = .success(.init(refundID: 0,
                                                                   orderID: 0,
                                                                   siteID: 0,
                                                                   dateCreated: Date(),
                                                                   amount: "0",
                                                                   reason: "",
                                                                   refundedByUserID: 0,
                                                                   isAutomated: nil,
                                                                   createAutomated: nil,
                                                                   items: [],
                                                                   shippingLines: nil))

    func loadRefunds(for siteID: Int64, by orderID: Int64, with refundIDs: [Int64]) async throws -> [Refund] {
        spySiteID = siteID
        spyOrderID = orderID
        spyRefundIDs = refundIDs
        return try result.get()
    }

    func createRefund(for siteID: Int64, by orderID: Int64, refund: Refund) async throws -> Refund {
        spySiteID = siteID
        spyOrderID = orderID
        spyRefund = refund
        return try createRefundResult.get()
    }
}
