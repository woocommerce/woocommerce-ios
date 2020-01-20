// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

/// Represents a ProductVariation entity.
///
public class ProductVariation: Decodable {
    // Entities.
    public let backordered: Bool
    public let backordersAllowed: Bool
    public let backordersKey: String
    public let dateCreated: Date
    public let dateModified: Date?
    public let dateOnSaleEnd: Date?
    public let dateOnSaleStart: Date?
    public let downloadable: Bool
    public let downloadExpiry: Int64
    public let downloadLimit: Int64
    public let fullDescription: String?
    public let manageStock: Bool
    public let menuOrder: Int64
    public let onSale: Bool
    public let permalink: String
    public let price: String
    public let productID: Int64
    public let productVariationID: Int64
    public let purchasable: Bool
    public let regularPrice: String?
    public let salePrice: String?
    public let shippingClass: String?
    public let shippingClassID: Int64
    public let siteID: Int64
    public let sku: String?
    public let statusKey: String
    public let stockQuantity: Int64
    public let stockStatusKey: String
    public let taxClass: String?
    public let taxStatusKey: String
    public let virtual: Bool
    public let weight: String?
    // Relationships.
    public let attributes: [Attribute]
    public let dimensions: ProductDimensions?
    public let downloads: [ProductDownload]
    public let image: ProductImage?
    public let product: Product?

    /// ProductVariation initializer.
    ///
    public init(backordered: Bool,
                backordersAllowed: Bool,
                backordersKey: String,
                dateCreated: Date,
                dateModified: Date?,
                dateOnSaleEnd: Date?,
                dateOnSaleStart: Date?,
                downloadable: Bool,
                downloadExpiry: Int64,
                downloadLimit: Int64,
                fullDescription: String?,
                manageStock: Bool,
                menuOrder: Int64,
                onSale: Bool,
                permalink: String,
                price: String,
                productID: Int64,
                productVariationID: Int64?,
                purchasable: Bool,
                regularPrice: String?,
                salePrice: String?,
                shippingClass: String?,
                shippingClassID: Int64?,
                siteID: Int64,
                sku: String?,
                statusKey: String,
                stockQuantity: Int64?,
                stockStatusKey: String,
                taxClass: String?,
                taxStatusKey: String,
                virtual: Bool,
                weight: String?,
                // Relationships.
                attributes: [Attribute],
                dimensions: ProductDimensions?,
                downloads: [ProductDownload],
                image: ProductImage?,
                product: Product?)
        // Entities.
        self.backordered = backordered
        self.backordersAllowed = backordersAllowed
        self.backordersKey = backordersKey
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.dateOnSaleEnd = dateOnSaleEnd
        self.dateOnSaleStart = dateOnSaleStart
        self.downloadable = downloadable
        self.downloadExpiry = downloadExpiry
        self.downloadLimit = downloadLimit
        self.fullDescription = fullDescription
        self.manageStock = manageStock
        self.menuOrder = menuOrder
        self.onSale = onSale
        self.permalink = permalink
        self.price = price
        self.productID = productID
        self.productVariationID = productVariationID
        self.purchasable = purchasable
        self.regularPrice = regularPrice
        self.salePrice = salePrice
        self.shippingClass = shippingClass
        self.shippingClassID = shippingClassID
        self.siteID = siteID
        self.sku = sku
        self.statusKey = statusKey
        self.stockQuantity = stockQuantity
        self.stockStatusKey = stockStatusKey
        self.taxClass = taxClass
        self.taxStatusKey = taxStatusKey
        self.virtual = virtual
        self.weight = weight
        // Relationships.
        self.attributes = attributes
        self.dimensions = dimensions
        self.downloads = downloads
        self.image = image
        self.product = product
    }


    /// Public initializer for ProductVariation.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Entities.
        let backordered = try container.decode(Bool.self, forKey: .backordered)
        let backordersAllowed = try container.decode(Bool.self, forKey: .backordersAllowed)
        let backordersKey = try container.decode(String.self, forKey: .backordersKey)
        let dateCreated = try container.decode(Date.self, forKey: .dateCreated)
        let dateModified = try container.decodeIfPresent(Date.self, forKey: .dateModified)
        let dateOnSaleEnd = try container.decodeIfPresent(Date.self, forKey: .dateOnSaleEnd)
        let dateOnSaleStart = try container.decodeIfPresent(Date.self, forKey: .dateOnSaleStart)
        let downloadable = try container.decode(Bool.self, forKey: .downloadable)
        let downloadExpiry = try container.decode(Int64.self, forKey: .downloadExpiry)
        let downloadLimit = try container.decode(Int64.self, forKey: .downloadLimit)
        let fullDescription = try container.decodeIfPresent(String.self, forKey: .fullDescription)
        let manageStock = try container.decode(Bool.self, forKey: .manageStock)
        let menuOrder = try container.decode(Int64.self, forKey: .menuOrder)
        let onSale = try container.decode(Bool.self, forKey: .onSale)
        let permalink = try container.decode(String.self, forKey: .permalink)
        let price = try container.decode(String.self, forKey: .price)
        let productID = try container.decode(Int64.self, forKey: .productID)
        let productVariationID = try container.decodeIfPresent(Int64.self, forKey: .productVariationID)
        let purchasable = try container.decode(Bool.self, forKey: .purchasable)
        let regularPrice = try container.decodeIfPresent(String.self, forKey: .regularPrice)
        let salePrice = try container.decodeIfPresent(String.self, forKey: .salePrice)
        let shippingClass = try container.decodeIfPresent(String.self, forKey: .shippingClass)
        let shippingClassID = try container.decodeIfPresent(Int64.self, forKey: .shippingClassID)
        let siteID = try container.decode(Int64.self, forKey: .siteID)
        let sku = try container.decodeIfPresent(String.self, forKey: .sku)
        let statusKey = try container.decode(String.self, forKey: .statusKey)
        let stockQuantity = try container.decodeIfPresent(Int64.self, forKey: .stockQuantity)
        let stockStatusKey = try container.decode(String.self, forKey: .stockStatusKey)
        let taxClass = try container.decodeIfPresent(String.self, forKey: .taxClass)
        let taxStatusKey = try container.decode(String.self, forKey: .taxStatusKey)
        let virtual = try container.decode(Bool.self, forKey: .virtual)
        let weight = try container.decodeIfPresent(String.self, forKey: .weight)

        // Relationships.
        let attributes = try container.decode([Attribute].self, forKey: .attributes)
        let dimensions = try container.decodeIfPresent(ProductDimensions.self, forKey: .dimensions)
        let downloads = try container.decodeIfPresent([ProductDownload].self, forKey: .downloads) ?? []
        let image = try container.decodeIfPresent(ProductImage.self, forKey: .image)
        let product = try container.decodeIfPresent(Product.self, forKey: .product)

        self.init(backordered: backordered,
                  backordersAllowed: backordersAllowed,
                  backordersKey: backordersKey,
                  dateCreated: dateCreated,
                  dateModified: dateModified,
                  dateOnSaleEnd: dateOnSaleEnd,
                  dateOnSaleStart: dateOnSaleStart,
                  downloadable: downloadable,
                  downloadExpiry: downloadExpiry,
                  downloadLimit: downloadLimit,
                  fullDescription: fullDescription,
                  manageStock: manageStock,
                  menuOrder: menuOrder,
                  onSale: onSale,
                  permalink: permalink,
                  price: price,
                  productID: productID,
                  productVariationID: productVariationID,
                  purchasable: purchasable,
                  regularPrice: regularPrice,
                  salePrice: salePrice,
                  shippingClass: shippingClass,
                  shippingClassID: shippingClassID,
                  siteID: siteID,
                  sku: sku,
                  statusKey: statusKey,
                  stockQuantity: stockQuantity,
                  stockStatusKey: stockStatusKey,
                  taxClass: taxClass,
                  taxStatusKey: taxStatusKey,
                  virtual: virtual,
                  weight: weight,
                  // Relationships.
                  attributes: attributes,
                  dimensions: dimensions,
                  downloads: downloads,
                  image: image,
                  product: product)
    }
}


/// Defines all of the ProductVariation CodingKeys
///
private extension ProductVariation {
    enum CodingKeys: String, CodingKey {
        case backordered
        case backordersAllowed
        case backordersKey
        case dateCreated
        case dateModified
        case dateOnSaleEnd
        case dateOnSaleStart
        case downloadable
        case downloadExpiry
        case downloadLimit
        case fullDescription
        case manageStock
        case menuOrder
        case onSale
        case permalink
        case price
        case productID
        case productVariationID
        case purchasable
        case regularPrice
        case salePrice
        case shippingClass
        case shippingClassID
        case siteID
        case sku
        case statusKey
        case stockQuantity
        case stockStatusKey
        case taxClass
        case taxStatusKey
        case virtual
        case weight
    }
}


// MARK: - Equatable Conformance
//
extension ProductVariation: Equatable {
    public static func == (lhs: ProductVariation, rhs: ProductVariation) -> Bool {
        return lhs.backordered == rhs.backordered
            lhs.backordersAllowed == rhs.backordersAllowed
            lhs.backordersKey == rhs.backordersKey
            lhs.dateCreated == rhs.dateCreated
            lhs.dateModified == rhs.dateModified
            lhs.dateOnSaleEnd == rhs.dateOnSaleEnd
            lhs.dateOnSaleStart == rhs.dateOnSaleStart
            lhs.downloadable == rhs.downloadable
            lhs.downloadExpiry == rhs.downloadExpiry
            lhs.downloadLimit == rhs.downloadLimit
            lhs.fullDescription == rhs.fullDescription
            lhs.manageStock == rhs.manageStock
            lhs.menuOrder == rhs.menuOrder
            lhs.onSale == rhs.onSale
            lhs.permalink == rhs.permalink
            lhs.price == rhs.price
            lhs.productID == rhs.productID
            lhs.productVariationID == rhs.productVariationID
            lhs.purchasable == rhs.purchasable
            lhs.regularPrice == rhs.regularPrice
            lhs.salePrice == rhs.salePrice
            lhs.shippingClass == rhs.shippingClass
            lhs.shippingClassID == rhs.shippingClassID
            lhs.siteID == rhs.siteID
            lhs.sku == rhs.sku
            lhs.statusKey == rhs.statusKey
            lhs.stockQuantity == rhs.stockQuantity
            lhs.stockStatusKey == rhs.stockStatusKey
            lhs.taxClass == rhs.taxClass
            lhs.taxStatusKey == rhs.taxStatusKey
            lhs.virtual == rhs.virtual
            lhs.weight == rhs.weight
            // Relationships.
            lhs.attributes == rhs.attributes
            lhs.dimensions == rhs.dimensions
            lhs.downloads == rhs.downloads
            lhs.image == rhs.image
            lhs.product == rhs.product
    }
}
