import Foundation
import Codegen

/// Represents a Product Entity.
///
public struct Product: Codable, GeneratedCopiable, Equatable, GeneratedFakeable {
    public let siteID: Int64
    public let productID: Int64
    public let name: String
    public let slug: String
    public let permalink: String

    public let date: Date               // Calculated date based on `dateCreated`, `dateModified`, and `statusKey`
    public let dateCreated: Date        // gmt
    public let dateModified: Date?      // gmt
    public let dateOnSaleStart: Date?   // gmt
    public let dateOnSaleEnd: Date?     // gmt

    public let productTypeKey: String
    public let statusKey: String        // draft, pending, private, published
    public let featured: Bool
    public let catalogVisibilityKey: String // visible, catalog, search, hidden

    public let fullDescription: String?
    public let shortDescription: String?
    public let sku: String?

    public let price: String
    public let regularPrice: String?
    public let salePrice: String?
    public let onSale: Bool

    public let purchasable: Bool
    public let totalSales: Int
    public let virtual: Bool

    public let downloadable: Bool
    public let downloads: [ProductDownload]
    public let downloadLimit: Int64       // defaults to -1
    public let downloadExpiry: Int64      // defaults to -1

    public let buttonText: String       // External products only
    public let externalURL: String?     // External products only
    public let taxStatusKey: String     // taxable, shipping, none
    public let taxClass: String?

    public let manageStock: Bool
    public let stockQuantity: Decimal?    // Core API reports Int or null; some extensions allow decimal values as well
    public let stockStatusKey: String   // instock, outofstock, backorder

    public let backordersKey: String    // no, notify, yes
    public let backordersAllowed: Bool
    public let backordered: Bool

    public let soldIndividually: Bool
    public let weight: String?
    public let dimensions: ProductDimensions

    public let shippingRequired: Bool
    public let shippingTaxable: Bool
    public let shippingClass: String?
    public let shippingClassID: Int64
    public let productShippingClass: ProductShippingClass?

    public let reviewsAllowed: Bool
    public let averageRating: String
    public let ratingCount: Int

    public let relatedIDs: [Int64]
    public let upsellIDs: [Int64]
    public let crossSellIDs: [Int64]
    public let parentID: Int64

    public let purchaseNote: String?
    public let categories: [ProductCategory]
    public let tags: [ProductTag]
    public let images: [ProductImage]

    public let attributes: [ProductAttribute]
    public let defaultAttributes: [ProductDefaultAttribute]
    public let variations: [Int64]
    public let groupedProducts: [Int64]

    public let menuOrder: Int

    public let addOns: [ProductAddOn]

    /// Whether the product was added automatically for a trial store
    public let isSampleItem: Bool

    // MARK: Product Bundle properties

    /// Stock status of this bundle, taking bundled product quantity requirements and limitations into account. Applicable for bundle-type products only.
    public let bundleStockStatus: ProductStockStatus?

    /// Quantity of bundles left in stock, taking bundled product quantity requirements into account. Applicable for bundle-type products only.
    public let bundleStockQuantity: Int64?

    /// Optional min bundle size (total number of bundle items) used in bundle configuration. Applicable for bundle-type products only.
    public let bundleMinSize: Decimal?

    /// Optional max bundle size (total number of bundle items) used in bundle configuration. Applicable for bundle-type products only.
    public let bundleMaxSize: Decimal?

    /// List of bundled item data contained in this product.
    public let bundledItems: [ProductBundleItem]

    // MARK: Composite Product properties

    /// List of components that this product consists of. Applicable to composite-type products only.
    public let compositeComponents: [ProductCompositeComponent]

    // MARK: Subscription Product properties

    /// Subscription settings. Applicable to subscription-type products only.
    public let subscription: ProductSubscription?

    // MARK: Min/Max Quantities properties

    /// Minimum allowed quantity for the product. Applicable with Min/Max Quantities extension only.
    public let minAllowedQuantity: String?

    /// Maximum allowed quantity for the product. Applicable with Min/Max Quantities extension only.
    public let maxAllowedQuantity: String?

    /// "Group of" quantity, requiring customers to purchase the product in multiples. Applicable with Min/Max Quantities extension only.
    public let groupOfQuantity: String?

    /// Combines the quantities of all purchased variations when checking quantity rules.
    /// Applicable with variable products and Min/Max Quantities extension only.
    public let combineVariationQuantities: Bool?

    /// Computed Properties
    ///
    public var productStatus: ProductStatus {
        return ProductStatus(rawValue: statusKey)
    }

    public var productCatalogVisibility: ProductCatalogVisibility {
        return ProductCatalogVisibility(rawValue: catalogVisibilityKey)
    }

    public var productStockStatus: ProductStockStatus {
        return ProductStockStatus(rawValue: stockStatusKey)
    }

    public var productType: ProductType {
        return ProductType(rawValue: productTypeKey)
    }

    public var backordersSetting: ProductBackordersSetting {
        return ProductBackordersSetting(rawValue: backordersKey)
    }

    public var productTaxStatus: ProductTaxStatus {
        return ProductTaxStatus(rawValue: taxStatusKey)
    }

    /// Filtered product attributes available for variations
    /// (attributes with `variation == true`)
    ///
    public var attributesForVariations: [ProductAttribute] {
        attributes.filter { $0.variation }
    }

    /// Whether the product has an integer (or nil) stock quantity.
    /// Decimal (non-integer) stock quantities currently aren't accepted by the Core API.
    /// Related issue: https://github.com/woocommerce/woocommerce-ios/issues/3494
    public var hasIntegerStockQuantity: Bool {
        guard let stockQuantity = stockQuantity else {
            return true
        }

        return stockQuantity.isInteger
    }

    /// Returns `true` if the product has a remote representation; `false` otherwise.
    ///
    public var existsRemotely: Bool {
        productID != 0
    }

    /// Product struct initializer.
    ///
    public init(siteID: Int64,
                productID: Int64,
                name: String,
                slug: String,
                permalink: String,
                date: Date,
                dateCreated: Date,
                dateModified: Date?,
                dateOnSaleStart: Date?,
                dateOnSaleEnd: Date?,
                productTypeKey: String,
                statusKey: String,
                featured: Bool,
                catalogVisibilityKey: String,
                fullDescription: String?,
                shortDescription: String?,
                sku: String?,
                price: String,
                regularPrice: String?,
                salePrice: String?,
                onSale: Bool,
                purchasable: Bool,
                totalSales: Int,
                virtual: Bool,
                downloadable: Bool,
                downloads: [ProductDownload],
                downloadLimit: Int64,
                downloadExpiry: Int64,
                buttonText: String,
                externalURL: String?,
                taxStatusKey: String,
                taxClass: String?,
                manageStock: Bool,
                stockQuantity: Decimal?,
                stockStatusKey: String,
                backordersKey: String,
                backordersAllowed: Bool,
                backordered: Bool,
                soldIndividually: Bool,
                weight: String?,
                dimensions: ProductDimensions,
                shippingRequired: Bool,
                shippingTaxable: Bool,
                shippingClass: String?,
                shippingClassID: Int64,
                productShippingClass: ProductShippingClass?,
                reviewsAllowed: Bool,
                averageRating: String,
                ratingCount: Int,
                relatedIDs: [Int64],
                upsellIDs: [Int64],
                crossSellIDs: [Int64],
                parentID: Int64,
                purchaseNote: String?,
                categories: [ProductCategory],
                tags: [ProductTag],
                images: [ProductImage],
                attributes: [ProductAttribute],
                defaultAttributes: [ProductDefaultAttribute],
                variations: [Int64],
                groupedProducts: [Int64],
                menuOrder: Int,
                addOns: [ProductAddOn],
                isSampleItem: Bool,
                bundleStockStatus: ProductStockStatus?,
                bundleStockQuantity: Int64?,
                bundleMinSize: Decimal?,
                bundleMaxSize: Decimal?,
                bundledItems: [ProductBundleItem],
                compositeComponents: [ProductCompositeComponent],
                subscription: ProductSubscription?,
                minAllowedQuantity: String?,
                maxAllowedQuantity: String?,
                groupOfQuantity: String?,
                combineVariationQuantities: Bool?) {
        self.siteID = siteID
        self.productID = productID
        self.name = name
        self.slug = slug
        self.permalink = permalink
        self.date = date
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.dateOnSaleStart = dateOnSaleStart
        self.dateOnSaleEnd = dateOnSaleEnd
        self.productTypeKey = productTypeKey
        self.statusKey = statusKey
        self.featured = featured
        self.catalogVisibilityKey = catalogVisibilityKey
        self.fullDescription = fullDescription
        self.shortDescription = shortDescription
        self.sku = sku
        self.price = price
        self.regularPrice = regularPrice
        self.salePrice = salePrice
        self.onSale = onSale
        self.purchasable = purchasable
        self.totalSales = totalSales
        self.virtual = virtual
        self.downloadable = downloadable
        self.downloads = downloads
        self.downloadLimit = downloadLimit
        self.downloadExpiry = downloadExpiry
        self.buttonText = buttonText
        self.externalURL = externalURL
        self.taxStatusKey = taxStatusKey
        self.taxClass = taxClass
        self.manageStock = manageStock
        self.stockQuantity = stockQuantity
        self.stockStatusKey = stockStatusKey
        self.backordersKey = backordersKey
        self.backordersAllowed = backordersAllowed
        self.backordered = backordered
        self.soldIndividually = soldIndividually
        self.weight = weight
        self.dimensions = dimensions
        self.shippingRequired = shippingRequired
        self.shippingTaxable = shippingTaxable
        self.shippingClass = shippingClass
        self.shippingClassID = shippingClassID
        self.productShippingClass = productShippingClass
        self.reviewsAllowed = reviewsAllowed
        self.averageRating = averageRating
        self.ratingCount = ratingCount
        self.relatedIDs = relatedIDs
        self.upsellIDs = upsellIDs
        self.crossSellIDs = crossSellIDs
        self.parentID = parentID
        self.purchaseNote = purchaseNote
        self.categories = categories
        self.tags = tags
        self.images = images
        self.attributes = attributes
        self.defaultAttributes = defaultAttributes
        self.variations = variations
        self.groupedProducts = groupedProducts
        self.menuOrder = menuOrder
        self.addOns = addOns
        self.isSampleItem = isSampleItem
        self.bundleStockStatus = bundleStockStatus
        self.bundleStockQuantity = bundleStockQuantity
        self.bundleMinSize = bundleMinSize
        self.bundleMaxSize = bundleMaxSize
        self.bundledItems = bundledItems
        self.compositeComponents = compositeComponents
        self.subscription = subscription
        self.minAllowedQuantity = minAllowedQuantity
        self.maxAllowedQuantity = maxAllowedQuantity
        self.groupOfQuantity = groupOfQuantity
        self.combineVariationQuantities = combineVariationQuantities
    }

    /// The public initializer for Product.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ProductDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let productID = try container.decode(Int64.self, forKey: .productID)
        let name = try container.decode(String.self, forKey: .name).strippedHTML
        let slug = try container.decode(String.self, forKey: .slug)
        // Even though a plain install of WooCommerce Core provides string values,
        // some plugins alter the field value from String to Int or Decimal.
        // We handle this by returning an empty string if we can't decode it
        let permalink: String = {
            do {
                return try container.decode(String.self, forKey: .permalink)
            } catch {
                DDLogError("⛔️ Error parsing `permalink` for Product ID \(productID): \(error)")
                return ""
            }
        }()
        let dateCreated = (try? container.decodeIfPresent(Date.self, forKey: .dateCreated)) ?? Date()
        let dateModified = (try? container.decodeIfPresent(Date.self, forKey: .dateModified)) ?? Date()
        let dateOnSaleStart = try container.decodeIfPresent(Date.self, forKey: .dateOnSaleStart)
        let dateOnSaleEnd = try container.decodeIfPresent(Date.self, forKey: .dateOnSaleEnd)

        let productTypeKey = try container.decode(String.self, forKey: .productTypeKey)
        let statusKey = try container.decode(String.self, forKey: .statusKey)
        let featured = try container.decode(Bool.self, forKey: .featured)
        let catalogVisibilityKey = try container.decode(String.self, forKey: .catalogVisibilityKey)

        // Calculated date: `dateModified` for a draft product and `dateCreated` otherwise.
        let date = statusKey == ProductStatus.draft.rawValue ? dateModified: dateCreated

        let fullDescription = try container.decodeIfPresent(String.self, forKey: .fullDescription)
        let shortDescription = try container.decodeIfPresent(String.self, forKey: .shortDescription)

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
        let totalSales = container.failsafeDecodeIfPresent(Int.self, forKey: .totalSales) ?? 0
        let virtual = try container.decode(Bool.self, forKey: .virtual)

        let downloadable = try container.decode(Bool.self, forKey: .downloadable)
        let downloads = try container.decode([ProductDownload].self, forKey: .downloads)
        let downloadLimit = try container.decode(Int64.self, forKey: .downloadLimit)
        let downloadExpiry = try container.decode(Int64.self, forKey: .downloadExpiry)

        let buttonText = try container.decode(String.self, forKey: .buttonText)
        let externalURL = try container.decodeIfPresent(String.self, forKey: .externalURL)
        let taxStatusKey = try container.decode(String.self, forKey: .taxStatusKey)
        let taxClass = try container.decodeIfPresent(String.self, forKey: .taxClass)

        // Even though the API docs claim `manageStock` is a bool, it's possible that `"parent"`
        // could be returned as well (typically with variations) — we need to account for this.
        // A "parent" value means that stock mgmt is turned on + managed at the parent product-level, therefore
        // we need to set this var as `true` in this situation.
        // See: https://github.com/woocommerce/woocommerce-ios/issues/884 for more deets
        let manageStock = container.failsafeDecodeIfPresent(targetType: Bool.self,
                                                            forKey: .manageStock,
                                                            alternativeTypes: [
                                                                .string(transform: { value in
                                                                    // A bool could not be parsed — check if "parent" is set, and if so, set manageStock to
                                                                    // `true`
                                                                    value.lowercased() == Values.manageStockParent ? true : false
                                                                })
        ]) ?? false

        // Even though WooCommerce Core returns Int or null values,
        // some plugins alter the field value from Int to Decimal or String.
        // We handle this as an optional Decimal value.
        let stockQuantity = container.failsafeDecodeIfPresent(decimalForKey: .stockQuantity)

        let stockStatusKey = try container.decode(String.self, forKey: .stockStatusKey)

        let backordersKey = try container.decode(String.self, forKey: .backordersKey)

        // Even though WooCommerce Core returns Bool values,
        // some plugins alter the field value from Bool to String.
        let backordersAllowed = container.failsafeDecodeIfPresent(targetType: Bool.self,
                                                                  forKey: .backordersAllowed,
                                                                  alternativeTypes: [ .string(transform: { NSString(string: $0).boolValue })]) ?? false

        let backordered = try container.decode(Bool.self, forKey: .backordered)

        let soldIndividually = try container.decodeIfPresent(Bool.self, forKey: .soldIndividually) ?? false

        // Even though a plain install of WooCommerce Core provides String values,
        // some plugins alter the field value from String to Int or Decimal.
        let weight = container.failsafeDecodeIfPresent(targetType: String.self,
                                                       forKey: .weight,
                                                       alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })])
        let dimensions = try container.decode(ProductDimensions.self, forKey: .dimensions)

        let shippingRequired = try container.decode(Bool.self, forKey: .shippingRequired)
        let shippingTaxable = try container.decode(Bool.self, forKey: .shippingTaxable)
        let shippingClass = try container.decodeIfPresent(String.self, forKey: .shippingClass)
        let shippingClassID = try container.decode(Int64.self, forKey: .shippingClassID)

        let reviewsAllowed = try container.decode(Bool.self, forKey: .reviewsAllowed)

        /// We have noticed this value coming as a number on some stores.
        /// As this was introduced quite a while ago it's cheaper to handle both types than letting the whole parsing fail.
        ///
        let averageRating = container.failsafeDecodeIfPresent(targetType: String.self,
                                                              forKey: .averageRating,
                                                              alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })]) ?? ""

        let ratingCount = try container.decode(Int.self, forKey: .ratingCount)

        let relatedIDs = try container.decode([Int64].self, forKey: .relatedIDs)
        let upsellIDs = try container.decode([Int64].self, forKey: .upsellIDs)
        let crossSellIDs = try container.decode([Int64].self, forKey: .crossSellIDs)
        let parentID = try container.decode(Int64.self, forKey: .parentID)

        let purchaseNote = try container.decodeIfPresent(String.self, forKey: .purchaseNote)
        let categories = try container.decode([ProductCategory].self, forKey: .categories)
        let tags = try container.decode([ProductTag].self, forKey: .tags)
        let images = try container.decode([ProductImage].self, forKey: .images)

        let attributes = try container.decode([ProductAttribute].self, forKey: .attributes)
        let defaultAttributes = try container.decode([ProductDefaultAttribute].self, forKey: .defaultAttributes)

        // Even though WooCommerce Core returns a list of variation IDs,
        // some plugins alter the field value to include the entire variation response and we need to extract the IDs.
        // If we still can't decode it, we return an empty variation list so the whole parsing doesn't fail.
        let variations: [Int64] = {
            do {
                if let variationIDs = try? container.decode([Int64].self, forKey: .variations) {
                    return variationIDs
                } else {
                    return try container.decode([IdentifiableObject].self, forKey: .variations).map { $0.id }
                }
            } catch {
                DDLogError("⛔️ Error parsing `variations` for Product ID \(productID): \(error)")
                return []
            }
        }()

        let groupedProducts = try container.decode([Int64].self, forKey: .groupedProducts)

        let menuOrder = try container.decode(Int.self, forKey: .menuOrder)

        // In some isolated cases, it appears to be some malformed meta-data that causes this line to throw hence the whole product decoding to throw.
        // Since add-ons are optional, `try?` will be used to prevent the whole decoding to stop.
        // https://github.com/woocommerce/woocommerce-ios/issues/4205
        let addOns = (try? container.decodeIfPresent(ProductAddOnEnvelope.self, forKey: .metadata)?.revolve()) ?? []

        let metaDataExtractor = try? container.decodeIfPresent(ProductMetadataExtractor.self, forKey: .metadata)
        let isSampleItem = (metaDataExtractor?.extractStringValue(forKey: MetadataKeys.headStartPost) == Values.headStartValue)

        // Product Bundle properties
        // Uses failsafe decoding because non-bundle product types can return unexpected value types.
        let bundleStockStatus = container.failsafeDecodeIfPresent(ProductStockStatus.self, forKey: .bundleStockStatus)
        // When the bundle stock quantity is not set for a product bundle, the API returns an empty string and the value will be `nil`.
        let bundleStockQuantity = container.failsafeDecodeIfPresent(Int64.self, forKey: .bundleStockQuantity)
        let bundleMinSize = container.failsafeDecodeIfPresent(decimalForKey: .bundleMinSize)
        let bundleMaxSize = container.failsafeDecodeIfPresent(decimalForKey: .bundleMaxSize)
        let bundledItems = try container.decodeIfPresent([ProductBundleItem].self, forKey: .bundledItems) ?? []

        // Composite Product properties
        let compositeComponents = try container.decodeIfPresent([ProductCompositeComponent].self, forKey: .compositeComponents) ?? []

        // Subscription properties
        let subscription = try? metaDataExtractor?.extractProductSubscription()

        // Min/Max Quantities properties
        let minAllowedQuantity = metaDataExtractor?.extractStringValue(forKey: MetadataKeys.minAllowedQuantity)
        let maxAllowedQuantity = metaDataExtractor?.extractStringValue(forKey: MetadataKeys.maxAllowedQuantity)
        let groupOfQuantity = metaDataExtractor?.extractStringValue(forKey: MetadataKeys.groupOfQuantity)
        let combineVariationQuantities: Bool? = {
            guard let allowCombination = metaDataExtractor?.extractStringValue(forKey: MetadataKeys.allowCombination) else {
                return nil
            }
            return (allowCombination as NSString).boolValue
        }()

        self.init(siteID: siteID,
                  productID: productID,
                  name: name,
                  slug: slug,
                  permalink: permalink,
                  date: date,
                  dateCreated: dateCreated,
                  dateModified: dateModified,
                  dateOnSaleStart: dateOnSaleStart,
                  dateOnSaleEnd: dateOnSaleEnd,
                  productTypeKey: productTypeKey,
                  statusKey: statusKey,
                  featured: featured,
                  catalogVisibilityKey: catalogVisibilityKey,
                  fullDescription: fullDescription,
                  shortDescription: shortDescription,
                  sku: sku,
                  price: price,
                  regularPrice: regularPrice,
                  salePrice: salePrice,
                  onSale: onSale,
                  purchasable: purchasable,
                  totalSales: totalSales,
                  virtual: virtual,
                  downloadable: downloadable,
                  downloads: downloads,
                  downloadLimit: downloadLimit,
                  downloadExpiry: downloadExpiry,
                  buttonText: buttonText,
                  externalURL: externalURL,
                  taxStatusKey: taxStatusKey,
                  taxClass: taxClass,
                  manageStock: manageStock,
                  stockQuantity: stockQuantity,
                  stockStatusKey: stockStatusKey,
                  backordersKey: backordersKey,
                  backordersAllowed: backordersAllowed,
                  backordered: backordered,
                  soldIndividually: soldIndividually,
                  weight: weight,
                  dimensions: dimensions,
                  shippingRequired: shippingRequired,
                  shippingTaxable: shippingTaxable,
                  shippingClass: shippingClass,
                  shippingClassID: shippingClassID,
                  productShippingClass: nil,
                  reviewsAllowed: reviewsAllowed,
                  averageRating: averageRating,
                  ratingCount: ratingCount,
                  relatedIDs: relatedIDs,
                  upsellIDs: upsellIDs,
                  crossSellIDs: crossSellIDs,
                  parentID: parentID,
                  purchaseNote: purchaseNote,
                  categories: categories,
                  tags: tags,
                  images: images,
                  attributes: attributes,
                  defaultAttributes: defaultAttributes,
                  variations: variations,
                  groupedProducts: groupedProducts,
                  menuOrder: menuOrder,
                  addOns: addOns,
                  isSampleItem: isSampleItem,
                  bundleStockStatus: bundleStockStatus,
                  bundleStockQuantity: bundleStockQuantity,
                  bundleMinSize: bundleMinSize,
                  bundleMaxSize: bundleMaxSize,
                  bundledItems: bundledItems,
                  compositeComponents: compositeComponents,
                  subscription: subscription,
                  minAllowedQuantity: minAllowedQuantity,
                  maxAllowedQuantity: maxAllowedQuantity,
                  groupOfQuantity: groupOfQuantity,
                  combineVariationQuantities: combineVariationQuantities)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(productID, forKey: .productID)

        try container.encode(images, forKey: .images)

        try container.encode(name, forKey: .name)
        try container.encode(fullDescription, forKey: .fullDescription)

        // Price Settings.
        try container.encode(regularPrice, forKey: .regularPrice)
        try container.encode(salePrice, forKey: .salePrice)

        // We need to send empty string if fields are null, because there is a bug on the API side
        // Issue: https://github.com/woocommerce/woocommerce/issues/25350
        if dateOnSaleStart == nil {
            try container.encode("", forKey: .dateOnSaleStart)
        }
        else {
            try container.encode(dateOnSaleStart, forKey: .dateOnSaleStart)
        }
        if dateOnSaleEnd == nil {
            try container.encode("", forKey: .dateOnSaleEnd)
        }
        else {
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
        try container.encode(soldIndividually, forKey: .soldIndividually)

        // API currently only accepts integer values for stock quantity
        if hasIntegerStockQuantity {
            try container.encode(stockQuantity, forKey: .stockQuantity)
        }

        try container.encode(backordersKey, forKey: .backordersKey)
        try container.encode(stockStatusKey, forKey: .stockStatusKey)
        try container.encode(virtual, forKey: .virtual)

        // Product type
        switch productType {
        case .custom:
            break
        default:
            try container.encode(productTypeKey, forKey: .productTypeKey)
        }

        // Categories
        try container.encode(categories, forKey: .categories)

        // Tags
        try container.encode(tags, forKey: .tags)

        // Short description.
        try container.encode(shortDescription, forKey: .shortDescription)

        // Grouped products.
        try container.encode(groupedProducts, forKey: .groupedProducts)

        // Product Settings
        try container.encode(statusKey, forKey: .statusKey)
        try container.encode(featured, forKey: .featured)
        try container.encode(catalogVisibilityKey, forKey: .catalogVisibilityKey)
        try container.encode(reviewsAllowed, forKey: .reviewsAllowed)
        try container.encode(slug, forKey: .slug)
        try container.encode(purchaseNote, forKey: .purchaseNote)
        try container.encode(menuOrder, forKey: .menuOrder)

        // External link for external/affiliate products.
        try container.encode(externalURL, forKey: .externalURL)
        try container.encode(buttonText, forKey: .buttonText)

        // Downloadable files settings for a downloadable products.
        try container.encode(downloadable, forKey: .downloadable)
        try container.encode(downloads, forKey: .downloads)
        try container.encode(downloadLimit, forKey: .downloadLimit)
        try container.encode(downloadExpiry, forKey: .downloadExpiry)

        // Linked Products (Upsells and Cross-sell Products)
        try container.encode(upsellIDs, forKey: .upsellIDs)
        try container.encode(crossSellIDs, forKey: .crossSellIDs)

        // Attributes
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


/// Defines all of the Product CodingKeys
///
private extension Product {

    enum CodingKeys: String, CodingKey {
        case productID  = "id"
        case name       = "name"
        case slug       = "slug"
        case permalink  = "permalink"

        case dateCreated  = "date_created_gmt"
        case dateModified = "date_modified_gmt"
        case dateOnSaleStart  = "date_on_sale_from_gmt"
        case dateOnSaleEnd = "date_on_sale_to_gmt"

        case productTypeKey         = "type"
        case statusKey              = "status"
        case featured               = "featured"
        case catalogVisibilityKey   = "catalog_visibility"

        case fullDescription        = "description"
        case shortDescription       = "short_description"

        case sku            = "sku"
        case price          = "price"
        case regularPrice   = "regular_price"
        case salePrice      = "sale_price"
        case onSale         = "on_sale"

        case purchasable    = "purchasable"
        case totalSales     = "total_sales"
        case virtual        = "virtual"

        case downloadable   = "downloadable"
        case downloads      = "downloads"
        case downloadLimit  = "download_limit"
        case downloadExpiry = "download_expiry"

        case buttonText     = "button_text"
        case externalURL    = "external_url"
        case taxStatusKey   = "tax_status"
        case taxClass       = "tax_class"

        case manageStock    = "manage_stock"
        case stockQuantity  = "stock_quantity"
        case stockStatusKey = "stock_status"

        case backordersKey      = "backorders"
        case backordersAllowed  = "backorders_allowed"
        case backordered        = "backordered"

        case soldIndividually   = "sold_individually"
        case weight             = "weight"
        case dimensions         = "dimensions"

        case shippingRequired   = "shipping_required"
        case shippingTaxable    = "shipping_taxable"
        case shippingClass      = "shipping_class"
        case shippingClassID    = "shipping_class_id"

        case reviewsAllowed = "reviews_allowed"
        case averageRating  = "average_rating"
        case ratingCount    = "rating_count"

        case relatedIDs     = "related_ids"
        case upsellIDs      = "upsell_ids"
        case crossSellIDs   = "cross_sell_ids"
        case parentID       = "parent_id"

        case purchaseNote   = "purchase_note"
        case categories     = "categories"
        case tags           = "tags"
        case images         = "images"

        case attributes         = "attributes"
        case defaultAttributes  = "default_attributes"
        case variations         = "variations"
        case groupedProducts    = "grouped_products"
        case menuOrder          = "menu_order"
        case metadata           = "meta_data"

        case bundleStockStatus              = "bundle_stock_status"
        case bundleStockQuantity            = "bundle_stock_quantity"
        case bundleMinSize                  = "bundle_min_size"
        case bundleMaxSize                  = "bundle_max_size"
        case bundledItems                   = "bundled_items"

        case compositeComponents    = "composite_components"
    }

    enum MetadataKeys {
        static let minAllowedQuantity = "minimum_allowed_quantity"
        static let maxAllowedQuantity = "maximum_allowed_quantity"
        static let groupOfQuantity    = "group_of_quantity"
        static let allowCombination   = "allow_combination"
        static let headStartPost      = "_headstart_post"
    }
}


// MARK: - Constants!
//
private extension Product {

    enum Values {
        static let manageStockParent = "parent"
        static let headStartValue = "_hs_extra"
    }
}


// MARK: - Decoding Errors
//
enum ProductDecodingError: Error {
    case missingSiteID
}

// MARK: - Hashable Conformance
//
extension Product: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(siteID)
        hasher.combine(productID)
    }
}
