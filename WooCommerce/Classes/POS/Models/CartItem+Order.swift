import struct Yosemite.Order
import struct Yosemite.OrderItem
import typealias Yosemite.POSOrderableItem
import struct Yosemite.OrderSyncProductInput
import Foundation

extension [CartItem] {
    /// Checks if the order has the same items as the cart does.
    /// Used in POS to check if we need to resync the Order with cart items
    /// - Returns: Whether the order has the same items as the cart does
    func matchesOrder(_ order: Order?) -> Bool {
        guard let order else {
            return self.isEmpty
        }

        var mutableCartItems: [CartItem] = self
        for item in order.items {
            guard let matchingItemIndex = mutableCartItems.firstIndex(where: { cartItem in
                cartItem.item.matches(orderItem: item) && Decimal(cartItem.quantity) == item.quantity
            }) else {
                return false
            }
            mutableCartItems.remove(at: matchingItemIndex)
        }
        return mutableCartItems.isEmpty
    }
}
