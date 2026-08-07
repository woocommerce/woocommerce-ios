import Foundation
import Yosemite

/// Deterministic `RefundServiceProtocol` implementation for screenshot generation and UI tests.
/// Computes preview totals from the mocked order's line items, mirroring what the production
/// service receives from the server, and persists nothing.
final class POSRefundServiceMock: RefundServiceProtocol {
    private let orderService: POSOrderServiceProtocol

    init(orderService: POSOrderServiceProtocol) {
        self.orderService = orderService
    }

    func previewRefund(siteID: Int64,
                       orderID: Int64,
                       lineItems: [RefundV4LineItem]) async throws -> RefundPreview {
        let order: Order?
        do {
            order = try await orderService.loadOrder(orderID: orderID)
        } catch {
            DDLogError("⛔️ POSRefundServiceMock could not load order \(orderID) for the preview: \(error)")
            order = nil
        }
        let subtotal = lineItems.reduce(Decimal.zero) { runningTotal, lineItem in
            if let refundTotal = lineItem.refundTotal {
                return runningTotal + refundTotal
            }
            let unitPrice = order?.items.first { $0.itemID == lineItem.lineItemID }?.price.decimalValue ?? .zero
            return runningTotal + unitPrice * (lineItem.quantity ?? .zero)
        }
        let emptySection = RefundPreview.Section(items: [], subtotal: .zero, tax: .zero, total: .zero)
        return RefundPreview(subtotal: subtotal,
                             tax: .zero,
                             total: subtotal,
                             maxRefundable: subtotal,
                             breakdown: .init(products: emptySection, shipping: emptySection, fees: emptySection))
    }

    func createRefund(siteID: Int64,
                      orderID: Int64,
                      reason: String,
                      automaticRefund: Bool,
                      restockItems: Bool,
                      lineItems: [RefundV4LineItem]) async throws -> Refund {
        let preview = try await previewRefund(siteID: siteID, orderID: orderID, lineItems: lineItems)
        return Refund(refundID: 1,
                      orderID: orderID,
                      siteID: siteID,
                      dateCreated: Date(),
                      amount: NSDecimalNumber(decimal: preview.total).stringValue,
                      reason: reason,
                      refundedByUserID: 0,
                      isAutomated: automaticRefund,
                      createAutomated: automaticRefund,
                      items: [],
                      shippingLines: [])
    }

    func previewRefund(siteID: Int64,
                       orderID: Int64,
                       lineItems: [RefundPreviewLineItem]) async throws -> RefundPreview {
        try await previewRefund(siteID: siteID,
                                orderID: orderID,
                                lineItems: lineItems.map { refundV4LineItem(from: $0) })
    }

    func createRefund(siteID: Int64,
                      orderID: Int64,
                      reason: String,
                      automaticRefund: Bool,
                      restockItems: Bool,
                      amountOverride: String?,
                      lineItems: [ComputedRefundLineItem]) async throws -> Refund {
        try await createRefund(siteID: siteID,
                               orderID: orderID,
                               reason: reason,
                               automaticRefund: automaticRefund,
                               restockItems: restockItems,
                               lineItems: lineItems.map { refundV4LineItem(from: $0) })
    }

    /// The mock computes totals the same way for every generation of the request models,
    /// so the v3 shapes are bridged to the v4 model the computation helpers consume.
    /// These bridges are deleted together with the v4 flow when the switch lands.
    private func refundV4LineItem(from lineItem: RefundPreviewLineItem) -> RefundV4LineItem {
        if let quantity = lineItem.quantity {
            return .quantityBased(lineItemID: lineItem.lineItemID, quantity: Decimal(quantity))
        }
        if let refundTotal = lineItem.refundTotal {
            return .amountBased(lineItemID: lineItem.lineItemID, refundTotal: refundTotal)
        }
        assertionFailure("RefundPreviewLineItem carries quantity or refundTotal by construction; the factories enforce it.")
        return .amountBased(lineItemID: lineItem.lineItemID, refundTotal: .zero)
    }

    private func refundV4LineItem(from lineItem: ComputedRefundLineItem) -> RefundV4LineItem {
        if let quantity = lineItem.quantity {
            return .quantityBased(lineItemID: lineItem.lineItemID, quantity: Decimal(quantity))
        }
        if let refundTotal = lineItem.refundTotal {
            return .amountBased(lineItemID: lineItem.lineItemID, refundTotal: refundTotal)
        }
        assertionFailure("ComputedRefundLineItem carries quantity or refundTotal by construction; the factories enforce it.")
        return .amountBased(lineItemID: lineItem.lineItemID, refundTotal: .zero)
    }
}
