import Foundation
import Yosemite

/// Generates mock order items
///
public struct MockOrderItem {
    public static func sampleItem(itemID: Int64 = 0,
                                  name: String = "",
                                  productID: Int64 = 0,
                                  variationID: Int64 = 0,
                                  quantity: Decimal = 0,
                                  price: NSDecimalNumber = 0,
                                  sku: String? = nil,
                                  subtotal: String = "0",
                                  subtotalTax: String = "0",
                                  taxClass: String = "",
                                  taxes: [OrderItemTax] = [],
                                  total: String = "0",
                                  totalTax: String = "0",
                                  attributes: [OrderItemAttribute] = []) -> OrderItem {
        return OrderItem(itemID: itemID,
                         name: name,
                         productID: productID,
                         variationID: variationID,
                         quantity: quantity,
                         price: price,
                         sku: sku,
                         subtotal: subtotal,
                         subtotalTax: subtotalTax,
                         taxClass: taxClass,
                         taxes: taxes,
                         total: total,
                         totalTax: totalTax,
                         attributes: attributes)
    }
}
