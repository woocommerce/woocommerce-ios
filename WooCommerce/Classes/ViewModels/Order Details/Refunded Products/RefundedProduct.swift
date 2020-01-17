import Foundation


/// This model represents the aggregate data for refunded products.
///
final class RefundedProduct {
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
extension RefundedProduct: Comparable {
    public static func == (lhs: RefundedProduct, rhs: RefundedProduct) -> Bool {
        return lhs.productID == rhs.productID &&
            lhs.variationID == rhs.variationID
    }

    public static func < (lhs: RefundedProduct, rhs: RefundedProduct) -> Bool {
        return lhs.productID < rhs.productID ||
            (lhs.productID == rhs.productID && lhs.variationID < rhs.variationID)
    }
}


// MARK: - Hashable Conformance
//
extension RefundedProduct: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(productID)
        hasher.combine(variationID)
    }
}

