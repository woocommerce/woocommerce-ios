import Foundation
import Yosemite
import Codegen

/// This model represents a computed summary of order items.
/// (order items - refunded order items) = aggregate order item data.
///
struct AggregateOrderItem: Equatable, GeneratedCopiable {
    let itemID: String
    let productID: Int64
    let variationID: Int64

    let name: String

    /// Price and total are currency values.
    /// When handling currencies, `NSDecimalNumber` is a powerhouse
    /// for localization and string-to-number conversions.
    /// `Decimal` doesn't have all of the `NSDecimalNumber` APIs (yet).
    ///
    let price: NSDecimalNumber?
    var quantity: Decimal
    let sku: String?
    let total: NSDecimalNumber?

    let imageURL: URL?

    let attributes: [OrderItemAttribute]

    /// Item ID of the parent order item, if any.
    ///
    let parent: Int64?

    /// Designated initializer.
    ///
    init(itemID: String,
         productID: Int64,
         variationID: Int64,
         name: String,
         price: NSDecimalNumber?,
         quantity: Decimal,
         sku: String?,
         total: NSDecimalNumber?,
         imageURL: URL? = nil,
         attributes: [OrderItemAttribute],
         parent: Int64?) {
        self.itemID = itemID
        self.productID = productID
        self.variationID = variationID
        self.name = name
        self.price = price
        self.quantity = quantity
        self.sku = sku
        self.total = total
        self.imageURL = imageURL
        self.attributes = attributes
        self.parent = parent
    }
}


// MARK: - Comparable Conformance
//
extension AggregateOrderItem: Comparable {
    static func < (lhs: AggregateOrderItem, rhs: AggregateOrderItem) -> Bool {
        return lhs.itemID < rhs.itemID
    }
}


// MARK: - Helper Methods
//
extension AggregateOrderItem {
    /// Returns the variant if it exists
    ///
    var productOrVariationID: Int64 {
        if variationID == 0 {
            return productID
        }

        return variationID
    }
}
