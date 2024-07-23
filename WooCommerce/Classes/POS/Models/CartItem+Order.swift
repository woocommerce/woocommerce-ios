import struct Yosemite.Order
import struct Yosemite.OrderItem
import protocol Yosemite.POSItem

extension CartItem {
    /// Checks if the order has the same items as the cart does.
    /// Used in POS to check if we need to resync the Order with cart items
    /// - Returns: Whether the order has the same items as the cart does
    static func areOrderAndCartDifferent(order: Order?, cartItems: [CartItem]) -> Bool {
        guard let order else {
            return cartItems.isNotEmpty
        }
        // first we get list of all products 1 by 1
        var singleQuantityOrderItems: [OrderItem] = order.items.flatMap {
            Array(repeating: $0, count: $0.quantity.intValue)
        }
        var singleQuantityCartItems: [POSItem] = cartItems.flatMap {
            Array(repeating: $0.item, count: $0.quantity)
        }
        // if order and cart do not have the same count of items
        // we do not need to compare them one by one
        if singleQuantityOrderItems.count == singleQuantityCartItems.count {
            // sort items by productIDs to have them in same order for comparison
            singleQuantityOrderItems.sort { $0.productID < $1.productID }
            singleQuantityCartItems.sort { $0.productID < $1.productID }
            // check if product item is different
            for (index, cartItem) in singleQuantityCartItems.enumerated() {
                let orderItem = singleQuantityOrderItems[index]
                if cartItem.productID != orderItem.productID {
                    // TODO: https://github.com/woocommerce/woocommerce-ios/pull/13328/files#r1687631533
                    // - we should also add a logic to compare prices
                    // - but we should be aware of the fact that some
                    // products already have tax in the price
                    return true
                }
            }
            return false
        }
        return true
    }
}
