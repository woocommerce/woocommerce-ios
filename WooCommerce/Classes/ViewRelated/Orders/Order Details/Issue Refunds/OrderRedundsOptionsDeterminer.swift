import Foundation
import Yosemite

protocol OrderRefundsOptionsDeterminerProtocol {
    func determineRefundableOrderItems(from order: Order, with refunds: [Refund]) -> [RefundableOrderItem]
}

final class OrderRefundsOptionsDeterminer: OrderRefundsOptionsDeterminerProtocol {

    func isAnythingToRefund(from order: Order, with refunds: [Refund], currencyFormatter: CurrencyFormatter) -> Bool {
        isAnyFeeAvailableForRefund(from: order) ||
        hasShippingBeenRefunded(from: refunds) == false ||
        shippingLineIsRefundable() ||
        determineRefundableOrderItems(from: order, with: refunds).count > 0
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

    func isAnyFeeAvailableForRefund(from order: Order) -> Bool {
        return order.fees.isNotEmpty
    }

    func hasShippingBeenRefunded(from refunds: [Refund]) -> Bool? {
        // Return false if there are no refunds.
        guard refunds.isNotEmpty else {
            return false
        }

        // Return nil if we can't get shipping line refunds information
        guard refunds.first?.shippingLines != nil else {
            return nil
        }

        // Return true if there is any non-empty shipping refund
        return refunds.first { $0.shippingLines?.isNotEmpty ?? false } != nil
    }

    func shippingLineIsRefundable(_ shippingLine: ShippingLine, currencyFormatter: CurrencyFormatter) -> Bool {
        let shippingValues = RefundShippingCalculationUseCase(shippingLine: shippingLine, currencyFormatter: currencyFormatter)

        return shippingValues.calculateRefundValue() > 0
    }
}
