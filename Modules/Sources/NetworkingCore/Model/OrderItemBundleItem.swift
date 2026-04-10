import Foundation
import Codegen

/// Networking layer and encodable only, when creating/updating an `OrderItem`.
/// Contains configurable properties of a bundle item when an order item is a bundle product.
public struct OrderItemBundleItem: Encodable, Equatable, Hashable, GeneratedFakeable, GeneratedCopiable {
    /// Bundle item ID.
    public let bundledItemID: Int64

    /// Bundle item's product ID.
    public let productID: Int64

    /// Quantity of the bundle item.
    public let quantity: Decimal

    /// Only `true` if the bundle item is optional and selected. If the bundle item is not optional, the value is `nil`.
    public let isOptionalAndSelected: Bool?

    /// Bundle item's variation ID if the item is a variable product.
    public let variationID: Int64?

    /// Bundle item's variation attributes if the item is a variable product. All attributes need to be specified ("Any" is not supported).
    public let variationAttributes: [ProductVariationAttribute]?

    public init(bundledItemID: Int64,
                productID: Int64,
                quantity: Decimal,
                isOptionalAndSelected: Bool?,
                variationID: Int64?,
                variationAttributes: [ProductVariationAttribute]?) {
        self.bundledItemID = bundledItemID
        self.productID = productID
        self.quantity = quantity
        self.isOptionalAndSelected = isOptionalAndSelected
        self.variationID = variationID
        self.variationAttributes = variationAttributes
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(bundledItemID, forKey: .bundledItemID)
        try container.encode(productID, forKey: .productID)
        try container.encode(quantity, forKey: .quantity)

        if let isOptionalAndSelected {
            if isOptionalAndSelected {
                try container.encode(true, forKey: .isOptionalAndSelected)
            } else {
                // This is a workaround to an API issue: Pe5pgL-3Vd-p2#api-issues
                // where a `false` boolean value needs to be encoded to a value so that
                // PHP `empty` should return `false`.
                try container.encode("no", forKey: .isOptionalAndSelected)
            }
        }

        if let variationID, let variationAttributes {
            try container.encode(variationID, forKey: .variationID)
            try container.encode(variationAttributes, forKey: .variationAttributes)
        }
    }

    enum CodingKeys: String, CodingKey {
        case bundledItemID = "bundled_item_id"
        case productID = "product_id"
        case quantity
        case isOptionalAndSelected = "optional_selected"
        case variationID = "variation_id"
        case variationAttributes = "attributes"
    }
}
