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

    /// Minimum bundled item quantity.
    public let quantityMin: Int64

    /// Maximum bundled item quantity.
    public let quantityMax: Int64

    /// Default bundled item quantity.
    public let quantityDefault: Int64

    /// Indicates whether the price of this bundled item is added to the base price of the bundle.
    public let pricedIndividually: Bool

    /// Indicates whether the bundled product is shipped separately from the bundle.
    public let shippedIndividually: Bool

    /// Indicates whether the title of the bundled product is overridden in front-end and e-mail templates.
    public let overrideTitle: Bool

    /// Title of the bundled product to display instead of the original product title, if overridden.
    public let title: String

    /// Indicates whether the short description of the bundled product is overridden in front-end templates.
    public let overrideDescription: Bool

    /// Short description of the bundled product to display instead of the original product short description, if overridden.
    public let description: String

    /// Indicates whether the bundled item is optional.
    public let optional: Bool

    /// Indicates whether the bundled product thumbnail is hidden in the single-product template.
    public let hideThumbnail: Bool

    /// Discount applied to the bundled product, applicable when the Priced Individually option is enabled.
    public let discount: String

    /// Indicates whether variations filtering is active, applicable for variable bundled products only.
    public let overrideVariations: Bool

    /// List of enabled variation IDs, applicable when variations filtering is active.
    public let allowedVariations: [Int64]

    /// Indicates whether the default variation attribute values are overridden, applicable for variable bundled products only.
    public let overrideDefaultVariationAttributes: Bool

    /// Overridden default variation attribute values, if applicable.
    public let defaultVariationAttributes: [ProductVariationAttribute]

    /// Indicates whether the bundled product is visible in the single-product template.
    public let singleProductVisibility: ProductBundleItemVisibility

    /// Indicates whether the bundled product is visible in cart templates.
    public let cartVisibility: ProductBundleItemVisibility

    /// Indicates whether the bundled product is visible in order/e-mail templates.
    public let orderVisibility: ProductBundleItemVisibility

    /// Indicates whether the bundled product price is visible in the single-product template. Applicable when the Priced Individually option is enabled.
    public let singleProductPriceVisibility: ProductBundleItemVisibility

    /// Indicates whether the bundled product price is visible in cart templates. Applicable when the Priced Individually option is enabled.
    public let cartPriceVisibility: ProductBundleItemVisibility

    /// Indicates whether the bundled product price is visible in order/e-mail templates. Applicable when the Priced Individually option is enabled.
    public let orderPriceVisibility: ProductBundleItemVisibility

    /// Stock status of the bundled item, taking minimum quantity into account.
    public let stockStatus: ProductBundleItemStockStatus

    /// ProductBundleItem struct initializer
    ///
    public init(bundledItemID: Int64,
                productID: Int64,
                menuOrder: Int64,
                quantityMin: Int64,
                quantityMax: Int64,
                quantityDefault: Int64,
                pricedIndividually: Bool,
                shippedIndividually: Bool,
                overrideTitle: Bool,
                title: String,
                overrideDescription: Bool,
                description: String,
                optional: Bool,
                hideThumbnail: Bool,
                discount: String,
                overrideVariations: Bool,
                allowedVariations: [Int64],
                overrideDefaultVariationAttributes: Bool,
                defaultVariationAttributes: [ProductVariationAttribute],
                singleProductVisibility: ProductBundleItemVisibility,
                cartVisibility: ProductBundleItemVisibility,
                orderVisibility: ProductBundleItemVisibility,
                singleProductPriceVisibility: ProductBundleItemVisibility,
                cartPriceVisibility: ProductBundleItemVisibility,
                orderPriceVisibility: ProductBundleItemVisibility,
                stockStatus: ProductBundleItemStockStatus) {
        self.bundledItemID = bundledItemID
        self.productID = productID
        self.menuOrder = menuOrder
        self.quantityMin = quantityMin
        self.quantityMax = quantityMax
        self.quantityDefault = quantityDefault
        self.pricedIndividually = pricedIndividually
        self.shippedIndividually = shippedIndividually
        self.overrideTitle = overrideTitle
        self.title = title
        self.overrideDescription = overrideDescription
        self.description = description
        self.optional = optional
        self.hideThumbnail = hideThumbnail
        self.discount = discount
        self.overrideVariations = overrideVariations
        self.allowedVariations = allowedVariations
        self.overrideDefaultVariationAttributes = overrideDefaultVariationAttributes
        self.defaultVariationAttributes = defaultVariationAttributes
        self.singleProductVisibility = singleProductVisibility
        self.cartVisibility = cartVisibility
        self.orderVisibility = orderVisibility
        self.singleProductPriceVisibility = singleProductPriceVisibility
        self.cartPriceVisibility = cartPriceVisibility
        self.orderPriceVisibility = orderPriceVisibility
        self.stockStatus = stockStatus
    }
}

/// Defines all of the ProductBundleItem CodingKeys
///
private extension ProductBundleItem {

    enum CodingKeys: String, CodingKey {
        case bundledItemID                      = "bundled_item_id"
        case productID                          = "product_id"
        case menuOrder                          = "menu_order"
        case quantityMin                        = "quantity_min"
        case quantityMax                        = "quantity_max"
        case quantityDefault                    = "quantity_default"
        case pricedIndividually                 = "priced_individually"
        case shippedIndividually                = "shipped_individually"
        case overrideTitle                      = "override_title"
        case title
        case overrideDescription                = "override_description"
        case description
        case optional
        case hideThumbnail                      = "hide_thumbnail"
        case discount
        case overrideVariations                 = "override_variations"
        case allowedVariations                  = "allowed_variations"
        case overrideDefaultVariationAttributes = "override_default_variation_attributes"
        case defaultVariationAttributes         = "default_variation_attributes"
        case singleProductVisibility            = "single_product_visibility"
        case cartVisibility                     = "cart_visibility"
        case orderVisibility                    = "order_visibility"
        case singleProductPriceVisibility       = "single_product_price_visibility"
        case cartPriceVisibility                = "cart_price_visibility"
        case orderPriceVisibility               = "order_price_visibility"
        case stockStatus                        = "stock_status"
    }
}

/// Represents all visibility options for ProductBundleItem settings.
///
public enum ProductBundleItemVisibility: String, Codable, GeneratedFakeable {
    case visible
    case hidden
}

/// Represents all ProductBundleItem stock statuses
///
public enum ProductBundleItemStockStatus: String, Codable, GeneratedFakeable {
    case inStock        = "in_stock"
    case outOfStock     = "out_of_stock"
    case onBackOrder    = "on_backorder"
}
