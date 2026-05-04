import Foundation

/// POSCart is different from the Cart in the POS app layer.
/// - The POS cart UI might show the cart items differently from how they appear in an order in wp-admin.

public struct POSCart {
    public let items: [POSCartItem]
    public let coupons: [POSCoupon]
    public let customAmounts: [POSCustomAmount]

    public init(items: [POSCartItem] = [],
                coupons: [POSCoupon] = [],
                customAmounts: [POSCustomAmount] = []) {
        self.items = items
        self.coupons = coupons
        self.customAmounts = customAmounts
    }
}

public struct POSCartItem {
    public let item: POSOrderableItem
    public let quantity: Decimal

    public init(item: POSOrderableItem, quantity: Decimal) {
        self.item = item
        self.quantity = quantity
    }
}

public extension POSCart {
    func matches(order: Order?) -> Bool {
        return items.matches(order: order)
            && coupons.matches(order: order)
            && customAmounts.matches(order: order)
    }

    func compareWithOrder(_ order: Order?) -> CartOrderComparison {
        let itemsComparison = items.compareWithOrder(order)
        let couponsMatch = coupons.matches(order: order)
        let customAmountsMatch = customAmounts.matches(order: order)

        return CartOrderComparison(
            missingItems: itemsComparison.missingItems,
            quantityMismatches: itemsComparison.quantityMismatches,
            couponsMatch: couponsMatch,
            customAmountsMatch: customAmountsMatch
        )
    }
}

/// Represents the result of comparing a cart with an order to detect discrepancies
public struct CartOrderComparison {
    /// Items that were expected in the cart but are missing from the order
    public let missingItems: [MissingCartItem]
    /// Items where the quantity in the order doesn't match the cart
    public let quantityMismatches: [QuantityMismatch]
    /// Whether the coupons in the cart match the order
    public let couponsMatch: Bool
    /// Whether the custom amounts in the cart match the order's active fee lines
    public let customAmountsMatch: Bool

    /// Returns true if there are any discrepancies between cart and order
    public var hasDiscrepancies: Bool {
        return !missingItems.isEmpty || !quantityMismatches.isEmpty || !couponsMatch || !customAmountsMatch
    }

    /// Represents an item that was expected in the cart but is missing from the order
    public struct MissingCartItem {
        /// The product ID (for simple products) or parent product ID (for variations)
        public let productID: Int64
        /// The variation ID (0 for simple products)
        public let variationID: Int64
        /// The product or variation name
        public let name: String
    }

    /// Represents an item where the quantity doesn't match between cart and order
    public struct QuantityMismatch {
        /// The product or variation name
        // periphery:ignore - part of public API
        public let name: String
        /// The quantity in the cart
        // periphery:ignore - part of public API
        public let expectedQuantity: Decimal
        /// The quantity in the order
        // periphery:ignore - part of public API
        public let actualQuantity: Decimal
    }
}

extension [POSCartItem] {
    func matches(order: Order?) -> Bool {
        guard let order else {
            return self.isEmpty
        }

        let consolidatedCartItems = self.reduce(into: [POSCartItem]()) { partialResult, nextItem in
            if let matchingIndex = partialResult.firstIndex(where: { $0.item.isEqual(to: nextItem.item) }) {
                let itemToUpdate = partialResult[matchingIndex]
                partialResult[matchingIndex] = POSCartItem(item: itemToUpdate.item, quantity: itemToUpdate.quantity + nextItem.quantity)
            } else {
                partialResult.append(nextItem)
            }
        }

        let consolidatedOrderItems = order.items.reduce(into: [OrderItem]()) { partialResult, nextItem in
            if let matchingIndex = partialResult.firstIndex(where: { $0.productID == nextItem.productID && $0.variationID == nextItem.variationID }) {
                let itemToUpdate = partialResult[matchingIndex]
                partialResult[matchingIndex] = itemToUpdate.copy(quantity: itemToUpdate.quantity + nextItem.quantity)
            } else {
                partialResult.append(nextItem)
            }
        }

        guard consolidatedCartItems.count == consolidatedOrderItems.count else {
            return false
        }

        for cartItem in consolidatedCartItems {
            guard consolidatedOrderItems.contains(where: { orderItem in
                cartItem.item.matches(orderItem: orderItem) && cartItem.quantity == orderItem.quantity
            }) else {
                return false
            }
        }
        return true
    }

    func compareWithOrder(_ order: Order?) -> ItemsComparison {
        guard let order else {
            // If there's no order but we have items, all items are missing
            let missingItems = self.compactMap { cartItem -> CartOrderComparison.MissingCartItem? in
                guard let (productID, variationID) = extractProductIDs(from: cartItem.item) else {
                    return nil
                }
                return CartOrderComparison.MissingCartItem(
                    productID: productID,
                    variationID: variationID,
                    name: cartItem.item.name
                )
            }
            return ItemsComparison(missingItems: missingItems, quantityMismatches: [])
        }

        // Group cart items by product/variation ID to consolidate duplicates
        let cartItemsByProductKey = Dictionary(grouping: self, by: { item -> String in
            guard let (productID, variationID) = extractProductIDs(from: item.item) else {
                // Use a unique UUID for each invalid item to prevent grouping them together.
                // This ensures each invalid item is reported separately in error handling
                // rather than being masked as a single consolidated entry.
                return "invalid_\(UUID())"
            }
            return variationID != 0 ? "variation_\(variationID)" : "product_\(productID)"
        })

        // Calculate total quantity for each product/variation in cart
        let cartQuantities = cartItemsByProductKey.mapValues { items in
            items.reduce(Decimal(0)) { $0 + $1.quantity }
        }

        // Group order items by product/variation ID
        let orderQuantities = Dictionary(grouping: order.items, by: { (item: OrderItem) -> String in
            item.variationID != 0 ? "variation_\(item.variationID)" : "product_\(item.productID)"
        }).mapValues { items in
            items.reduce(Decimal(0)) { $0 + $1.quantity }
        }

        var missingItems: [CartOrderComparison.MissingCartItem] = []
        var quantityMismatches: [CartOrderComparison.QuantityMismatch] = []

        // Check each unique product/variation in cart
        for (key, cartItems) in cartItemsByProductKey {
            guard let firstItem = cartItems.first,
                  let (productID, variationID) = extractProductIDs(from: firstItem.item) else {
                continue
            }

            let expectedQuantity = cartQuantities[key] ?? 0
            let actualQuantity = orderQuantities[key] ?? 0

            if actualQuantity == 0 {
                // Item is in cart but not in order at all
                missingItems.append(
                    CartOrderComparison.MissingCartItem(
                        productID: productID,
                        variationID: variationID,
                        name: firstItem.item.name
                    )
                )
            } else if actualQuantity != expectedQuantity {
                // Item is in both but quantities don't match
                quantityMismatches.append(
                    CartOrderComparison.QuantityMismatch(
                        name: firstItem.item.name,
                        expectedQuantity: expectedQuantity,
                        actualQuantity: actualQuantity
                    )
                )
            }
        }

        return ItemsComparison(missingItems: missingItems, quantityMismatches: quantityMismatches)
    }

    private func extractProductIDs(from item: POSOrderableItem) -> (productID: Int64, variationID: Int64)? {
        // Check if it's a simple product
        if let simpleProduct = item as? POSSimpleProduct {
            return (simpleProduct.productID, 0)
        }
        // Check if it's a variation
        else if let variation = item as? POSVariation {
            return (variation.productID, variation.productVariationID)
        }
        return nil
    }

    struct ItemsComparison {
        let missingItems: [CartOrderComparison.MissingCartItem]
        let quantityMismatches: [CartOrderComparison.QuantityMismatch]
    }

    func createGroupedOrderSyncProductInputs() -> [OrderSyncProductInput.ProductType: OrderSyncProductInput] {
        let orderSyncProductInputs = self.map { $0.item.toOrderSyncProductInput(quantity: $0.quantity) }

        // Group items by their `product`, which is actually a `ProductType` enum, representing a product or variation,
        // with an associated value for the underlying item.
        let groupedItems = Dictionary(grouping: orderSyncProductInputs, by: { $0.product })

        // Convert each group into a single `OrderSyncProductInput`
        let output = groupedItems.compactMapValues { items -> OrderSyncProductInput? in
            guard let firstItem = items.first else { return nil }

            // Aggregate the quantity for this item
            let totalQuantity = items.reduce(Decimal(0)) { $0 + $1.quantity }

            // Return a copy of the first item, with the aggregate quantity
            return OrderSyncProductInput(product: firstItem.product,
                                         quantity: totalQuantity,
                                         discount: firstItem.discount,
                                         baseSubtotal: firstItem.baseSubtotal,
                                         bundleConfiguration: firstItem.bundleConfiguration)
        }

        return output
    }
}

extension [POSCoupon] {
    func matches(order: Order?) -> Bool {
        guard let order else {
            return self.isEmpty
        }

        let orderCoupons = Set(order.coupons.map(\.code))
        let cartCoupons = Set(self.map(\.code))
        return orderCoupons == cartCoupons
    }
}
