import Foundation
import Combine
import Networking
import protocol NetworkingCore.POSRefundsRemoteProtocol
import struct NetworkingCore.Refund
import struct NetworkingCore.OrderItemRefund
import struct NetworkingCore.OrderItemTaxRefund
import class WooFoundation.CurrencySettings

public final class POSRefundsService: POSRefundsServiceProtocol {
    private let refundsRemote: POSRefundsRemoteProtocol
    private let paymentGatewayRemote: POSPaymentGatewayRemoteProtocol
    private let refundCalculator: POSRefundCalculating
    private let currencySettings: CurrencySettings
    private let siteID: Int64
    private let mapper: POSRefundMapper

    public init(siteID: Int64,
                credentials: Credentials?,
                selectedSite: AnyPublisher<JetpackSite?, Never>,
                appPasswordSupportState: AnyPublisher<Bool, Never>,
                currencySettings: CurrencySettings
    ) {
        self.siteID = siteID
        self.currencySettings = currencySettings
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.refundsRemote = RefundsRemote(network: network)
        self.paymentGatewayRemote = PaymentGatewayRemote(network: network)
        self.refundCalculator = POSRefundCalculator()
        self.mapper = POSRefundMapper()
    }

    init(siteID: Int64,
         refundsRemote: POSRefundsRemoteProtocol,
         paymentGatewayRemote: POSPaymentGatewayRemoteProtocol,
         currencySettings: CurrencySettings = CurrencySettings(),
         refundCalculator: POSRefundCalculating = POSRefundCalculator()) {
        self.siteID = siteID
        self.currencySettings = currencySettings
        self.refundsRemote = refundsRemote
        self.paymentGatewayRemote = paymentGatewayRemote
        self.refundCalculator = refundCalculator
        self.mapper = POSRefundMapper()
    }

    public func providePointOfSaleRefunds(for order: POSOrder) async throws -> POSRefundsResult {
        async let refundsTask = refundsRemote.loadRefunds(for: siteID, by: order.id, with: order.refunds.map { $0.refundID })
        async let gatewaysTask = fetchPaymentGateways()

        let refunds = try await refundsTask
        let gateways = await gatewaysTask

        let mappedRefunds = refunds.map { mapper.map(refund: $0) }
        let isFullyRefunded = areAllProductsFullyRefunded(
            orderedQuantities: order.lineItemQuantitiesByProductOrVariationID,
            refunds: refunds
        )
        let supportsAutomaticRefund = determineAutomaticRefundSupport(
            paymentMethodID: order.paymentMethodID,
            gateways: gateways
        )

        return POSRefundsResult(refunds: mappedRefunds, isFullyRefunded: isFullyRefunded, supportsAutomaticRefund: supportsAutomaticRefund)
    }

    private func fetchPaymentGateways() async -> [PaymentGateway] {
        await withCheckedContinuation { continuation in
            paymentGatewayRemote.loadAllPaymentGateways(siteID: siteID) { result in
                switch result {
                case .success(let gateways):
                    continuation.resume(returning: gateways)
                case .failure(let error):
                    DDLogError("⛔️ Failed to load payment gateways: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }

    private func determineAutomaticRefundSupport(paymentMethodID: String, gateways: [PaymentGateway]) -> Bool {
        if let gateway = gateways.first(where: { $0.gatewayID == paymentMethodID }) {
            return gateway.features.contains(.refunds)
        }
        // Fallback: if gateway not found, use simple check
        return paymentMethodID != PaymentGateway.Constants.cashOnDeliveryGatewayID
    }

    public func createRefund(orderID: Int64, items: [POSRefundableItem], reason: String?, isAutomaticRefund: Bool) async throws {
        let numberOfDecimals = currencySettings.fractionDigits
        let request = refundCalculator.buildRefundRequest(
            orderID: orderID,
            selectedItems: items,
            reason: reason,
            numberOfDecimals: numberOfDecimals
        )
        let refund = buildRefund(from: request, createAutomated: isAutomaticRefund, numberOfDecimals: numberOfDecimals)
        _ = try await refundsRemote.createRefund(for: siteID, by: orderID, refund: refund)
    }

    private func buildRefund(from request: POSRefundRequest, createAutomated: Bool, numberOfDecimals: Int) -> Refund {
        let items = request.items.map { item in
            OrderItemRefund(
                itemID: item.itemID,
                name: "",
                productID: 0,
                variationID: 0,
                refundedItemID: nil,
                quantity: Decimal(-item.quantity),
                price: NSDecimalNumber.zero,
                sku: nil,
                subtotal: "",
                subtotalTax: "",
                taxClass: "",
                taxes: item.refundTax > 0 ? [OrderItemTaxRefund(taxID: 0, subtotal: "", total: formatDecimalForAPI(item.refundTax, numberOfDecimals: numberOfDecimals))] : [],
                total: formatDecimalForAPI(-item.refundTotal, numberOfDecimals: numberOfDecimals),
                totalTax: ""
            )
        }

        return Refund(
            refundID: 0,
            orderID: request.orderID,
            siteID: siteID,
            dateCreated: Date(),
            amount: formatDecimalForAPI(request.amount, numberOfDecimals: numberOfDecimals),
            reason: request.reason ?? "",
            refundedByUserID: 0,
            isAutomated: nil,
            createAutomated: createAutomated,
            items: items,
            shippingLines: nil
        )
    }

    private func formatDecimalForAPI(_ value: Decimal, numberOfDecimals: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = numberOfDecimals
        formatter.maximumFractionDigits = numberOfDecimals
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
