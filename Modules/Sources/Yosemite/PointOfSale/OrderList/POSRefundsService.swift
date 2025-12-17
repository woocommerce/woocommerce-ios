import Foundation
import protocol NetworkingCore.POSRefundsRemoteProtocol

public final class POSRefundsService {
    private let refundsRemote: POSRefundsRemoteProtocol
    private let siteID: Int64
    private let mapper: POSRefundMapper

    public init(
        siteID: Int64,
        refundsRemote: POSRefundsRemoteProtocol
    ) {
        self.siteID = siteID
        self.refundsRemote = refundsRemote
        self.mapper = POSRefundMapper()
    }

    public func providePointOfSaleRefunds(for order: POSOrder) async throws -> [POSRefund] {
        let refunds = try await refundsRemote.loadRefunds(for: siteID, by: order.id, with: order.refunds.map { $0.refundID })

        return refunds.map { mapper.map(refund: $0) }
    }
}
