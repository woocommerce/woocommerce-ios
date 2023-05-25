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
        let items = refunds.flatMap { $0.items }
        let currency = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

        // Creates an array of dictionaries, with the refunded order item ID as the key.
        // Example: [refundedItemID: [item, item], refundedItemID: [item]]
        // Since dictionary keys are unique, this eliminates the duplicate `OrderItemRefund`s.
        let grouped = Dictionary(grouping: items) { (item) in
            // There should always be a refunded item ID (the ID for the refunded `OrderItem`).
            // As a fallback, use the `OrderItemRefund` ID as a unique ID for the refund.
            return item.refundedItemID ?? item.itemID.description
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

            // Find the order item matching this refund, to get its properties
            let matchingOrderItem = orderItems.first(where: {
                guard let refundedItemID = item.refundedItemID else {
                    return false
                }

                return $0.itemID == Int64(refundedItemID)
            })
            let attributes = matchingOrderItem?.attributes ?? []
            let parent = matchingOrderItem?.parent

            return AggregateOrderItem(
                itemID: key,
                productID: item.productID,
                variationID: item.variationID,
                name: item.name,
                price: item.price,
                quantity: totalQuantity,
                sku: item.sku,
                total: total,
                attributes: attributes,
                parent: parent
            )
        }

        return unsortedResult.sorted()
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
                itemID: item.itemID.description,
                productID: item.productID,
                variationID: item.variationID,
                name: item.name,
                price: item.price,
                quantity: item.quantity,
                sku: item.sku,
                total: total,
                attributes: item.attributes,
                parent: item.parent
            )
        }

        let allItems = convertedItems + refundedProducts

        let grouped = Dictionary(grouping: allItems) { (item) in
            return item.itemID
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
                itemID: item.itemID,
                productID: item.productID,
                variationID: item.variationID,
                name: item.name,
                price: item.price,
                quantity: totalQuantity,
                sku: item.sku,
                total: total,
                attributes: item.attributes,
                parent: item.parent
            )
        }

        let filtered = unsortedResult.filter { $0.quantity > 0 }

        return filtered.sorted()
    }

    static func isChildItemWithParent(_ item: AggregateOrderItem, in items: [AggregateOrderItem]) -> Bool {
        guard let parentID = item.parent else {
            return false
        }
        return items.contains(where: { $0.itemID == parentID.description })
    }
}
