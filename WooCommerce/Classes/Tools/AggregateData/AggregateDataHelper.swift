import Foundation
import Yosemite
import WooFoundation


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
    static func combineRefundedProducts(from refunds: [Refund], orderItems: [OrderItem]) -> [AggregateOrderItem]? {
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
                .compactMap { currency.convertToDecimal($0.total) }
                .reduce(NSDecimalNumber(value: 0), { $0.adding($1) })

            let attributes = orderItems.first(where: {
                guard let refundedItemID = item.refundedItemID else {
                    return false
                }

                return $0.itemID == Int64(refundedItemID)
            })?.attributes ?? []

            return AggregateOrderItem(
                productID: item.productID,
                variationID: item.variationID,
                name: item.name,
                price: item.price,
                quantity: totalQuantity,
                sku: item.sku,
                total: total,
                attributes: attributes
            )
        }

        let sorted = unsortedResult.sorted(by: { ($0.productID, $0.variationID) < ($1.productID, $1.variationID) })

        return sorted
    }

    /// Combine original order items with refunded products
    /// to get a tally for the quantity and item total
    ///
    static func combineOrderItems(_ items: [OrderItem], with refunds: [Refund]) -> [AggregateOrderItem] {
        guard let refundedProducts = combineRefundedProducts(from: refunds, orderItems: items) else {
            fatalError("Error: attempted to calculate aggregate order item data with no refunded products.")
        }

        let currency = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
        // Convert the order items into a mutable type
        let convertedItems = items.map { item -> AggregateOrderItem in
            let total = currency.convertToDecimal(item.total) ?? NSDecimalNumber.zero
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

        var filtered = unsortedResult.filter { $0.quantity > 0 }

        // Sort elements following the previous order of the items.
        var sorted: [AggregateOrderItem] = []
        for item in allItems {
            if let find = filtered.first(where: {
                $0.hashValue == item.hashValue
            }) {
                sorted.append(find)
            }

            filtered.removeAll {
                $0.hashValue == item.hashValue
            }
        }

        return sorted
    }
}
