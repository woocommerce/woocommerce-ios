import Foundation


/// Represents an Order's Item Entity.
///
public struct OrderItem: Decodable {
    public let itemID: Int
    public let name: String
    public let productID: Int
    public let quantity: Int
    public let sku: String
    public let subtotal: String
    public let subtotalTax: String
    public let taxClass: String
    public let total: String
    public let totalTax: String
    public let variationID: Int
}


/// Defines all of the OrderItem's CodingKeys.
///
private extension OrderItem {

    enum CodingKeys: String, CodingKey {
        case itemID         = "id"
        case name           = "name"
        case productID      = "product_id"
        case quantity       = "quantity"
        case sku            = "sku"
        case subtotal       = "subtotal"
        case subtotalTax    = "subtotal_tax"
        case taxClass       = "tax_class"
        case total          = "total"
        case totalTax       = "total_tax"
        case variationID    = "variation_id"
    }
}
