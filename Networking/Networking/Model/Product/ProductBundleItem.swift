import Foundation
import Codegen

/// Represents an item in a Product Bundle
///
public struct ProductBundleItem: Codable, Equatable, GeneratedCopiable, GeneratedFakeable {
    /// Bundled item ID
    public let bundledItemID: Int64

    /// Bundled product ID
    public let productID: Int64

    /// Bundled item menu order
    public let menuOrder: Int64

    /// Title of the bundled product to display.
    public let title: String

    /// Stock status of the bundled item, taking minimum quantity into account.
    public let stockStatus: ProductBundleItemStockStatus

    /// Minimum quantity of the item in a bundle product.
    public let minQuantity: Decimal

    /// Maximum quantity of the item in a bundle product.
    public let maxQuantity: Decimal?

    /// Default quantity of the item in a bundle product.
    public let defaultQuantity: Decimal

    /// Whether the bundle item is optional.
    public let isOptional: Bool

    /// Whether variations filtering is active, applicable for variable bundled products only.
    public let overridesVariations: Bool

    /// List of enabled variation IDs of the bundle item, applicable when variations filtering is active.
    public let allowedVariations: [Int64]

    /// Whether the default variation attribute values are overridden, applicable for variable bundled products only.
    public let overridesDefaultVariationAttributes: Bool

    /// Overridden default variation attribute values, if applicable.
    public let defaultVariationAttributes: [ProductVariationAttribute]

    /// Whether the price of this bundled item is added to the base price of the bundle.
    public let pricedIndividually: Bool

    /// ProductBundleItem struct initializer
    ///
    public init(bundledItemID: Int64,
                productID: Int64,
                menuOrder: Int64,
                title: String,
                stockStatus: ProductBundleItemStockStatus,
                minQuantity: Decimal,
                maxQuantity: Decimal?,
                defaultQuantity: Decimal,
                isOptional: Bool,
                overridesVariations: Bool,
                allowedVariations: [Int64],
                overridesDefaultVariationAttributes: Bool,
                defaultVariationAttributes: [ProductVariationAttribute],
                pricedIndividually: Bool) {
        self.bundledItemID = bundledItemID
        self.productID = productID
        self.menuOrder = menuOrder
        self.title = title
        self.stockStatus = stockStatus
        self.minQuantity = minQuantity
        self.maxQuantity = maxQuantity
        self.defaultQuantity = defaultQuantity
        self.isOptional = isOptional
        self.overridesVariations = overridesVariations
        self.allowedVariations = allowedVariations
        self.overridesDefaultVariationAttributes = overridesDefaultVariationAttributes
        self.defaultVariationAttributes = defaultVariationAttributes
        self.pricedIndividually = pricedIndividually
    }

    /// The public initializer for ProductBundleItem.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let bundledItemID = try container.decode(Int64.self, forKey: .bundledItemID)
        let productID = try container.decode(Int64.self, forKey: .productID)
        let menuOrder = try container.decode(Int64.self, forKey: .menuOrder)
        let title = try container.decode(String.self, forKey: .title)
        let stockStatus = try container.decode(ProductBundleItemStockStatus.self, forKey: .stockStatus)
        let minQuantity = try container.decode(Decimal.self, forKey: .minQuantity)
        // When there is no max quantity, an empty string is returned.
        let maxQuantity = container.failsafeDecodeIfPresent(decimalForKey: .maxQuantity)
        let defaultQuantity = try container.decode(Decimal.self, forKey: .defaultQuantity)
        let isOptional = try container.decode(Bool.self, forKey: .isOptional)
        let overridesVariations = try container.decode(Bool.self, forKey: .overridesVariations)
        let allowedVariations = try container.decode([Int64].self, forKey: .allowedVariations)
        let overridesDefaultVariationAttributes = try container.decode(Bool.self, forKey: .overridesDefaultVariationAttributes)
        let defaultVariationAttributes = try container.decode([ProductVariationAttribute].self, forKey: .defaultVariationAttributes)
        let pricedIndividually = try container.decode(Bool.self, forKey: .pricedIndividually)

        self.init(bundledItemID: bundledItemID,
                  productID: productID,
                  menuOrder: menuOrder,
                  title: title,
                  stockStatus: stockStatus,
                  minQuantity: minQuantity,
                  maxQuantity: maxQuantity,
                  defaultQuantity: defaultQuantity,
                  isOptional: isOptional,
                  overridesVariations: overridesVariations,
                  allowedVariations: allowedVariations,
                  overridesDefaultVariationAttributes: overridesDefaultVariationAttributes,
                  defaultVariationAttributes: defaultVariationAttributes,
                  pricedIndividually: pricedIndividually)
    }
}

/// Defines all of the ProductBundleItem CodingKeys
///
private extension ProductBundleItem {

    enum CodingKeys: String, CodingKey {
        case bundledItemID                      = "bundled_item_id"
        case productID                          = "product_id"
        case menuOrder                          = "menu_order"
        case title
        case stockStatus                        = "stock_status"
        case minQuantity = "quantity_min"
        case maxQuantity = "quantity_max"
        case defaultQuantity = "quantity_default"
        case isOptional = "optional"
        case overridesVariations = "override_variations"
        case allowedVariations = "allowed_variations"
        case overridesDefaultVariationAttributes = "override_default_variation_attributes"
        case defaultVariationAttributes = "default_variation_attributes"
        case pricedIndividually = "priced_individually"
    }
}

/// Represents all ProductBundleItem stock statuses
///
public enum ProductBundleItemStockStatus: String, Codable, GeneratedFakeable {
    case inStock        = "in_stock"
    case outOfStock     = "out_of_stock"
    case onBackOrder    = "on_backorder"
}
