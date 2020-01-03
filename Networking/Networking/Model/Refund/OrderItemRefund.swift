import Foundation


/// Represents an Order Item to be Refunded
///
public struct OrderItemRefund: Codable {
    public let itemID: Int64
    public let name: String
    public let productID: Int64
    public let variationID: Int64
    public let quantity: Decimal

    /// Price is a currency.
    /// When handling currencies, `NSDecimalNumber` is a powerhouse
    /// for localization and string-to-number conversions.
    /// `Decimal` doesn't yet have all of the `NSDecimalNumber` APIs.
    ///
    public let price: NSDecimalNumber
    public let sku: String?
    public let subtotal: String
    public let subtotalTax: String
    public let taxClass: String
    public let taxes: [OrderItemTaxRefund]
    public let total: String
    public let totalTax: String

    /// OrderItemRefund struct initializer.
    ///
    public init(itemID: Int64,
                name: String,
                productID: Int64,
                variationID: Int64,
                quantity: Decimal,
                price: NSDecimalNumber,
                sku: String?,
                subtotal: String,
                subtotalTax: String,
                taxClass: String,
                taxes: [OrderItemTaxRefund],
                total: String,
                totalTax: String) {
        self.itemID = itemID
        self.name = name
        self.productID = productID
        self.variationID = variationID
        self.quantity = quantity
        self.price = price
        self.sku = sku
        self.subtotal = subtotal
        self.subtotalTax = subtotalTax
        self.taxClass = taxClass
        self.taxes = taxes
        self.total = total
        self.totalTax = totalTax
    }

    /// The public decoder for OrderItemRefund.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let itemID = try container.decode(Int64.self, forKey: .itemID)
        let name = try container.decode(String.self, forKey: .name)
        let productID = try container.decode(Int64.self, forKey: .productID)
        let variationID = try container.decode(Int64.self, forKey: .variationID)

        let quantity = try container.decode(Decimal.self, forKey: .quantity)
        let decimalPrice = try container.decodeIfPresent(Decimal.self, forKey: .price) ?? Decimal(0)
        let price = NSDecimalNumber(decimal: decimalPrice)

        let sku = try container.decodeIfPresent(String.self, forKey: .sku)
        let subtotal = try container.decode(String.self, forKey: .subtotal)
        let subtotalTax = try container.decode(String.self, forKey: .subtotalTax)
        let taxClass = try container.decode(String.self, forKey: .taxClass)
        let taxes = try container.decode([OrderItemTaxRefund].self, forKey: .taxes)
        let total = try container.decode(String.self, forKey: .total)
        let totalTax = try container.decode(String.self, forKey: .totalTax)

        // initialize the struct
        self.init(itemID: itemID,
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
                  totalTax: totalTax)
    }

    /// The public encoder for OrderItemRefund.
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(itemID, forKey: .itemID)
        try container.encode(name, forKey: .name)
        try container.encode(productID, forKey: .productID)
        try container.encode(variationID, forKey: .variationID)

        // Decimal does not play nice when encoding.
        // Cast the Decimal to an NSNumber, then convert to a Double.
        let doubleValue = Double(truncating: quantity as NSNumber)
        try container.encode(doubleValue, forKey: .quantity)
        try container.encode(price.stringValue, forKey: .price)

        try container.encode(subtotal, forKey: .subtotal)
        try container.encode(subtotalTax, forKey: .subtotalTax)
        try container.encode(taxClass, forKey: .taxClass)

        try container.encode(taxes, forKey: .taxes)

        try container.encode(total, forKey: .total)
        try container.encode(totalTax, forKey: .totalTax)
    }
}


/// Defines all of the OrderItemRefund CodingKeys.
///
private extension OrderItemRefund {

    enum CodingKeys: String, CodingKey {
        case itemID         = "id"
        case variationID    = "variation_id"
        case name
        case productID      = "product_id"
        case quantity
        case price
        case sku
        case subtotal
        case subtotalTax    = "subtotal_tax"
        case taxClass       = "tax_class"
        case total
        case totalTax       = "total_tax"
        case taxes
    }
}


// MARK: - Comparable Conformance
//
extension OrderItemRefund: Comparable {
    public static func == (lhs: OrderItemRefund, rhs: OrderItemRefund) -> Bool {
        return lhs.itemID == rhs.itemID &&
            lhs.productID == rhs.productID &&
            lhs.variationID == rhs.variationID
    }

    public static func < (lhs: OrderItemRefund, rhs: OrderItemRefund) -> Bool {
        return lhs.itemID < rhs.itemID ||
            (lhs.itemID == rhs.itemID && lhs.productID < rhs.productID) ||
            (lhs.itemID == rhs.itemID && lhs.productID == rhs.productID && lhs.name < rhs.name)
    }
}
