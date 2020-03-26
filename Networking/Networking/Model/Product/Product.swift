import Foundation


/// Represents a Product Entity.
///
public struct Product: Codable {
    public let siteID: Int64
    public let productID: Int64
    public let name: String
    public let slug: String
    public let permalink: String

    public let dateCreated: Date        // gmt
    public let dateModified: Date?      // gmt
    public let dateOnSaleStart: Date?   // gmt
    public let dateOnSaleEnd: Date?     // gmt

    public let productTypeKey: String
    public let statusKey: String        // draft, pending, private, published
    public let featured: Bool
    public let catalogVisibilityKey: String // visible, catalog, search, hidden

    public let fullDescription: String?
    public let briefDescription: String?
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
    public let downloadLimit: Int       // defaults to -1
    public let downloadExpiry: Int      // defaults to -1

    public let externalURL: String?
    public let taxStatusKey: String     // taxable, shipping, none
    public let taxClass: String?

    public let manageStock: Bool
    public let stockQuantity: Int?      // API reports Int or null
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

    /// Computed Properties
    ///
    public var productStatus: ProductStatus {
        return ProductStatus(rawValue: statusKey)
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

    /// Product struct initializer.
    ///
    public init(siteID: Int64,
                productID: Int64,
                name: String,
                slug: String,
                permalink: String,
                dateCreated: Date,
                dateModified: Date?,
                dateOnSaleStart: Date?,
                dateOnSaleEnd: Date?,
                productTypeKey: String,
                statusKey: String,
                featured: Bool,
                catalogVisibilityKey: String,
                fullDescription: String?,
                briefDescription: String?,
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
                downloadLimit: Int,
                downloadExpiry: Int,
                externalURL: String?,
                taxStatusKey: String,
                taxClass: String?,
                manageStock: Bool,
                stockQuantity: Int?,
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
                menuOrder: Int) {
        self.siteID = siteID
        self.productID = productID
        self.name = name
        self.slug = slug
        self.permalink = permalink
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.dateOnSaleStart = dateOnSaleStart
        self.dateOnSaleEnd = dateOnSaleEnd
        self.productTypeKey = productTypeKey
        self.statusKey = statusKey
        self.featured = featured
        self.catalogVisibilityKey = catalogVisibilityKey
        self.fullDescription = fullDescription
        self.briefDescription = briefDescription
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
        let permalink = try container.decode(String.self, forKey: .permalink)

        let dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated) ?? Date()
        let dateModified = try container.decodeIfPresent(Date.self, forKey: .dateModified) ?? Date()
        let dateOnSaleStart = try container.decodeIfPresent(Date.self, forKey: .dateOnSaleStart)
        let dateOnSaleEnd = try container.decodeIfPresent(Date.self, forKey: .dateOnSaleEnd)

        let productTypeKey = try container.decode(String.self, forKey: .productTypeKey)
        let statusKey = try container.decode(String.self, forKey: .statusKey)
        let featured = try container.decode(Bool.self, forKey: .featured)
        let catalogVisibilityKey = try container.decode(String.self, forKey: .catalogVisibilityKey)

        let fullDescription = try container.decodeIfPresent(String.self, forKey: .fullDescription)
        let briefDescription = try container.decodeIfPresent(String.self, forKey: .briefDescription)
        let sku = try container.decodeIfPresent(String.self, forKey: .sku)

        // Even though a plain install of WooCommerce Core provides string values,
        // some plugins alter the field value from String to Int or Decimal.
        var price = ""
        if let parsedStringValue = container.failsafeDecodeIfPresent(stringForKey: .price) {
            price = parsedStringValue
        } else if let parsedDecimalValue = container.failsafeDecodeIfPresent(decimalForKey: .price) {
            price = NSDecimalNumber(decimal: parsedDecimalValue).stringValue
        }

        let regularPrice = try container.decodeIfPresent(String.self, forKey: .regularPrice)

        let onSale = try container.decode(Bool.self, forKey: .onSale)

        // Even though a plain install of WooCommerce Core provides string values,
        // some plugins alter the field value from String to Int or Decimal.
        var salePrice = ""
        if let parsedSalePriceString = container.failsafeDecodeIfPresent(stringForKey: .salePrice) {
            salePrice = (onSale && parsedSalePriceString.isEmpty) ? "0" : parsedSalePriceString
        } else if let parsedSalePriceDecimal = container.failsafeDecodeIfPresent(decimalForKey: .salePrice) {
            let stringPrice = NSDecimalNumber(decimal: parsedSalePriceDecimal).stringValue
            salePrice = onSale ? "0" : stringPrice
        }

        let purchasable = try container.decode(Bool.self, forKey: .purchasable)
        let totalSales = container.failsafeDecodeIfPresent(Int.self, forKey: .totalSales) ?? 0
        let virtual = try container.decode(Bool.self, forKey: .virtual)

        let downloadable = try container.decode(Bool.self, forKey: .downloadable)
        let downloads = try container.decode([ProductDownload].self, forKey: .downloads)
        let downloadLimit = try container.decode(Int.self, forKey: .downloadLimit)
        let downloadExpiry = try container.decode(Int.self, forKey: .downloadExpiry)

        let externalURL = try container.decodeIfPresent(String.self, forKey: .externalURL)
        let taxStatusKey = try container.decode(String.self, forKey: .taxStatusKey)
        let taxClass = try container.decodeIfPresent(String.self, forKey: .taxClass)

        // Even though the API docs claim `manageStock` is a bool, it's possible that `"parent"`
        // could be returned as well (typically with variations) — we need to account for this.
        // A "parent" value means that stock mgmt is turned on + managed at the parent product-level, therefore
        // we need to set this var as `true` in this situation.
        // See: https://github.com/woocommerce/woocommerce-ios/issues/884 for more deets
        var manageStock = false
        if let parsedBoolValue = container.failsafeDecodeIfPresent(booleanForKey: .manageStock) {
            manageStock = parsedBoolValue
        } else if let parsedStringValue = container.failsafeDecodeIfPresent(stringForKey: .manageStock) {
            // A bool could not be parsed — check if "parent" is set, and if so, set manageStock to `true`
            manageStock = parsedStringValue.lowercased() == Values.manageStockParent ? true : false
        }

        let stockQuantity = try container.decodeIfPresent(Int.self, forKey: .stockQuantity)
        let stockStatusKey = try container.decode(String.self, forKey: .stockStatusKey)

        let backordersKey = try container.decode(String.self, forKey: .backordersKey)
        let backordersAllowed = try container.decode(Bool.self, forKey: .backordersAllowed)
        let backordered = try container.decode(Bool.self, forKey: .backordered)

        let soldIndividually = try container.decode(Bool.self, forKey: .soldIndividually)
        let weight = try container.decodeIfPresent(String.self, forKey: .weight)
        let dimensions = try container.decode(ProductDimensions.self, forKey: .dimensions)

        let shippingRequired = try container.decode(Bool.self, forKey: .shippingRequired)
        let shippingTaxable = try container.decode(Bool.self, forKey: .shippingTaxable)
        let shippingClass = try container.decodeIfPresent(String.self, forKey: .shippingClass)
        let shippingClassID = try container.decode(Int64.self, forKey: .shippingClassID)

        let reviewsAllowed = try container.decode(Bool.self, forKey: .reviewsAllowed)
        let averageRating = try container.decode(String.self, forKey: .averageRating)
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
        let variations = try container.decode([Int64].self, forKey: .variations)
        let groupedProducts = try container.decode([Int64].self, forKey: .groupedProducts)

        let menuOrder = try container.decode(Int.self, forKey: .menuOrder)

        self.init(siteID: siteID,
                  productID: productID,
                  name: name,
                  slug: slug,
                  permalink: permalink,
                  dateCreated: dateCreated,
                  dateModified: dateModified,
                  dateOnSaleStart: dateOnSaleStart,
                  dateOnSaleEnd: dateOnSaleEnd,
                  productTypeKey: productTypeKey,
                  statusKey: statusKey,
                  featured: featured,
                  catalogVisibilityKey: catalogVisibilityKey,
                  fullDescription: fullDescription,
                  briefDescription: briefDescription,
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
                  menuOrder: menuOrder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

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
        try container.encode(stockQuantity, forKey: .stockQuantity)
        try container.encode(backordersKey, forKey: .backordersKey)
        try container.encode(stockStatusKey, forKey: .stockStatusKey)

        // Brief description (short description).
        try container.encode(briefDescription, forKey: .briefDescription)
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
        case briefDescription       = "short_description"

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
    }
}


// MARK: - Comparable Conformance
//
extension Product: Comparable {
    public static func == (lhs: Product, rhs: Product) -> Bool {
        return lhs.siteID == rhs.siteID &&
            lhs.productID == rhs.productID &&
            lhs.name == rhs.name &&
            lhs.slug == rhs.slug &&
            lhs.permalink == rhs.permalink &&
            lhs.dateCreated == rhs.dateCreated &&
            lhs.dateModified == rhs.dateModified &&
            lhs.dateOnSaleStart == rhs.dateOnSaleStart &&
            lhs.dateOnSaleEnd == rhs.dateOnSaleEnd &&
            lhs.productTypeKey == rhs.productTypeKey &&
            lhs.statusKey == rhs.statusKey &&
            lhs.featured == rhs.featured &&
            lhs.catalogVisibilityKey == rhs.catalogVisibilityKey &&
            lhs.fullDescription == rhs.fullDescription &&
            lhs.briefDescription == rhs.briefDescription &&
            lhs.sku == rhs.sku &&
            // lhs.price == rhs.price &&    // can't compare because object type unknown
            lhs.regularPrice == rhs.regularPrice &&
            // lhs.salePrice == rhs.salePrice && // can't compare because object type unknown
            lhs.onSale == rhs.onSale &&
            lhs.purchasable == rhs.purchasable &&
            lhs.totalSales == rhs.totalSales &&
            lhs.virtual == rhs.virtual &&
            lhs.downloadable == rhs.downloadable &&
            lhs.downloadLimit == rhs.downloadLimit &&
            lhs.downloadExpiry == rhs.downloadExpiry &&
            lhs.externalURL == rhs.externalURL &&
            lhs.taxStatusKey == rhs.taxStatusKey &&
            lhs.taxClass == rhs.taxClass &&
            lhs.manageStock == rhs.manageStock &&
            lhs.stockQuantity == rhs.stockQuantity &&
            lhs.stockStatusKey == rhs.stockStatusKey &&
            lhs.backordersKey == rhs.backordersKey &&
            lhs.backordersAllowed == rhs.backordersAllowed &&
            lhs.backordered == rhs.backordered &&
            lhs.soldIndividually == rhs.soldIndividually &&
            lhs.weight == rhs.weight &&
            lhs.dimensions == rhs.dimensions &&
            lhs.shippingRequired == rhs.shippingRequired &&
            lhs.shippingTaxable == rhs.shippingTaxable &&
            lhs.shippingClass == rhs.shippingClass &&
            lhs.shippingClassID == rhs.shippingClassID &&
            lhs.productShippingClass == rhs.productShippingClass &&
            lhs.reviewsAllowed == rhs.reviewsAllowed &&
            lhs.averageRating == rhs.averageRating &&
            lhs.ratingCount == rhs.ratingCount &&
            lhs.relatedIDs == rhs.relatedIDs &&
            lhs.upsellIDs == rhs.upsellIDs &&
            lhs.parentID == rhs.parentID &&
            lhs.purchaseNote == rhs.purchaseNote &&
            lhs.categories.count == rhs.categories.count &&
            lhs.categories.sorted() == rhs.categories.sorted() &&
            lhs.tags.count == rhs.tags.count &&
            lhs.tags.sorted() == rhs.tags.sorted() &&
            lhs.images.count == rhs.images.count &&
            lhs.images.sorted() == rhs.images.sorted() &&
            lhs.attributes.count == rhs.attributes.count &&
            lhs.attributes.sorted() == rhs.attributes.sorted() &&
            lhs.defaultAttributes.count == rhs.defaultAttributes.count &&
            lhs.defaultAttributes.sorted() == rhs.defaultAttributes.sorted() &&
            lhs.variations == rhs.variations &&
            lhs.groupedProducts == rhs.groupedProducts &&
            lhs.menuOrder == rhs.menuOrder
    }

    public static func < (lhs: Product, rhs: Product) -> Bool {
        /// Note: stockQuantity can be `null` in the API,
        /// which is why we are unable to sort by it here.
        ///
        return lhs.siteID < rhs.siteID ||
            (lhs.siteID == rhs.siteID && lhs.productID < rhs.productID) ||
            (lhs.siteID == rhs.siteID && lhs.productID == rhs.productID &&
                lhs.name < rhs.name) ||
            (lhs.siteID == rhs.siteID && lhs.productID == rhs.productID &&
                lhs.name == rhs.name && lhs.slug < rhs.slug) ||
            (lhs.siteID == rhs.siteID && lhs.productID == rhs.productID &&
                lhs.name == rhs.name && lhs.slug == rhs.slug &&
                lhs.dateCreated < rhs.dateCreated) ||
            (lhs.siteID == rhs.siteID && lhs.productID == rhs.productID &&
                lhs.name == rhs.name && lhs.slug == rhs.slug &&
                lhs.dateCreated == rhs.dateCreated &&
                lhs.productTypeKey < rhs.productTypeKey) ||
            (lhs.siteID == rhs.siteID && lhs.productID == rhs.productID &&
                lhs.name == rhs.name && lhs.slug == rhs.slug &&
                lhs.dateCreated == rhs.dateCreated &&
                lhs.productTypeKey == rhs.productTypeKey &&
                lhs.statusKey < rhs.statusKey) ||
            (lhs.siteID == rhs.siteID && lhs.productID == rhs.productID &&
                lhs.name == rhs.name && lhs.slug == rhs.slug &&
                lhs.dateCreated == rhs.dateCreated &&
                lhs.productTypeKey == rhs.productTypeKey &&
                lhs.statusKey == rhs.statusKey &&
                lhs.stockStatusKey < rhs.stockStatusKey) ||
            (lhs.siteID == rhs.siteID && lhs.productID == rhs.productID &&
                lhs.name == rhs.name && lhs.slug == rhs.slug &&
                lhs.dateCreated == rhs.dateCreated &&
                lhs.productTypeKey == rhs.productTypeKey &&
                lhs.statusKey == rhs.statusKey &&
                lhs.stockStatusKey == rhs.stockStatusKey &&
                lhs.averageRating < rhs.averageRating) ||
            (lhs.siteID == rhs.siteID && lhs.productID == rhs.productID &&
                lhs.name == rhs.name && lhs.slug == rhs.slug &&
                lhs.dateCreated == rhs.dateCreated &&
                lhs.productTypeKey == rhs.productTypeKey &&
                lhs.statusKey == rhs.statusKey &&
                lhs.stockStatusKey == rhs.stockStatusKey &&
                lhs.averageRating == rhs.averageRating &&
                lhs.ratingCount < rhs.ratingCount)
    }
}


// MARK: - Constants!
//
private extension Product {

    enum Values {
        static let manageStockParent = "parent"
    }
}


// MARK: - Decoding Errors
//
enum ProductDecodingError: Error {
    case missingSiteID
}
