import Foundation

/// Represents a Product Variation Entity.
///
public struct ProductVariation: Decodable, GeneratedCopiable {
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
    public let stockQuantity: Int64?    // API reports Int or null
    public let stockStatus: ProductStockStatus

    public let backordersKey: String    // no, notify, yes
    public let backordersAllowed: Bool
    public let backordered: Bool

    public let weight: String?
    public let dimensions: ProductDimensions

    public let shippingClass: String?
    public let shippingClassID: Int64

    public let menuOrder: Int64

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
                stockQuantity: Int64?,
                stockStatus: ProductStockStatus,
                backordersKey: String,
                backordersAllowed: Bool,
                backordered: Bool,
                weight: String?,
                dimensions: ProductDimensions,
                shippingClass: String?,
                shippingClassID: Int64,
                menuOrder: Int64) {
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
        let permalink = try container.decode(String.self, forKey: .permalink)
        let dateCreated = try container.decode(Date.self, forKey: .dateCreated)
        let dateModified = try container.decodeIfPresent(Date.self, forKey: .dateModified)
        let dateOnSaleStart = try container.decodeIfPresent(Date.self, forKey: .dateOnSaleStart)
        let dateOnSaleEnd = try container.decodeIfPresent(Date.self, forKey: .dateOnSaleEnd)
        let statusKey = try container.decode(String.self, forKey: .statusKey)
        let status = ProductStatus(rawValue: statusKey)
        let description = try container.decodeIfPresent(String.self, forKey: .description)
        let sku = try container.decodeIfPresent(String.self, forKey: .sku)
        let price = try container.decode(String.self, forKey: .price)
        let regularPrice = try container.decodeIfPresent(String.self, forKey: .regularPrice)
        let salePrice = try container.decodeIfPresent(String.self, forKey: .salePrice)
        let onSale = try container.decode(Bool.self, forKey: .onSale)
        let purchasable = try container.decode(Bool.self, forKey: .purchasable)
        let virtual = try container.decode(Bool.self, forKey: .virtual)
        let downloadable = try container.decode(Bool.self, forKey: .downloadable)
        let downloads = try container.decode([ProductDownload].self, forKey: .downloads)
        let downloadLimit = try container.decode(Int64.self, forKey: .downloadLimit)
        let downloadExpiry = try container.decode(Int64.self, forKey: .downloadExpiry)
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

        let stockQuantity = try container.decodeIfPresent(Int64.self, forKey: .stockQuantity)
        let stockStatusKey = try container.decode(String.self, forKey: .stockStatusKey)
        let stockStatus = ProductStockStatus(rawValue: stockStatusKey)
        let backordersKey = try container.decode(String.self, forKey: .backordersKey)
        let backordersAllowed = try container.decode(Bool.self, forKey: .backordersAllowed)
        let backordered = try container.decode(Bool.self, forKey: .backordered)
        let weight = try container.decodeIfPresent(String.self, forKey: .weight)
        let dimensions = try container.decode(ProductDimensions.self, forKey: .dimensions)
        let shippingClass = try container.decodeIfPresent(String.self, forKey: .shippingClass)
        let shippingClassID = try container.decode(Int64.self, forKey: .shippingClassID)
        let menuOrder = try container.decode(Int64.self, forKey: .menuOrder)

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
                  menuOrder: menuOrder)
    }
}

/// Defines all of the ProductVariation CodingKeys
///
private extension ProductVariation {

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
    }
}


// MARK: - Equatable Conformance
//
extension ProductVariation: Equatable {
    public static func == (lhs: ProductVariation, rhs: ProductVariation) -> Bool {
        return lhs.siteID == rhs.siteID &&
            lhs.productID == rhs.productID &&
            lhs.productVariationID == rhs.productVariationID &&
            lhs.attributes == rhs.attributes &&
            lhs.image == rhs.image &&
            lhs.permalink == rhs.permalink &&
            lhs.dateCreated == rhs.dateCreated &&
            lhs.dateModified == rhs.dateModified &&
            lhs.dateOnSaleStart == rhs.dateOnSaleStart &&
            lhs.dateOnSaleEnd == rhs.dateOnSaleEnd &&
            lhs.status == rhs.status &&
            lhs.description == rhs.description &&
            lhs.sku == rhs.sku &&
            lhs.price == rhs.price &&
            lhs.regularPrice == rhs.regularPrice &&
            lhs.salePrice == rhs.salePrice &&
            lhs.onSale == rhs.onSale &&
            lhs.purchasable == rhs.purchasable &&
            lhs.virtual == rhs.virtual &&
            lhs.downloadable == rhs.downloadable &&
            lhs.downloads == rhs.downloads &&
            lhs.downloadLimit == rhs.downloadLimit &&
            lhs.downloadExpiry == rhs.downloadExpiry &&
            lhs.taxStatusKey == rhs.taxStatusKey &&
            lhs.taxClass == rhs.taxClass &&
            lhs.manageStock == rhs.manageStock &&
            lhs.stockQuantity == rhs.stockQuantity &&
            lhs.stockStatus == rhs.stockStatus &&
            lhs.backordersKey == rhs.backordersKey &&
            lhs.backordersAllowed == rhs.backordersAllowed &&
            lhs.backordered == rhs.backordered &&
            lhs.weight == rhs.weight &&
            lhs.dimensions == rhs.dimensions &&
            lhs.shippingClass == rhs.shippingClass &&
            lhs.shippingClassID == rhs.shippingClassID &&
            lhs.menuOrder == rhs.menuOrder
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
