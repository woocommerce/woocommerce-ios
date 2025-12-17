import Foundation
import Combine
import Networking
import protocol NetworkingCore.POSRefundsRemoteProtocol

public final class POSRefundsService: POSRefundsServiceProtocol {
    private let refundsRemote: POSRefundsRemoteProtocol
    private let siteID: Int64
    private let mapper: POSRefundMapper

    public init(siteID: Int64,
                credentials: Credentials?,
                selectedSite: AnyPublisher<JetpackSite?, Never>,
                appPasswordSupportState: AnyPublisher<Bool, Never>
    ) {
        self.siteID = siteID
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.refundsRemote = RefundsRemote(network: network)
        self.mapper = POSRefundMapper()
    }

    public func providePointOfSaleRefunds(for order: POSOrder) async throws -> [POSRefund] {
        let refunds = try await refundsRemote.loadRefunds(for: siteID, by: order.id, with: order.refunds.map { $0.refundID })

        return refunds.map { mapper.map(refund: $0) }
    }
}
