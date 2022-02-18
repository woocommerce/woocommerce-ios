import Foundation
import Codegen

/// Represents an Order's Item Entity.
///
public struct OrderItem: Decodable, Equatable, Hashable, GeneratedFakeable, GeneratedCopiable {
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
    public let taxes: [OrderItemTax]
    public let total: String
    public let totalTax: String

    public let attributes: [OrderItemAttribute]

    /// OrderItem struct initializer.
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
                taxes: [OrderItemTax],
                total: String,
                totalTax: String,
                attributes: [OrderItemAttribute]) {
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
        self.attributes = attributes
    }

    /// The public initializer for OrderItem.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let itemID = try container.decode(Int64.self, forKey: .itemID)
        let productID = try container.decode(Int64.self, forKey: .productID)
        let variationID = try container.decode(Int64.self, forKey: .variationID)

        let isVariation = variationID > 0
        let name: String
        let attributes: [OrderItemAttribute]
        if isVariation {
            name = try ((container.decodeIfPresent(String.self, forKey: .variationParentName))
                        ?? container.decode(String.self, forKey: .name)).strippedHTML
        } else {
            name = try container.decode(String.self, forKey: .name).strippedHTML
        }

        let quantity = try container.decode(Decimal.self, forKey: .quantity)

        /// WC versions lower than `6.3` send the item price as a `number`.
        /// WC Versions equal or greater than `6.3` send the item price as a `string`.
        ///
        let decimalPrice = container.failsafeDecodeIfPresent(targetType: String.self,
                                                             forKey: .price,
                                                             alternativeTypes: [.decimal { String(describing: $0) }])
        let price = NSDecimalNumber(string: decimalPrice)

        let sku = try container.decodeIfPresent(String.self, forKey: .sku)
        let subtotal = try container.decode(String.self, forKey: .subtotal)
        let subtotalTax = try container.decode(String.self, forKey: .subtotalTax)
        let taxClass = try container.decode(String.self, forKey: .taxClass)
        let taxes = try container.decode([OrderItemTax].self, forKey: .taxes)
        let total = try container.decode(String.self, forKey: .total)
        let totalTax = try container.decode(String.self, forKey: .totalTax)

        // Do not throw errors in case new metadata is introduced with a different format
        let allAttributes = (try? container.decodeIfPresent([OrderItemAttribute].self, forKey: .attributes)) ?? []
        attributes = allAttributes.filter { !$0.name.hasPrefix("_") } // Exclude private items (marked with an underscore)

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
                  totalTax: totalTax,
                  attributes: attributes)
    }
}


/// Defines all of the OrderItem's CodingKeys.
///
extension OrderItem {

    enum CodingKeys: String, CodingKey {
        case itemID         = "id"
        case name
        case variationParentName = "parent_name"
        case attributes = "meta_data"
        case productID      = "product_id"
        case variationID    = "variation_id"
        case quantity
        case price
        case sku
        case subtotal
        case subtotalTax    = "subtotal_tax"
        case taxClass       = "tax_class"
        case taxes
        case total
        case totalTax       = "total_tax"
    }
}


// MARK: - Comparable Conformance
//
extension OrderItem: Comparable {
    public static func < (lhs: OrderItem, rhs: OrderItem) -> Bool {
        return lhs.itemID < rhs.itemID ||
            (lhs.itemID == rhs.itemID && lhs.productID < rhs.productID) ||
            (lhs.itemID == rhs.itemID && lhs.productID == rhs.productID && lhs.name < rhs.name)
    }
}
