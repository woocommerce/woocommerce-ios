import Foundation
import Yosemite

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
}

final class OrderRefundsOptionsDeterminer: OrderRefundsOptionsDeterminerProtocol {
    func isAnythingToRefund(from order: Order, with refunds: [Refund], currencyFormatter: CurrencyFormatter) -> Bool {
        let alreadyRefundedTotal = refunds
            .map {
                (currencyFormatter.convertToDecimal(from: $0.amount) ?? 0) as Decimal
            }
            .reduce(Decimal(0), +)

        let orderTotal = (currencyFormatter.convertToDecimal(from: order.total) ?? 0) as Decimal

        let thereIsSomeAmountToRefund = orderTotal - alreadyRefundedTotal > 0
        let thereAreItemsToRefund = determineRefundableOrderItems(from: order, with: refunds).count > 0

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

                // Only keep accumulating if the refunded item product and the original item product match
                guard refundedItem.productOrVariationID == item.productOrVariationID else {
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
            return RefundableOrderItem(item: item, quantity: quantityLeftToRefund)
        }
    }
}
