import Foundation


/// Represents a computed summary of refunded products
///
final class OrderItemRefundSummary {
    let productID: Int64
    let variationID: Int64

    let name: String

    /// Price, total, and totalTax are currency values.
    /// When handling currencies, `NSDecimalNumber` is a powerhouse
    /// for localization and string-to-number conversions.
    /// `Decimal` doesn't have all of the `NSDecimalNumber` APIs (yet).
    ///
    let price: NSDecimalNumber
    var quantity: Decimal
    let sku: String?
    var total: NSDecimalNumber
    var totalTax: NSDecimalNumber?

    /// Designated initializer.
    ///
    init(productID: Int64,
         variationID: Int64,
         name: String,
         price: NSDecimalNumber,
         quantity: Decimal,
         sku: String?,
         total: NSDecimalNumber,
         totalTax: NSDecimalNumber?)
    {
        self.productID = productID
        self.variationID = variationID
        self.name = name
        self.price = price
        self.quantity = quantity
        self.sku = sku
        self.total = total
        self.totalTax = totalTax
    }
}


// MARK: - Comparable Conformance
//
extension OrderItemRefundSummary: Comparable {
    public static func == (lhs: OrderItemRefundSummary, rhs: OrderItemRefundSummary) -> Bool {
        return lhs.productID == rhs.productID &&
            lhs.variationID == rhs.variationID
    }

    public static func < (lhs: OrderItemRefundSummary, rhs: OrderItemRefundSummary) -> Bool {
        return lhs.productID < rhs.productID ||
            (lhs.productID == rhs.productID && lhs.name < rhs.name)
    }
}


// MARK: - Hashable Conformance
//
extension OrderItemRefundSummary: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(productID)
        hasher.combine(variationID)
    }
}
