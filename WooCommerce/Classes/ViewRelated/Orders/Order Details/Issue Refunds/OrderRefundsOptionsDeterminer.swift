import Foundation
import Yosemite
import WooFoundation

/// Encapsulates the logic related with the refunding options of an Order
///
protocol OrderRefundsOptionsDeterminerProtocol {
    /// Provides an array of refundable items linked to the order parameter
    ///
    /// - Parameters:
    ///   - order: the order to be analyzed
    ///   - refunds: the previously issued refunds linked to that order
    ///
    /// - Returns: An array of `RefundableOrderItem`
    ///
    func determineRefundableOrderItems(from order: Order, with refunds: [Refund]) -> [RefundableOrderItem]

    /// Determines whether there is something to be refunded from that order (e.g items, fees, shippings, taxes ...)
    ///
    /// - Parameters:
    ///   - order: the order to be analyzed
    ///   - refunds: the previously issued refunds linked to that order
    ///   - currencyFormatter: the formatter to parse the order or refunds model amount
    ///
    /// - Returns: A boolean indicating whether there is still something to be refunded from that order
    ///
    func isAnythingToRefund(from order: Order, with refunds: [Refund], currencyFormatter: CurrencyFormatter) -> Bool

    /// Determines whether refunding custom amounts should be enabled by default.
    ///
    /// - Parameters:
    ///   - order: the order to be analyzed
    ///
    /// - Returns: A boolean indicating whether custom amounts should be refunded by default
    ///
    func shouldRefundCustomAmountsByDefault(from order: Order) -> Bool
}

final class OrderRefundsOptionsDeterminer: OrderRefundsOptionsDeterminerProtocol {
    func isAnythingToRefund(from order: Order, with refunds: [Refund], currencyFormatter: CurrencyFormatter) -> Bool {
        let alreadyRefundedTotal = refunds
            .map {
                (currencyFormatter.convertToDecimal($0.amount) ?? 0) as Decimal
            }
            .reduce(Decimal(0), +)

        let orderTotal = (currencyFormatter.convertToDecimal(order.total) ?? 0) as Decimal

        let thereIsSomeAmountToRefund = orderTotal - alreadyRefundedTotal > 0
        let thereAreItemsToRefund = !determineRefundableOrderItems(from: order, with: refunds).isEmpty

        return thereIsSomeAmountToRefund || thereAreItemsToRefund
    }

    /// Return an array of `RefundableOrderItems` by taking out all previously refunded items
    ///
    func determineRefundableOrderItems(from order: Order, with refunds: [Refund]) -> [RefundableOrderItem] {
        // Flattened array with all items refunded
        let allRefundedItems = refunds.flatMap { $0.items }

        // Transform `order.items` by subtracting the quantity left to refund and evicting those who were fully refunded.
        return order.items.compactMap { item -> RefundableOrderItem? in

            // Calculate how many times an item has been refunded. This number is negative.
            let timesRefunded = allRefundedItems.reduce(0) { timesRefunded, refundedItem -> Decimal in
                guard refundedItemMatches(refundedItem, item: item) else {
                    return timesRefunded
                }
                return timesRefunded + refundedItem.quantity
            }

            // If there is no more items to refund, evict it from the resulting array
            let quantityLeftToRefund = item.quantity + timesRefunded
            guard quantityLeftToRefund > 0 else {
                return nil
            }

            // Return the item with the updated quantity to refund
            var refundable = RefundableOrderItem(item: item, quantity: quantityLeftToRefund)
            refundable.refundedItems = allRefundedItems.filter { refundedItemMatches($0, item: item) }
            return refundable
        }
    }

    func shouldRefundCustomAmountsByDefault(from order: Order) -> Bool {
        let thereIsOnlyCustomAmountsToRefund = order.items.isEmpty && order.fees.isNotEmpty

        return thereIsOnlyCustomAmountsToRefund
    }

    private func refundedItemMatches(_ refundedItem: OrderItemRefund, item: OrderItem) -> Bool {
        guard let refundedItemID = refundedItem.refundedItemID, let originalOrderItemID = Int64(refundedItemID) else {
            return refundedItem.productOrVariationID == item.productOrVariationID
        }

        return originalOrderItemID == item.itemID
    }
}

// Monetary balances are independent of quantity (for example after a partial amount refund).
extension OrderRefundsOptionsDeterminer {
    static func remainingFees(in order: Order, refunds: [Refund]) -> [OrderFeeLine] {
        order.fees.compactMap { fee -> OrderFeeLine? in
            let history = refunds.flatMap(\.feeLines).filter { ($0.refundedItemID ?? $0.feeID) == fee.feeID }
            guard history.isNotEmpty else { return fee }
            let total = remaining(fee.total, refunds: history.map(\.total))
            let totalTax = remaining(fee.totalTax, refunds: history.map(\.totalTax))
            guard total + totalTax != 0 else { return nil }
            return fee.copy(total: "\(total)", totalTax: "\(totalTax)", taxes: fee.taxes.map { tax in
                let refundedTaxes = history.flatMap(\.taxes).filter { $0.taxID == tax.taxID }.map(\.total)
                return OrderItemTax(taxID: tax.taxID, subtotal: tax.subtotal, total: "\(remaining(tax.total, refunds: refundedTaxes))")
            })
        }
    }

    static func remainingShipping(in order: Order, refunds: [Refund]) -> [ShippingLine]? {
        guard refunds.allSatisfy({ $0.shippingLines != nil }) else { return nil }
        return order.shippingLines.compactMap { line -> ShippingLine? in
            let history = refunds.flatMap { $0.shippingLines ?? [] }.filter { ($0.refundedItemID ?? $0.shippingID) == line.shippingID }
            guard history.isNotEmpty else { return line }
            let total = remaining(line.total, refunds: history.map(\.total))
            let totalTax = remaining(line.totalTax, refunds: history.map(\.totalTax))
            guard total + totalTax > 0 else { return nil }
            return line.copy(total: "\(total)", totalTax: "\(totalTax)", taxes: line.taxes.map { tax in
                let refundedTaxes = history.flatMap(\.taxes).filter { $0.taxID == tax.taxID }.map(\.total)
                return ShippingLineTax(taxID: tax.taxID, subtotal: tax.subtotal, total: "\(remaining(tax.total, refunds: refundedTaxes))")
            })
        }
    }

    private static func remaining(_ original: String, refunds: [String]) -> Decimal {
        let value = Decimal(string: original) ?? .zero
        let refunded = refunds.reduce(Decimal.zero) { $0 + abs(Decimal(string: $1) ?? .zero) }
        return (value < 0 ? -1 : 1) * max(abs(value) - refunded, .zero)
    }
}
