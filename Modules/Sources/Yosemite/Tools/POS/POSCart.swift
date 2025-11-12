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
            let missingItems = self.map {
                CartOrderComparison.MissingCartItem(name: $0.item.name, expectedQuantity: $0.quantity)
            }
            return ItemsComparison(missingItems: missingItems, quantityMismatches: [])
        }

        // Consolidate cart items
        let consolidatedCartItems = self.reduce(into: [POSCartItem]()) { partialResult, nextItem in
            if let matchingIndex = partialResult.firstIndex(where: { $0.item.isEqual(to: nextItem.item) }) {
                let itemToUpdate = partialResult[matchingIndex]
                partialResult[matchingIndex] = POSCartItem(item: itemToUpdate.item, quantity: itemToUpdate.quantity + nextItem.quantity)
            } else {
                partialResult.append(nextItem)
            }
        }

        // Consolidate order items
        let consolidatedOrderItems = order.items.reduce(into: [OrderItem]()) { partialResult, nextItem in
            if let matchingIndex = partialResult.firstIndex(where: { $0.productID == nextItem.productID && $0.variationID == nextItem.variationID }) {
                let itemToUpdate = partialResult[matchingIndex]
                partialResult[matchingIndex] = itemToUpdate.copy(quantity: itemToUpdate.quantity + nextItem.quantity)
            } else {
                partialResult.append(nextItem)
            }
        }

        var missingItems: [CartOrderComparison.MissingCartItem] = []
        var quantityMismatches: [CartOrderComparison.QuantityMismatch] = []

        // Check each cart item against order items
        for cartItem in consolidatedCartItems {
            if let matchingOrderItem = consolidatedOrderItems.first(where: { $0.productMatches(cartItem: cartItem.item) }) {
                // Item exists in order, check quantity
                if cartItem.quantity != matchingOrderItem.quantity {
                    quantityMismatches.append(
                        CartOrderComparison.QuantityMismatch(
                            name: cartItem.item.name,
                            expectedQuantity: cartItem.quantity,
                            actualQuantity: matchingOrderItem.quantity
                        )
                    )
                }
            } else {
                // Item is in cart but not in order
                missingItems.append(
                    CartOrderComparison.MissingCartItem(
                        name: cartItem.item.name,
                        expectedQuantity: cartItem.quantity
                    )
                )
            }
        }

        return ItemsComparison(missingItems: missingItems, quantityMismatches: quantityMismatches)
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
