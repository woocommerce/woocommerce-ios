import Foundation


/// Represents a computed summary of order items.
/// order items - refunded order items = aggregate order item data.
///
final class AggregateOrderItem {
    let productID: Int64
    let variationID: Int64

    let name: String

    /// Price and total are currency values.
    /// When handling currencies, `NSDecimalNumber` is a powerhouse
    /// for localization and string-to-number conversions.
    /// `Decimal` doesn't have all of the `NSDecimalNumber` APIs (yet).
    ///
    let price: NSDecimalNumber
    var quantity: Decimal
    let sku: String?
    var total: NSDecimalNumber

    /// Designated initializer.
    ///
    init(productID: Int64,
         variationID: Int64,
         name: String,
         price: NSDecimalNumber,
         quantity: Decimal,
         sku: String?,
         total: NSDecimalNumber) {
        self.productID = productID
        self.variationID = variationID
        self.name = name
        self.price = price
        self.quantity = quantity
        self.sku = sku
        self.total = total
    }
}


// MARK: - Comparable Conformance
//
extension AggregateOrderItem: Comparable {
    public static func == (lhs: AggregateOrderItem, rhs: AggregateOrderItem) -> Bool {
        return lhs.productID == rhs.productID &&
            lhs.variationID == rhs.variationID
    }

    public static func < (lhs: AggregateOrderItem, rhs: AggregateOrderItem) -> Bool {
        return lhs.productID < rhs.productID ||
            (lhs.productID == rhs.productID && lhs.variationID < rhs.variationID)
    }
}


// MARK: - Hashable Conformance
//
extension AggregateOrderItem: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(productID)
        hasher.combine(variationID)
    }
}
