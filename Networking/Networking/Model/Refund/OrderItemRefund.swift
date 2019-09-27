import Foundation


/// Represents an Order Item to be Refunded
///
public struct OrderItemRefund: Encodable {
    public let itemID: Int
    public let name: String
    public let productID: Int
    public let quantity: NSDecimalNumber
    public let price: NSDecimalNumber
    public let sku: String?
    public let subtotal: String
    public let subtotalTax: String
    public let taxClass: String
    public let taxes: [OrderItemTaxRefund]
    public let refundTotal: String
    public let totalTax: String
    public let variationID: Int

    /// OrderItemRefund struct initializer.
    ///
    public init(itemID: Int,
                name: String,
                productID: Int,
                quantity: NSDecimalNumber,
                price: NSDecimalNumber,
                sku: String?,
                subtotal: String,
                subtotalTax: String,
                taxClass: String,
                taxes: [OrderItemTaxRefund],
                refundTotal: String,
                totalTax: String,
                variationID: Int) {
        self.itemID = itemID
        self.name = name
        self.productID = productID
        self.quantity = quantity
        self.price = price
        self.sku = sku
        self.subtotal = subtotal
        self.subtotalTax = subtotalTax
        self.taxClass = taxClass
        self.taxes = taxes
        self.refundTotal = refundTotal
        self.totalTax = totalTax
        self.variationID = variationID
    }

    /// The public encoder for OrderItemRefund.
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(itemID, forKey: .itemID)
        try container.encode(name, forKey: .name)
        try container.encode(productID, forKey: .productID)
        try container.encode(Double(truncating: quantity), forKey: .quantity)
        try container.encode(price.stringValue, forKey: .price)
        try container.encode(sku, forKey: .sku)
        try container.encode(subtotal, forKey: .subtotal)
        try container.encode(subtotalTax, forKey: .subtotalTax)
        try container.encode(taxClass, forKey: .taxClass)
//        try container.encodeIfPresent(OrderItemTaxRefund.self, forKey: .refundTax)
        try container.encode(refundTotal, forKey: .refundTotal)
        try container.encode(totalTax, forKey: .totalTax)
        try container.encode(variationID, forKey: .variationID)
    }
}


/// Defines all of the OrderItemRefund CodingKeys.
///
private extension OrderItemRefund {

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
        case refundTax      = "refund_tax"
        case refundTotal    = "refund_total"
        case totalTax       = "total_tax"
        case variationID    = "variation_id"
    }
}


// MARK: - Comparable Conformance
//
extension OrderItemRefund: Comparable {
    public static func == (lhs: OrderItemRefund, rhs: OrderItemRefund) -> Bool {
        return lhs.itemID == rhs.itemID &&
            lhs.name == rhs.name &&
            lhs.productID == rhs.productID &&
            lhs.quantity == rhs.quantity &&
            lhs.price == rhs.price &&
            lhs.sku == rhs.sku &&
            lhs.subtotal == rhs.subtotal &&
            lhs.subtotalTax == rhs.subtotalTax &&
            lhs.taxClass == rhs.taxClass &&
            lhs.refundTotal == rhs.refundTotal &&
            lhs.totalTax == rhs.totalTax &&
            lhs.variationID == rhs.variationID
    }

    public static func < (lhs: OrderItemRefund, rhs: OrderItemRefund) -> Bool {
        return lhs.itemID < rhs.itemID ||
            (lhs.itemID == rhs.itemID && lhs.productID < rhs.productID) ||
            (lhs.itemID == rhs.itemID && lhs.productID == rhs.productID && lhs.name < rhs.name)
    }
}
