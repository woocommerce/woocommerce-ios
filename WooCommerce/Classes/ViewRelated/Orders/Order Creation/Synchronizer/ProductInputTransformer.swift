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

    enum UpdateOrDelete {
        case update
        case delete
    }

    /// Adds, deletes, or updates order items based on the given product input.
    /// When `shouldUpdateOrDeleteZeroQuantities` value is `.update`, items with `.zero` quantities will be updated instead of being deleted.
    ///
    static func update(input: OrderSyncProductInput, on order: Order, shouldUpdateOrDeleteZeroQuantities: UpdateOrDelete) -> Order {
        // If the input's quantity is 0 or less, delete the item if required.
        guard input.quantity > 0 || shouldUpdateOrDeleteZeroQuantities == .update else {
            return remove(input: input, from: order)
        }

        // Add or update the order items with the new input.
        var items = order.items
        updateOrderItems(from: order, with: input, orderItems: &items)
        return order.copy(items: items)
    }

    /// Adds, deletes, or updates Order items based on the multiple given product inputs
    /// We receive an `[OrderSyncProductInput]` object as input, and must return an updated `Order`
    ///
    /// - Parameters:
    ///   - inputs: Array of product types the OrderSynchronizer supports
    ///   - order: Represents an Order entity.
    ///   - shouldUpdateOrDeleteZeroQuantities: When its value is `.update`, items with `.zero` quantities will be updated instead of being deleted.
    ///
    /// - Returns: An Order entity.
    static func updateMultipleItems(with inputs: [OrderSyncProductInput], on order: Order, shouldUpdateOrDeleteZeroQuantities: UpdateOrDelete) -> Order {
        var updatedOrderItems = order.items

        for input in inputs {
            updateOrderItems(from: order, with: input, orderItems: &updatedOrderItems)
        }

        // If the input's quantity is 0 or less, delete the item if required.
        // We perform a second loop for deletions so we don't attempt to access to overflown indexes
        for input in inputs {
            guard input.quantity > 0 || shouldUpdateOrDeleteZeroQuantities == .update else {
                updatedOrderItems.removeAll(where: { $0.itemID == input.id })
                return order.copy(items: updatedOrderItems)
            }
        }

        return order.copy(items: updatedOrderItems)
    }
}

// MARK: ProductInputTransformer helper methods
//
private extension ProductInputTransformer {
    /// Creates, or updates existing `OrderItems` of a given `Order` with any `OrderSyncProductInput` update
    ///
    /// - Parameters:
    ///   - order: Represents an Order entity.
    ///   - input: Types of products the synchronizer supports
    ///   - updatedOrderItems: An array of `[OrderItem]` entities
    ///
    static func updateOrderItems(from order: Order, with input: OrderSyncProductInput, orderItems updatedOrderItems: inout [OrderItem]) {
        if let itemIndex = order.items.firstIndex(where: { $0.itemID == input.id }) {
            let newItem = createOrderItem(using: input, usingPriceFrom: updatedOrderItems[itemIndex])
            updatedOrderItems[itemIndex] = newItem
        } else {
            let newItem = createOrderItem(using: input, usingPriceFrom: nil)
            updatedOrderItems.append(newItem)
        }
    }

    /// Updates the `OrderItems` array with `OrderSyncProductInput`.
    /// Uses the same implementation as `update()` but returns an array of OrderItems instead,
    /// rather than aggregating them into the Order
    ///
    /// - Parameters:
    ///   - input: Types of products the synchronizer supports
    ///   - order: Represents an Order entity.
    ///   - shouldUpdateOrDeleteZeroQuantities: When its value is `.update`, items with `.zero` quantities will be updated instead of being deleted.
    ///
    /// - Returns: An array of Order Item entities
    private static func updateOrderItems(from input: OrderSyncProductInput, order: Order, shouldUpdateOrDeleteZeroQuantities: UpdateOrDelete) -> [OrderItem] {
        // If the input's quantity is 0 or less, delete the item if required.
        guard input.quantity > 0 || shouldUpdateOrDeleteZeroQuantities == .update else {
            return remove(input: input, from: order).items
        }

        // Adds or updates the Order items with the new input:
        var updatedOrderItems = order.items
        updateOrderItems(from: order, with: input, orderItems: &updatedOrderItems)

        return updatedOrderItems
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
            case .productID(let productID):
                let price: Decimal = existingItem?.price.decimalValue ?? .zero
                return OrderItemParameters(quantity: input.quantity, price: price, productID: productID, variationID: nil)
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
