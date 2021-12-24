import Foundation

extension Product {
    /// Converts a `Product` to an `OrderItem`
    ///
    public func toOrderItem(quantity: Decimal) -> OrderItem {
        let price = NSDecimalNumber(string: price)
        let total = quantity * price.decimalValue

        return OrderItem(itemID: 0,
                         name: name,
                         productID: productID,
                         variationID: 0,
                         quantity: quantity,
                         price: price,
                         sku: nil,
                         subtotal: "\(total)",
                         subtotalTax: "",
                         taxClass: "",
                         taxes: [],
                         total: "\(total)",
                         totalTax: "0",
                         attributes: []
        )
    }
}
