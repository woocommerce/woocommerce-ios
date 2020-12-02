import Foundation
import Yosemite


// MARK: - A helper class for calculating aggregate data
//
final class AggregateDataHelper {
    /// Calculate the total quantity of refunded products
    ///
    static func refundedProductsCount(from refunds: [Refund]) -> Decimal {
        let refundedItems = refunds.flatMap { $0.items }
        let quantities = refundedItems.map { $0.quantity }
        let decimalCount = quantities.reduce(0, +)

        // quantities report as negative values
        return abs(decimalCount)
    }

    /// Combine all refunded products into a single data source
    ///
    static func combineRefundedProducts(from refunds: [Refund]) -> [AggregateOrderItem]? {
        /// OrderItemRefund.orderItemID isn't useful for finding duplicates
        /// because multiple refunds cause orderItemIDs to be unique.
        /// Instead, we need to find duplicate *Products*.
        let items = refunds.flatMap { $0.items }
        let currency = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

        // Creates an array of dictionaries, with the hash value as the key.
        // Example: [hashValue: [item, item], hashvalue: [item]]
        // Since dictionary keys are unique, this eliminates the duplicate `OrderItemRefund`s.
        let grouped = Dictionary(grouping: items) { (item) in
            return item.hashValue
        }

        let unsortedResult = grouped.compactMap { (key, items) -> AggregateOrderItem? in
            // Here we iterate over each group's items

            // All items should be equal except for quantity and price, so we pick the first
            guard let item = items.first else {
                // This should never happen, but let's be safe
                return nil
            }

            // Sum the quantities
            let totalQuantity = items.sum(\.quantity)
            // Sum the refunded product amount
            let total = items
                .compactMap { currency.convertToDecimal(from: $0.total) }
                .reduce(NSDecimalNumber(value: 0), { $0.adding($1) })

            return AggregateOrderItem(
                productID: item.productID,
                variationID: item.variationID,
                name: item.name,
                price: item.price,
                quantity: totalQuantity,
                sku: item.sku,
                total: total,
                attributes: []
            )
        }

        let sorted = unsortedResult.sorted(by: { ($0.productID, $0.variationID) < ($1.productID, $1.variationID) })

        return sorted
    }

    /// Combine original order items with refunded products
    /// to get a tally for the quantity and item total
    ///
    static func combineOrderItems(_ items: [OrderItem], with refunds: [Refund]) -> [AggregateOrderItem] {
        guard let refundedProducts = combineRefundedProducts(from: refunds) else {
            fatalError("Error: attempted to calculate aggregate order item data with no refunded products.")
        }

        let currency = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
        // Convert the order items into a mutable type
        let convertedItems = items.map { item -> AggregateOrderItem in
            let total = currency.convertToDecimal(from: item.total) ?? NSDecimalNumber.zero
            return AggregateOrderItem(
                productID: item.productID,
                variationID: item.variationID,
                name: item.name,
                price: item.price,
                quantity: item.quantity,
                sku: item.sku,
                total: total,
                attributes: item.attributes
            )
        }

        let allItems = convertedItems + refundedProducts

        let grouped = Dictionary(grouping: allItems) { (item) in
            return item.hashValue
        }

        let unsortedResult: [AggregateOrderItem] = grouped.compactMap { (key, items) in
            // Here we iterate over each group's items

            // All items should be equal except for quantity and price, so we pick the first
            guard let item = items.first else {
                // This should never happen, but let's be safe
                return nil
            }

            // Sum the quantities
            let totalQuantity = items.sum(\.quantity)
            // Sum the refunded product amount
            let total = items
                .compactMap({ $0.total })
                .reduce(NSDecimalNumber(value: 0), { $0.adding($1) })

            return AggregateOrderItem(
                productID: item.productID,
                variationID: item.variationID,
                name: item.name,
                price: item.price,
                quantity: totalQuantity,
                sku: item.sku,
                total: total,
                attributes: item.attributes
            )
        }

        let filtered = unsortedResult.filter { $0.quantity > 0 }

        let sorted = filtered.sorted(by: { ($0.productID, $0.variationID) < ($1.productID, $1.variationID) })

        return sorted
    }

    /// Combines aggregate order items with order items from non-refunded shipping labels.
    ///
    /// - Parameters:
    ///   - orderItems: an array of aggregate order items, like after combining with refunded products by calling `combineOrderItems`.
    ///   - orderItemsInNonRefundedShippingLabels: an array of aggregate order items from shipping labels that could have duplicate products/variations.
    /// - Returns: an array of aggregate order items based on the given `orderItems` whose elements are removed if fully covered in shipping labels, and the
    ///            quantity is subtracted by the total quantity from the given order items in shipping labels.
    static func combineAggregatedOrderItems(_ orderItems: [AggregateOrderItem],
                                            with orderItemsInNonRefundedShippingLabels: [AggregateOrderItem]) -> [AggregateOrderItem] {
        // Generates a dictionary that maps a unique order item (keyed by `productID` and `variationID`) to the sum of quantity from order items in shipping
        // labels.
        let orderItemsByProductAndVariationID = Dictionary(grouping: orderItemsInNonRefundedShippingLabels) { $0.hashValue }
        let orderItemCountsByProductAndVariationID = orderItemsByProductAndVariationID.mapValues {
            $0.reduce(into: 0) { result, orderItem in
                result += orderItem.quantity
            }
        }
        return orderItems.compactMap { orderItem in
            // If the order item is not in any shipping labels, the original order item is returned.
            guard let orderItemCountInNonRefundedShippingLabels = orderItemCountsByProductAndVariationID[orderItem.hashValue] else {
                return orderItem
            }
            // If the order item quantity is <= the sum in the shipping labels, the order item is skipped since it's shown in the shipping label sections.
            guard orderItemCountInNonRefundedShippingLabels < orderItem.quantity else {
                return nil
            }
            // If the order item quantity is larger than the sum in the shipping labels, the order item's quantity is deducted by the sum in the shipping
            // labels.
            return orderItem.copy(quantity: orderItem.quantity - orderItemCountInNonRefundedShippingLabels)
        }
    }
}
