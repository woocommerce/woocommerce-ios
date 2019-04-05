import Foundation


/// Represents a product variation Entity.
///
public struct ProductVariation: Decodable {
    public let siteID: Int
    public let variationID: Int
    public let productID: Int
    public let permalink: String

    public let dateCreated: Date        // gmt
    public let dateModified: Date?      // gmt
    public let dateOnSaleFrom: Date?    // gmt
    public let dateOnSaleTo: Date?      // gmt

    public let statusKey: String        // draft, pending, private, published
    public let fullDescription: String?
    public let sku: String?

    public let price: String
    public let regularPrice: String?
    public let salePrice: String?
    public let onSale: Bool

    public let purchasable: Bool
    public let virtual: Bool

    public let downloadable: Bool
    public let downloadLimit: Int       // defaults to -1
    public let downloadExpiry: Int      // defaults to -1

    public let taxStatusKey: String     // taxable, shipping, none
    public let taxClass: String?

    public let manageStock: Bool
    public let stockQuantity: Int?      // API reports Int or null
    public let stockStatusKey: String   // instock, outofstock, backorder

    public let backordersKey: String    // no, notify, yes
    public let backordersAllowed: Bool
    public let backordered: Bool

    public let weight: String?
    public let dimensions: ProductDimensions

    public let shippingClass: String?
    public let shippingClassID: Int

    public let image: ProductImage
    public let attributes: [ProductVariationAttribute]

    public let menuOrder: Int


    /// ProductVariation struct initializer.
    ///
    public init(siteID: Int,
                variationID: Int,
                productID: Int,
                permalink: String,
                dateCreated: Date,
                dateModified: Date?,
                dateOnSaleFrom: Date?,
                dateOnSaleTo: Date?,
                statusKey: String,
                fullDescription: String?,
                sku: String?,
                price: String,
                regularPrice: String?,
                salePrice: String?,
                onSale: Bool,
                purchasable: Bool,
                virtual: Bool,
                downloadable: Bool,
                downloadLimit: Int,
                downloadExpiry: Int,
                taxStatusKey: String,
                taxClass: String?,
                manageStock: Bool,
                stockQuantity: Int?,
                stockStatusKey: String,
                backordersKey: String,
                backordersAllowed: Bool,
                backordered: Bool,
                weight: String?,
                dimensions: ProductDimensions,
                shippingClass: String?,
                shippingClassID: Int,
                image: ProductImage,
                attributes: [ProductVariationAttribute],
                menuOrder: Int) {

        self.siteID = siteID
        self.variationID = variationID
        self.productID = productID
        self.permalink = permalink
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.dateOnSaleFrom = dateOnSaleFrom
        self.dateOnSaleTo = dateOnSaleTo
        self.statusKey = statusKey
        self.fullDescription = fullDescription
        self.sku = sku
        self.price = price
        self.regularPrice = regularPrice
        self.salePrice = salePrice
        self.onSale = onSale
        self.purchasable = purchasable
        self.virtual = virtual
        self.downloadable = downloadable
        self.downloadLimit = downloadLimit
        self.downloadExpiry = downloadExpiry
        self.taxStatusKey = taxStatusKey
        self.taxClass = taxClass
        self.manageStock = manageStock
        self.stockQuantity = stockQuantity
        self.stockStatusKey = stockStatusKey
        self.backordersKey = backordersKey
        self.backordersAllowed = backordersAllowed
        self.backordered = backordered
        self.weight = weight
        self.dimensions = dimensions
        self.shippingClass = shippingClass
        self.shippingClassID = shippingClassID
        self.image = image
        self.attributes = attributes
        self.menuOrder = menuOrder
    }

    /// The public initializer for ProductVariation.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int else {
            throw ProductVariationDecodingError.missingSiteID
        }
        guard let productID = decoder.userInfo[.productID] as? Int else {
            throw ProductVariationDecodingError.missingProductID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let variationID = try container.decode(Int.self, forKey: .variationID)
        let permalink = try container.decode(String.self, forKey: .permalink)

        let dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated) ?? Date()
        let dateModified = try container.decodeIfPresent(Date.self, forKey: .dateModified)
        let dateOnSaleFrom = try container.decodeIfPresent(Date.self, forKey: .dateOnSaleFrom)
        let dateOnSaleTo = try container.decodeIfPresent(Date.self, forKey: .dateOnSaleTo)

        let statusKey = try container.decode(String.self, forKey: .statusKey)
        let fullDescription = try container.decodeIfPresent(String.self, forKey: .fullDescription)
        let sku = try container.decodeIfPresent(String.self, forKey: .sku)

        let price = try container.decode(String.self, forKey: .price)
        let regularPrice = try container.decodeIfPresent(String.self, forKey: .regularPrice)
        let salePrice = try container.decodeIfPresent(String.self, forKey: .salePrice)
        let onSale = try container.decode(Bool.self, forKey: .onSale)

        let purchasable = try container.decode(Bool.self, forKey: .purchasable)
        let virtual = try container.decode(Bool.self, forKey: .virtual)

        let downloadable = try container.decode(Bool.self, forKey: .downloadable)
        let downloadLimit = try container.decode(Int.self, forKey: .downloadLimit)
        let downloadExpiry = try container.decode(Int.self, forKey: .downloadExpiry)

        let taxStatusKey = try container.decode(String.self, forKey: .taxStatusKey)
        let taxClass = try container.decodeIfPresent(String.self, forKey: .taxClass)

        let manageStock = try container.decode(Bool.self, forKey: .manageStock)
        let stockQuantity = try container.decodeIfPresent(Int.self, forKey: .stockQuantity)
        let stockStatusKey = try container.decode(String.self, forKey: .stockStatusKey)

        let backordersKey = try container.decode(String.self, forKey: .backordersKey)
        let backordersAllowed = try container.decode(Bool.self, forKey: .backordersAllowed)
        let backordered = try container.decode(Bool.self, forKey: .backordered)

        let weight = try container.decodeIfPresent(String.self, forKey: .weight)
        let dimensions = try container.decode(ProductDimensions.self, forKey: .dimensions)

        let shippingClass = try container.decodeIfPresent(String.self, forKey: .shippingClass)
        let shippingClassID = try container.decode(Int.self, forKey: .shippingClassID)

        let image = try container.decode(ProductImage.self, forKey: .image)

        let attributes = try container.decode([ProductVariationAttribute].self, forKey: .attributes)
        let menuOrder = try container.decode(Int.self, forKey: .menuOrder)
        

        self.init(siteID: siteID,
                  variationID: variationID,
                  productID: productID,
                  permalink: permalink,
                  dateCreated: dateCreated,
                  dateModified: dateModified,
                  dateOnSaleFrom: dateOnSaleFrom,
                  dateOnSaleTo: dateOnSaleTo,
                  statusKey: statusKey,
                  fullDescription: fullDescription,
                  sku: sku,
                  price: price,
                  regularPrice: regularPrice,
                  salePrice: salePrice,
                  onSale: onSale,
                  purchasable: purchasable,
                  virtual: virtual,
                  downloadable: downloadable,
                  downloadLimit: downloadLimit,
                  downloadExpiry: downloadExpiry,
                  taxStatusKey: taxStatusKey,
                  taxClass: taxClass,
                  manageStock: manageStock,
                  stockQuantity: stockQuantity,
                  stockStatusKey: stockStatusKey,
                  backordersKey: backordersKey,
                  backordersAllowed: backordersAllowed,
                  backordered: backordered,
                  weight: weight,
                  dimensions: dimensions,
                  shippingClass: shippingClass,
                  shippingClassID: shippingClassID,
                  image: image,
                  attributes: attributes,
                  menuOrder: menuOrder)
    }
}


// MARK: -  Defines all of the Product CodingKeys
//
private extension ProductVariation {

    enum CodingKeys: String, CodingKey {
        case variationID        = "id"
        case permalink          = "permalink"

        case dateCreated        = "date_created_gmt"
        case dateModified       = "date_modified_gmt"
        case dateOnSaleFrom     = "date_on_sale_from_gmt"
        case dateOnSaleTo       = "date_on_sale_to_gmt"

        case statusKey          = "status"
        case fullDescription    = "description"
        case sku                = "sku"

        case price              = "price"
        case regularPrice       = "regular_price"
        case salePrice          = "sale_price"
        case onSale             = "on_sale"

        case purchasable        = "purchasable"
        case virtual            = "virtual"

        case downloadable       = "downloadable"
        case downloadLimit      = "download_limit"
        case downloadExpiry     = "download_expiry"

        case taxStatusKey       = "tax_status"
        case taxClass           = "tax_class"

        case manageStock        = "manage_stock"
        case stockQuantity      = "stock_quantity"
        case stockStatusKey     = "stock_status"

        case backordersKey      = "backorders"
        case backordersAllowed  = "backorders_allowed"
        case backordered        = "backordered"

        case weight             = "weight"
        case dimensions         = "dimensions"

        case shippingClass      = "shipping_class"
        case shippingClassID    = "shipping_class_id"

        case image              = "image"
        case attributes         = "attributes"
        case menuOrder          = "menu_order"
    }
}


// MARK: - Comparable Conformance
//
extension ProductVariation: Comparable {

    public static func == (lhs: ProductVariation, rhs: ProductVariation) -> Bool {
        return lhs.siteID == rhs.siteID &&
            lhs.variationID == rhs.variationID &&
            lhs.productID == rhs.productID &&
            lhs.permalink == rhs.permalink &&
            lhs.dateCreated == rhs.dateCreated &&
            lhs.dateModified == rhs.dateModified &&
            lhs.dateOnSaleFrom == rhs.dateOnSaleFrom &&
            lhs.dateOnSaleTo == rhs.dateOnSaleTo &&
            lhs.statusKey == rhs.statusKey &&
            lhs.fullDescription == rhs.fullDescription &&
            lhs.sku == rhs.sku &&
            lhs.price == rhs.price &&
            lhs.regularPrice == rhs.regularPrice &&
            lhs.salePrice == rhs.salePrice &&
            lhs.onSale == rhs.onSale &&
            lhs.purchasable == rhs.purchasable &&
            lhs.virtual == rhs.virtual &&
            lhs.downloadable == rhs.downloadable &&
            lhs.downloadLimit == rhs.downloadLimit &&
            lhs.downloadExpiry == rhs.downloadExpiry &&
            lhs.taxStatusKey == rhs.taxStatusKey &&
            lhs.taxClass == rhs.taxClass &&
            lhs.manageStock == rhs.manageStock &&
            lhs.stockQuantity == rhs.stockQuantity &&
            lhs.stockStatusKey == rhs.stockStatusKey &&
            lhs.backordersKey == rhs.backordersKey &&
            lhs.backordersAllowed == rhs.backordersAllowed &&
            lhs.backordered == rhs.backordered &&
            lhs.weight == rhs.weight &&
            lhs.dimensions == rhs.dimensions &&
            lhs.shippingClass == rhs.shippingClass &&
            lhs.shippingClassID == rhs.shippingClassID &&
            lhs.image == rhs.image &&
            lhs.attributes.count == rhs.attributes.count &&
            lhs.attributes.sorted() == rhs.attributes.sorted() &&
            lhs.menuOrder == rhs.menuOrder
    }

    public static func < (lhs: ProductVariation, rhs: ProductVariation) -> Bool {
        return lhs.siteID < rhs.siteID ||
            (lhs.siteID == rhs.siteID && lhs.productID < rhs.productID) ||
            (lhs.siteID == rhs.siteID && lhs.productID == rhs.productID && lhs.variationID < rhs.variationID) ||
            (lhs.siteID == rhs.siteID && lhs.productID == rhs.productID && lhs.variationID == rhs.variationID && lhs.menuOrder < rhs.menuOrder)
    }
}


// MARK: - Decoding Errors
//
enum ProductVariationDecodingError: Error {
    case missingSiteID
    case missingProductID
}
