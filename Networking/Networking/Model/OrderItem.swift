import Foundation
import Codegen

/// Represents an Order's Item Entity.
///
public struct OrderItem: Codable, Equatable, Hashable, GeneratedFakeable, GeneratedCopiable {
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

    /// Item ID of parent `OrderItem`, if any.
    ///
    /// An `OrderItem` can have a parent if, for example, it is a bundled item within a product bundle.
    ///
    public let parent: Int64?

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
                attributes: [OrderItemAttribute],
                parent: Int64?) {
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
        self.parent = parent
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
        let decimalPrice = try container.decodeIfPresent(Decimal.self, forKey: .price) ?? Decimal(0)
        let price = NSDecimalNumber(decimal: decimalPrice)

        let sku = try container.decodeIfPresent(String.self, forKey: .sku)
        let subtotal = try container.decode(String.self, forKey: .subtotal)
        let subtotalTax = try container.decode(String.self, forKey: .subtotalTax)
        let taxClass = try container.decode(String.self, forKey: .taxClass)
        let taxes = try container.decode([OrderItemTax].self, forKey: .taxes)
        let total = try container.decode(String.self, forKey: .total)
        let totalTax = try container.decode(String.self, forKey: .totalTax)

        // Use failsafe decoding to discard any attributes with non-string values (currently not supported).
        let allAttributes = container.failsafeDecodeIfPresent(lossyList: [OrderItemAttribute].self, forKey: .attributes)
        attributes = allAttributes.filter { !$0.name.hasPrefix("_") } // Exclude private items (marked with an underscore)

        // Product Bundle extension properties:
        // If the order item is part of a product bundle, `bundledBy` is the parent order item (product bundle).
        // If it's not a bundled item, the API returns an empty string for `bundledBy` and the value will be `nil`.
        let bundledBy = container.failsafeDecodeIfPresent(Int64.self, forKey: .bundledBy)

        // Composite Products extension properties:
        // If the order item is a composite component, `compositeParent` is the parent order item (composite product).
        // If it's not a composite component, the API returns an empty string for `compositeParent` and the value will be `nil`.
        let compositeParent = container.failsafeDecodeIfPresent(Int64.self, forKey: .compositeParent)

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
                  attributes: attributes,
                  parent: bundledBy ?? compositeParent)
    }

    /// Encodes an order item.
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(itemID, forKey: .itemID)

        let parentID = variationID != 0 ? variationID : productID
        try container.encode(parentID, forKey: .productID)

        let nonDecimalQuantity = (quantity as NSDecimalNumber).int64Value
        try container.encode(nonDecimalQuantity, forKey: .quantity)

        if !subtotal.isEmpty {
            try container.encode(subtotal, forKey: .subtotal)
        }

        if !total.isEmpty {
            try container.encode(total, forKey: .total)
        }
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
        case bundledBy      = "bundled_by"
        case compositeParent = "composite_parent"
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
