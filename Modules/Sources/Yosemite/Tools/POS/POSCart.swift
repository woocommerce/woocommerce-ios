import Foundation

/// POSCart is different from the Cart in the POS app layer.
/// - The POS cart UI might show the cart items differently from how they appear in an order in wp-admin.

public struct POSCart {
    public let items: [POSCartItem]
    public let coupons: [POSCoupon]

    public init(items: [POSCartItem] = [], coupons: [POSCoupon] = []) {
        self.items = items
        self.coupons = coupons
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
        return items.matches(order: order) && coupons.matches(order: order)
    }

    func compareWithOrder(_ order: Order?) -> CartOrderComparison {
        let itemsComparison = items.compareWithOrder(order)
        let couponsMatch = coupons.matches(order: order)

        return CartOrderComparison(
            missingItems: itemsComparison.missingItems,
            quantityMismatches: itemsComparison.quantityMismatches,
            couponsMatch: couponsMatch
        )
    }
}

public struct CartOrderComparison {
    public let missingItems: [MissingCartItem]
    public let quantityMismatches: [QuantityMismatch]
    public let couponsMatch: Bool

    public var hasDiscrepancies: Bool {
        return !missingItems.isEmpty || !quantityMismatches.isEmpty || !couponsMatch
    }

    public struct MissingCartItem {
        public let productID: Int64
        public let variationID: Int64
        public let name: String
        public let expectedQuantity: Decimal
    }

    public struct QuantityMismatch {
        public let name: String
        public let expectedQuantity: Decimal
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
                    name: cartItem.item.name,
                    expectedQuantity: cartItem.quantity
                )
            }
            return ItemsComparison(missingItems: missingItems, quantityMismatches: [])
        }

        // Group cart items by product/variation ID to consolidate duplicates
        let cartItemsByProductKey = Dictionary(grouping: self, by: { item -> String in
            guard let (productID, variationID) = extractProductIDs(from: item.item) else {
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
                        name: firstItem.item.name,
                        expectedQuantity: expectedQuantity
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
