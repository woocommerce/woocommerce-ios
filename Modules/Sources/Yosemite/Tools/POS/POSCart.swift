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
