import Foundation


/// Represents an Order's Item Entity.
///
public struct OrderItem: Decodable {
    public let itemID: Int
    public let name: String
    public let productID: Int
    public let quantity: Int
    public let price: Double
    public let sku: String?
    public let subtotal: String
    public let subtotalTax: String
    public let taxClass: String
    public let total: String
    public let totalTax: String
    public let variationID: Int

    /// OrderItem struct initializer.
    ///
    public init(itemID: Int, name: String, productID: Int, quantity: Int, price: Double, sku: String, subtotal: String, subtotalTax: String, taxClass: String, total: String, totalTax: String, variationID: Int) {
        self.itemID = itemID
        self.name = name
        self.productID = productID
        self.quantity = quantity
        self.price = price
        self.sku = sku
        self.subtotal = subtotal
        self.subtotalTax = subtotalTax
        self.taxClass = taxClass
        self.total = total
        self.totalTax = totalTax
        self.variationID = variationID
    }
}


/// Defines all of the OrderItem's CodingKeys.
///
private extension OrderItem {

    enum CodingKeys: String, CodingKey {
        case itemID         = "id"
        case name           = "name"
        case productID      = "product_id"
        case quantity       = "quantity"
        case price          = "price"
        case sku            = "sku"
        case subtotal       = "subtotal"
        case subtotalTax    = "subtotal_tax"
        case taxClass       = "tax_class"
        case total          = "total"
        case totalTax       = "total_tax"
        case variationID    = "variation_id"
    }
}


// MARK: - Comparable Conformance
//
extension OrderItem: Comparable {
    public static func == (lhs: OrderItem, rhs: OrderItem) -> Bool {
        return lhs.itemID == rhs.itemID &&
            lhs.name == rhs.name &&
            lhs.productID == rhs.productID &&
            lhs.quantity == rhs.quantity &&
            lhs.price == rhs.price &&
            lhs.sku == rhs.sku &&
            lhs.subtotal == rhs.subtotal &&
            lhs.subtotalTax == rhs.subtotalTax &&
            lhs.taxClass == rhs.taxClass &&
            lhs.total == rhs.total &&
            lhs.totalTax == rhs.totalTax &&
            lhs.variationID == rhs.variationID
    }

    public static func < (lhs: OrderItem, rhs: OrderItem) -> Bool {
        return lhs.itemID < rhs.itemID ||
            (lhs.itemID == rhs.itemID && lhs.productID < rhs.productID) ||
            (lhs.itemID == rhs.itemID && lhs.productID == rhs.productID && lhs.name < rhs.name)
    }
}
