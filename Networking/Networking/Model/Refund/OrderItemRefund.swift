import Foundation


/// Represents an Order Item to be Refunded
///
public struct OrderItemRefund: Codable {
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
    public let total: String
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
                total: String,
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
        self.total = total
        self.totalTax = totalTax
        self.variationID = variationID
    }

    /// The public initializer for OrderItemRefund.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let itemID = try container.decode(Int.self, forKey: .itemID)
        let name = try container.decode(String.self, forKey: .name)
        let productID = try container.decode(Int.self, forKey: .productID)
        let decimalQuantity = try container.decode(Decimal.self, forKey: .quantity)
        let quantity = NSDecimalNumber(decimal: decimalQuantity)
        let decimalPrice = try container.decodeIfPresent(Decimal.self, forKey: .price) ?? Decimal(0)
        let price = NSDecimalNumber(decimal: decimalPrice)
        let sku = try container.decodeIfPresent(String.self, forKey: .sku)
        let subtotal = try container.decode(String.self, forKey: .subtotal)
        let subtotalTax = try container.decode(String.self, forKey: .subtotalTax)
        let taxClass = try container.decode(String.self, forKey: .taxClass)
        let taxes = try container.decode([OrderItemTaxRefund].self, forKey: .taxes)
        let total = try container.decode(String.self, forKey: .total)
        let totalTax = try container.decode(String.self, forKey: .totalTax)
        let variationID = try container.decode(Int.self, forKey: .variationID)

        // initialize the struct
        self.init(itemID: itemID,
                  name: name,
                  productID: productID,
                  quantity: quantity,
                  price: price,
                  sku: sku,
                  subtotal: subtotal,
                  subtotalTax: subtotalTax,
                  taxClass: taxClass,
                  taxes: taxes,
                  total: total,
                  totalTax: totalTax,
                  variationID: variationID)
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

        // TODO: encode the OrderItemTaxes container
        //try container.encode(taxes, forKey: .taxes)

        try container.encode(total, forKey: .total)
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
        case taxes          = "taxes"
        case total          = "total"
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
            lhs.total == rhs.total &&
            lhs.totalTax == rhs.totalTax &&
            lhs.variationID == rhs.variationID
    }

    public static func < (lhs: OrderItemRefund, rhs: OrderItemRefund) -> Bool {
        return lhs.itemID < rhs.itemID ||
            (lhs.itemID == rhs.itemID && lhs.productID < rhs.productID) ||
            (lhs.itemID == rhs.itemID && lhs.productID == rhs.productID && lhs.name < rhs.name)
    }
}
