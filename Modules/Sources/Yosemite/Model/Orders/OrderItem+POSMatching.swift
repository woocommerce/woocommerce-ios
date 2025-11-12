import Foundation

extension OrderItem {
    /// Checks if this OrderItem matches a POSOrderableItem
    /// Uses the POSOrderableItem's matches method which compares productID and variationID
    func productMatches(cartItem: POSOrderableItem) -> Bool {
        return cartItem.matches(orderItem: self)
    }
}
