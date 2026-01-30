import Foundation
import Combine
import Networking
import protocol NetworkingCore.POSRefundsRemoteProtocol
import struct NetworkingCore.Refund
import struct NetworkingCore.OrderItemRefund
import struct NetworkingCore.OrderItemTaxRefund

public final class POSRefundsService: POSRefundsServiceProtocol {
    private let refundsRemote: POSRefundsRemoteProtocol
    private let refundCalculator: POSRefundCalculating
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
        self.refundCalculator = POSRefundCalculator()
        self.mapper = POSRefundMapper()
    }

    init(siteID: Int64,
         refundsRemote: POSRefundsRemoteProtocol,
         refundCalculator: POSRefundCalculating = POSRefundCalculator()) {
        self.siteID = siteID
        self.refundsRemote = refundsRemote
        self.refundCalculator = refundCalculator
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

    public func createRefund(orderID: Int64, items: [POSRefundableItem], reason: String?) async throws {
        let request = refundCalculator.buildRefundRequest(
            orderID: orderID,
            selectedItems: items,
            reason: reason
        )
        let refund = buildRefund(from: request)
        _ = try await refundsRemote.createRefund(for: siteID, by: orderID, refund: refund)
    }

    private func buildRefund(from request: POSRefundRequest) -> Refund {
        let items = request.items.map { item in
            let refundQuantity = Decimal(-item.quantity)
            let refundTotal = formatDecimalForAPI(-item.refundTotal)
            let refundTaxes: [OrderItemTaxRefund] = item.refundTax > 0
                ? [OrderItemTaxRefund(taxID: 0, subtotal: "", total: formatDecimalForAPI(item.refundTax))]
                : []

            return OrderItemRefund(
                itemID: item.itemID,
                name: "",
                productID: 0,
                variationID: 0,
                refundedItemID: nil,
                quantity: refundQuantity,
                price: NSDecimalNumber.zero,
                sku: nil,
                subtotal: "",
                subtotalTax: "",
                taxClass: "",
                taxes: refundTaxes,
                total: refundTotal,
                totalTax: ""
            )
        }

        return Refund(
            refundID: 0,
            orderID: request.orderID,
            siteID: siteID,
            dateCreated: Date(),
            amount: formatDecimalForAPI(request.amount),
            reason: request.reason ?? "",
            refundedByUserID: 0,
            isAutomated: nil,
            createAutomated: true,
            items: items,
            shippingLines: nil
        )
    }

    private func formatDecimalForAPI(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        formatter.decimalSeparator = "."
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
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
