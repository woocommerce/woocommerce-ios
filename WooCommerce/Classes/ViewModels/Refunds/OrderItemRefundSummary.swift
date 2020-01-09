import Foundation


/// Represents a computed summary of refunded products
///
public class OrderItemRefundSummary {
    public let name: String
    public let productID: Int64
    public let variationID: Int64
    public var quantity: Decimal

    /// Price is a currency.
    /// When handling currencies, `NSDecimalNumber` is a powerhouse
    /// for localization and string-to-number conversions.
    /// `Decimal` doesn't yet have all of the `NSDecimalNumber` APIs.
    ///
    public let price: NSDecimalNumber
    public let sku: String?
    public var totalTax: NSDecimalNumber?

    /// Designated initializer.
    ///
    init(name: String, productID: Int64, variationID: Int64, quantity: Decimal, price: NSDecimalNumber, sku: String?, totalTax: NSDecimalNumber?) {
        self.name = name
        self.productID = productID
        self.variationID = variationID
        self.quantity = quantity
        self.price = price
        self.sku = sku
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
