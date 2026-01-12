import Foundation
import Combine
import Networking
import protocol NetworkingCore.POSRefundsRemoteProtocol
import struct NetworkingCore.Refund

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

    init(siteID: Int64,
        refundsRemote: POSRefundsRemoteProtocol) {
        self.siteID = siteID
        self.refundsRemote = refundsRemote
        self.mapper = POSRefundMapper()
    }

    public func providePointOfSaleRefunds(for order: POSOrder) async throws -> POSRefundsResult {
        let refunds = try await refundsRemote.loadRefunds(for: siteID, by: order.id, with: order.refunds.map { $0.refundID })

        let mappedRefunds = refunds.map { mapper.map(refund: $0) }
        let isFullyRefunded = areAllProductsFullyRefunded(
            orderedQuantities: order.lineItemQuantitiesByProductOrVariationID,
            refunds: refunds
        )

        return POSRefundsResult(refunds: mappedRefunds, isFullyRefunded: isFullyRefunded)
    }

    /// Checks if all ordered products have been fully refunded.
    /// - Parameters:
    ///   - orderedQuantities: Aggregated quantities per product/variation ID from the order
    ///   - refunds: The refunds from the API containing item-level refund details
    /// - Returns: true if all products have been fully refunded
    private func areAllProductsFullyRefunded(
        orderedQuantities: [Int64: Decimal],
        refunds: [Refund]
    ) -> Bool {
        // Aggregate refunded quantities by product/variation ID
        var refundedQuantities: [Int64: Decimal] = [:]
        for refund in refunds {
            for item in refund.items {
                let id = item.variationID != 0 ? item.variationID : item.productID
                refundedQuantities[id, default: 0] += item.quantity
            }
        }

        // Check if every ordered product has been fully refunded
        return orderedQuantities.allSatisfy { id, orderedQty in
            (refundedQuantities[id] ?? 0) >= orderedQty
        }
    }
}
