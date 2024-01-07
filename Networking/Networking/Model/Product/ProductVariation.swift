import Foundation
import Codegen

/// Represents a Product Variation Entity.
///
public struct ProductVariation: Codable, GeneratedCopiable, Equatable, GeneratedFakeable {
    public let siteID: Int64
    public let productID: Int64

    public let productVariationID: Int64

    public let attributes: [ProductVariationAttribute]
    public let image: ProductImage?

    public let permalink: String

    public let dateCreated: Date
    public let dateModified: Date?
    public let dateOnSaleStart: Date?
    public let dateOnSaleEnd: Date?

    public let status: ProductStatus

    public let description: String?
    public let sku: String?

    public let price: String
    public let regularPrice: String?
    public let salePrice: String?
    public let onSale: Bool

    public let purchasable: Bool
    public let virtual: Bool

    public let downloadable: Bool
    public let downloads: [ProductDownload]
    public let downloadLimit: Int64     // defaults to -1
    public let downloadExpiry: Int64    // defaults to -1

    public let taxStatusKey: String     // taxable, shipping, none
    public let taxClass: String?

    public let manageStock: Bool
    public let stockQuantity: Decimal?    // Core API reports Int or null; some extensions allow decimal values as well
    public let stockStatus: ProductStockStatus

    public let backordersKey: String    // no, notify, yes
    public let backordersAllowed: Bool
    public let backordered: Bool

    public let weight: String?
    public let dimensions: ProductDimensions

    public let shippingClass: String?
    public let shippingClassID: Int64

    public let menuOrder: Int64

    /// Subscription settings. Applicable to variations in variable subscription-type products only.
    public let subscription: ProductSubscription?

    // MARK: Min/Max Quantities properties

    /// Minimum allowed quantity for the variation. Applicable with Min/Max Quantities extension only.
    public let minAllowedQuantity: String?

    /// Maximum allowed quantity for the variation. Applicable with Min/Max Quantities extension only.
    public let maxAllowedQuantity: String?

    /// "Group of" quantity, requiring customers to purchase the variation in multiples. Applicable with Min/Max Quantities extension only.
    public let groupOfQuantity: String?

    /// Overrides the product-level quantity rules with the variation rules. Applicable with Min/Max Quantities extension only.
    public let overrideProductQuantities: Bool?

    /// Computed Properties
    ///
    /// Whether the product variation has an integer (or nil) stock quantity.
    /// Decimal (non-integer) stock quantities currently aren't accepted by the Core API.
    /// Related issue: https://github.com/woocommerce/woocommerce-ios/issues/3494
    public var hasIntegerStockQuantity: Bool {
        guard let stockQuantity = stockQuantity else {
            return true
        }

        return stockQuantity.isInteger
    }

    /// ProductVariation struct initializer.
    ///
    public init(siteID: Int64,
                productID: Int64,
                productVariationID: Int64,
                attributes: [ProductVariationAttribute],
                image: ProductImage?,
                permalink: String,
                dateCreated: Date,
                dateModified: Date?,
                dateOnSaleStart: Date?,
                dateOnSaleEnd: Date?,
                status: ProductStatus,
                description: String?,
                sku: String?,
                price: String,
                regularPrice: String?,
                salePrice: String?,
                onSale: Bool,
                purchasable: Bool,
                virtual: Bool,
                downloadable: Bool,
                downloads: [ProductDownload],
                downloadLimit: Int64,
                downloadExpiry: Int64,
                taxStatusKey: String,
                taxClass: String?,
                manageStock: Bool,
                stockQuantity: Decimal?,
                stockStatus: ProductStockStatus,
                backordersKey: String,
                backordersAllowed: Bool,
                backordered: Bool,
                weight: String?,
                dimensions: ProductDimensions,
                shippingClass: String?,
                shippingClassID: Int64,
                menuOrder: Int64,
                subscription: ProductSubscription?,
                minAllowedQuantity: String?,
                maxAllowedQuantity: String?,
                groupOfQuantity: String?,
                overrideProductQuantities: Bool?) {
        self.siteID = siteID
        self.productID = productID
        self.productVariationID = productVariationID
        self.attributes = attributes
        self.image = image
        self.permalink = permalink
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.dateOnSaleStart = dateOnSaleStart
        self.dateOnSaleEnd = dateOnSaleEnd
        self.status = status
        self.description = description
        self.sku = sku
        self.price = price
        self.regularPrice = regularPrice
        self.salePrice = salePrice
        self.onSale = onSale
        self.purchasable = purchasable
        self.virtual = virtual
        self.downloadable = downloadable
        self.downloads = downloads
        self.downloadLimit = downloadLimit
        self.downloadExpiry = downloadExpiry
        self.taxStatusKey = taxStatusKey
        self.taxClass = taxClass
        self.manageStock = manageStock
        self.stockQuantity = stockQuantity
        self.stockStatus = stockStatus
        self.backordersKey = backordersKey
        self.backordersAllowed = backordersAllowed
        self.backordered = backordered
        self.weight = weight
        self.dimensions = dimensions
        self.shippingClass = shippingClass
        self.shippingClassID = shippingClassID
        self.menuOrder = menuOrder
        self.subscription = subscription
        self.minAllowedQuantity = minAllowedQuantity
        self.maxAllowedQuantity = maxAllowedQuantity
        self.groupOfQuantity = groupOfQuantity
        self.overrideProductQuantities = overrideProductQuantities
    }

    /// The public initializer for ProductVariation.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ProductVariationDecodingError.missingSiteID
        }

        guard let productID = decoder.userInfo[.productID] as? Int64 else {
            throw ProductVariationDecodingError.missingProductID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let productVariationID = try container.decode(Int64.self, forKey: .productVariationID)
        let attributes = try container.decode([ProductVariationAttribute].self, forKey: .attributes)
        let image = try container.decodeIfPresent(ProductImage.self, forKey: .image)
        // Even though a plain install of WooCommerce Core provides string values,
        // some plugins alter the field value from String to Int or Decimal.
        // We handle this by returning an empty string if we can't decode it
        let permalink: String = {
            do {
                return try container.decode(String.self, forKey: .permalink)
            } catch {
                DDLogError("⛔️ Error parsing `permalink` for product variations in Product ID \(productID): \(error)")
                return ""
            }
        }()
        let dateCreated = (try? container.decode(Date.self, forKey: .dateCreated)) ?? Date()
        let dateModified = try? container.decodeIfPresent(Date.self, forKey: .dateModified)
        let dateOnSaleStart = try container.decodeIfPresent(Date.self, forKey: .dateOnSaleStart)
        let dateOnSaleEnd = try container.decodeIfPresent(Date.self, forKey: .dateOnSaleEnd)
        let statusKey = try container.decode(String.self, forKey: .statusKey)
        let status = ProductStatus(rawValue: statusKey)
        let description = try container.decodeIfPresent(String.self, forKey: .description)

        // Even though a plain install of WooCommerce Core provides String values,
        // some plugins alter the field value from String to Int or Decimal.
        let sku = container.failsafeDecodeIfPresent(targetType: String.self,
                                                    forKey: .sku,
                                                    alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })])

        // Even though a plain install of WooCommerce Core provides string values,
        // some plugins alter the field value from String to Int or Decimal.
        let price = container.failsafeDecodeIfPresent(targetType: String.self,
                                                      forKey: .price,
                                                      alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })])
            ?? ""

        let regularPrice = container.failsafeDecodeIfPresent(targetType: String.self,
                                                             forKey: .regularPrice,
                                                             alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })])
            ?? ""

        // Even though WooCommerce Core returns Bool values,
        // some plugins alter the field value from Bool to String.
        let onSale = container.failsafeDecodeIfPresent(targetType: Bool.self,
                                                       forKey: .onSale,
                                                       alternativeTypes: [ .string(transform: { NSString(string: $0).boolValue })]) ?? false

        // Even though a plain install of WooCommerce Core provides string values,
        // some plugins alter the field value from String to Int or Decimal.
        let salePrice = container.failsafeDecodeIfPresent(targetType: String.self,
                                                          forKey: .salePrice,
                                                          shouldDecodeTargetTypeFirst: false,
                                                          alternativeTypes: [
                                                            .string(transform: { (onSale && $0.isEmpty) ? "0" : $0 }),
                                                            .decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })])
            ?? ""

        // Even though WooCommerce Core returns Bool values,
        // some plugins alter the field value from Bool to Int (1 or 0)
        let purchasable = container.failsafeDecodeIfPresent(targetType: Bool.self, forKey: .purchasable,
                                                            alternativeTypes: [
                                                                .integer(transform: { ($0 as NSNumber).boolValue })])
        ?? true
        let virtual = try container.decode(Bool.self, forKey: .virtual)
        let downloadable = try container.decode(Bool.self, forKey: .downloadable)
        let downloads = try container.decode([ProductDownload].self, forKey: .downloads)
        let downloadLimit = try container.decode(Int64.self, forKey: .downloadLimit)
        let downloadExpiry = try container.decode(Int64.self, forKey: .downloadExpiry)
        let taxStatusKey = try container.decode(String.self, forKey: .taxStatusKey)
        let taxClass = try container.decodeIfPresent(String.self, forKey: .taxClass)

        // Even though the API docs claim `manageStock` is a bool, it's possible that `"parent"`
        // could be returned as well (typically with variations) — we need to account for this.
        // A "parent" value means that stock mgmt is turned off at the product variation and it is managed at the parent product-level.
        // Therefore, we need to set this var as `false` in this situation.
        // See: https://github.com/woocommerce/woocommerce-ios/issues/884 for more deets
        let manageStock = container.failsafeDecodeIfPresent(targetType: Bool.self,
                                                            forKey: .manageStock,
                                                            alternativeTypes: [
                                                                .string(transform: { value in
                                                                    guard value.lowercased() == Values.manageStockParent else {
                                                                        let message = "Unexpected manage stock value: \(value)"
                                                                        assertionFailure(message)
                                                                        DDLogError(message)
                                                                        return false
                                                                    }
                                                                    return false
                                                                })
        ]) ?? false

        // Even though WooCommerce Core returns Int or null values,
        // some plugins alter the field value from Int to Decimal or String.
        // We handle this as an optional Decimal value.
        let stockQuantity = container.failsafeDecodeIfPresent(decimalForKey: .stockQuantity)

        let stockStatusKey = try container.decode(String.self, forKey: .stockStatusKey)
        let stockStatus = ProductStockStatus(rawValue: stockStatusKey)
        let backordersKey = try container.decode(String.self, forKey: .backordersKey)

        // Even though WooCommerce Core returns Bool values,
        // some plugins alter the field value from Bool to String.
        let backordersAllowed = container.failsafeDecodeIfPresent(targetType: Bool.self,
                                                                  forKey: .backordersAllowed,
                                                                  alternativeTypes: [ .string(transform: { NSString(string: $0).boolValue })]) ?? false

        let backordered = try container.decode(Bool.self, forKey: .backordered)

        // Even though a plain install of WooCommerce Core provides String values,
        // some plugins alter the field value from String to Int or Decimal.
        let weight = container.failsafeDecodeIfPresent(targetType: String.self,
                                                       forKey: .weight,
                                                       alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })])
        let dimensions = try container.decode(ProductDimensions.self, forKey: .dimensions)
        let shippingClass = try container.decodeIfPresent(String.self, forKey: .shippingClass)
        let shippingClassID = try container.decode(Int64.self, forKey: .shippingClassID)
        let menuOrder = try container.decode(Int64.self, forKey: .menuOrder)

        // Subscription settings for subscription variations
        let subscription = try? container.decodeIfPresent(ProductMetadataExtractor.self, forKey: .metadata)?.extractProductSubscription()

        // Min/Max Quantities properties
        let minAllowedQuantity = try? container.decodeIfPresent(ProductMetadataExtractor.self, forKey: .metadata)?
            .extractStringValue(forKey: MetadataKeys.minAllowedQuantity)
        let maxAllowedQuantity = try? container.decodeIfPresent(ProductMetadataExtractor.self, forKey: .metadata)?
            .extractStringValue(forKey: MetadataKeys.maxAllowedQuantity)
        let groupOfQuantity = try? container.decodeIfPresent(ProductMetadataExtractor.self, forKey: .metadata)?
            .extractStringValue(forKey: MetadataKeys.groupOfQuantity)
        let overrideProductQuantities: Bool? = {
            guard let minMaxRules = try? container.decodeIfPresent(ProductMetadataExtractor.self, forKey: .metadata)?
                .extractStringValue(forKey: MetadataKeys.minMaxRules) else {
                return nil
            }
            return (minMaxRules as NSString).boolValue
        }()

        self.init(siteID: siteID,
                  productID: productID,
                  productVariationID: productVariationID,
                  attributes: attributes,
                  image: image,
                  permalink: permalink,
                  dateCreated: dateCreated,
                  dateModified: dateModified,
                  dateOnSaleStart: dateOnSaleStart,
                  dateOnSaleEnd: dateOnSaleEnd,
                  status: status,
                  description: description,
                  sku: sku,
                  price: price,
                  regularPrice: regularPrice,
                  salePrice: salePrice,
                  onSale: onSale,
                  purchasable: purchasable,
                  virtual: virtual,
                  downloadable: downloadable,
                  downloads: downloads,
                  downloadLimit: downloadLimit,
                  downloadExpiry: downloadExpiry,
                  taxStatusKey: taxStatusKey,
                  taxClass: taxClass,
                  manageStock: manageStock,
                  stockQuantity: stockQuantity,
                  stockStatus: stockStatus,
                  backordersKey: backordersKey,
                  backordersAllowed: backordersAllowed,
                  backordered: backordered,
                  weight: weight,
                  dimensions: dimensions,
                  shippingClass: shippingClass,
                  shippingClassID: shippingClassID,
                  menuOrder: menuOrder,
                  subscription: subscription,
                  minAllowedQuantity: minAllowedQuantity,
                  maxAllowedQuantity: maxAllowedQuantity,
                  groupOfQuantity: groupOfQuantity,
                  overrideProductQuantities: overrideProductQuantities)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(image, forKey: .image)

        // Needed for bulk update variations, in other API calls it is ingored
        try container.encode(productVariationID, forKey: .productVariationID)

        try container.encode(description, forKey: .description)
        try container.encode(status.rawValue, forKey: .statusKey)

        // Price Settings.
        try container.encode(regularPrice, forKey: .regularPrice)
        try container.encode(salePrice, forKey: .salePrice)

        // We need to send empty string if fields are null, because there is a bug on the API side
        // Issue: https://github.com/woocommerce/woocommerce/issues/25350
        if dateOnSaleStart == nil {
            try container.encode("", forKey: .dateOnSaleStart)
        } else {
            try container.encode(dateOnSaleStart, forKey: .dateOnSaleStart)
        }
        if dateOnSaleEnd == nil {
            try container.encode("", forKey: .dateOnSaleEnd)
        } else {
            try container.encode(dateOnSaleEnd, forKey: .dateOnSaleEnd)
        }

        try container.encode(taxStatusKey, forKey: .taxStatusKey)
        //The backend for the standard tax class return "standard",
        // but to set the standard tax class it accept only an empty string "" in the POST request
        let newTaxClass = taxClass == "standard" ? "" : taxClass
        try container.encode(newTaxClass, forKey: .taxClass)

        // Shipping Settings.
        try container.encode(weight, forKey: .weight)
        try container.encode(dimensions, forKey: .dimensions)
        try container.encode(shippingClass, forKey: .shippingClass)

        // Inventory Settings.
        try container.encode(sku, forKey: .sku)
        try container.encode(manageStock, forKey: .manageStock)
        try container.encode(stockStatus.rawValue, forKey: .stockStatusKey)
        if hasIntegerStockQuantity {
            try container.encode(stockQuantity, forKey: .stockQuantity)
        }
        try container.encode(backordersKey, forKey: .backordersKey)

        // Variation (Local) Attributes
        try container.encode(attributes, forKey: .attributes)

        // Metadata
        let metaDataValuePairs = buildMetaDataValuePairs()
        if metaDataValuePairs.isEmpty == false {
            try container.encode(metaDataValuePairs, forKey: .metadata)
        }
    }

    private func buildMetaDataValuePairs() -> [KeyValuePair] {
        if let subscription {
            return subscription.toKeyValuePairs()
        }
        return []
    }
}

/// Defines all of the ProductVariation CodingKeys
///
extension ProductVariation {

    enum CodingKeys: String, CodingKey {
        case productVariationID = "id"
        case permalink

        case dateCreated = "date_created_gmt"
        case dateModified = "date_modified_gmt"
        case dateOnSaleStart  = "date_on_sale_from_gmt"
        case dateOnSaleEnd = "date_on_sale_to_gmt"

        case statusKey = "status"

        case description

        case sku
        case price
        case regularPrice   = "regular_price"
        case salePrice      = "sale_price"
        case onSale         = "on_sale"

        case purchasable

        case virtual

        case downloadable
        case downloads
        case downloadLimit  = "download_limit"
        case downloadExpiry = "download_expiry"

        case taxStatusKey   = "tax_status"
        case taxClass       = "tax_class"

        case manageStock    = "manage_stock"
        case stockQuantity  = "stock_quantity"
        case stockStatusKey = "stock_status"

        case backordersKey      = "backorders"
        case backordersAllowed  = "backorders_allowed"
        case backordered

        case weight
        case dimensions

        case shippingClass      = "shipping_class"
        case shippingClassID    = "shipping_class_id"

        case image

        case attributes
        case menuOrder          = "menu_order"

        case metadata           = "meta_data"
    }

    enum MetadataKeys {
        static let minAllowedQuantity = "variation_minimum_allowed_quantity"
        static let maxAllowedQuantity = "variation_maximum_allowed_quantity"
        static let groupOfQuantity    = "variation_group_of_quantity"
        static let minMaxRules        = "min_max_rules"
    }
}

// MARK: - Constants!
//
private extension ProductVariation {
    enum Values {
        static let manageStockParent = "parent"
    }
}

// MARK: - Decoding Errors
//
enum ProductVariationDecodingError: Error {
    case missingSiteID
    case missingProductID
}

// MARK: - Hashable Conformance
//
extension ProductVariation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(siteID)
        hasher.combine(productID)
        hasher.combine(productVariationID)
    }
}
