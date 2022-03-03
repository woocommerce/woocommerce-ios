import Foundation
import Yosemite

/// Helper to updates an `order` given an `OrderSyncInput` type.
///
struct ProductInputTransformer {
    /// Type to help bundling  order Items parameters.
    ///
    struct OrderItemParameters {
        let quantity: Decimal
        let price: Decimal
        let productID: Int64
        let variationID: Int64?
        var subtotal: String {
            "\(price * quantity)"
        }
        var total: String {
            subtotal
        }
    }

    /// Adds, deletes, or updates order items based on the given product input.
    ///
    static func update(input: OrderSyncProductInput, on order: Order) -> Order {
        // If the input's quantity is 0 or less, delete the item if possible.
        guard input.quantity > 0 else {
            return remove(input: input, from: order)
        }

        // Add or update the order items with the new input.
        var items = order.items
        if let itemIndex = order.items.firstIndex(where: { $0.itemID == input.id }) {
            let newItem = createOrderItem(using: input, usingPriceFrom: items[itemIndex])
            items[itemIndex] = newItem
        } else {
            let newItem = createOrderItem(using: input, usingPriceFrom: nil)
            items.append(newItem)
        }

        return order.copy(items: items)
    }

    /// Removes an order item from an order when the `item.itemID` matches the `input.id`.
    ///
    private static func remove(input: OrderSyncProductInput, from order: Order) -> Order {
        var items = order.items
        items.removeAll { $0.itemID == input.id }
        return order.copy(items: items)
    }

    /// Creates and order item by using the `input.id` as the `item.itemID`.
    /// When `usingPriceFrom` is set, the price from the item will be used instead of the price of the product.
    ///
    private static func createOrderItem(using input: OrderSyncProductInput, usingPriceFrom existingItem: OrderItem?) -> OrderItem {
        let parameters: OrderItemParameters = {
            // Prefer the item price as it should have been properly sanitized by the remote source.
            switch input.product {
            case .product(let product):
                let price: Decimal = existingItem?.price.decimalValue ?? Decimal(string: product.price) ?? .zero
                return OrderItemParameters(quantity: input.quantity, price: price, productID: product.productID, variationID: nil)
            case .variation(let variation):
                let price: Decimal = existingItem?.price.decimalValue ?? Decimal(string: variation.price) ?? .zero
                return OrderItemParameters(quantity: input.quantity, price: price, productID: variation.productID, variationID: variation.productVariationID)
            }
        }()

        return OrderItem(itemID: input.id,
                         name: "",
                         productID: parameters.productID,
                         variationID: parameters.variationID ?? 0,
                         quantity: parameters.quantity,
                         price: parameters.price as NSDecimalNumber,
                         sku: nil,
                         subtotal: parameters.subtotal,
                         subtotalTax: "",
                         taxClass: "",
                         taxes: [],
                         total: parameters.total,
                         totalTax: "",
                         attributes: [])
    }
}
