// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

/// Represents a Product entity.
///
public class Product: Decodable {
    // Entities.
    public let averageRating: String
    public let backordered: Bool
    public let backordersAllowed: Bool
    public let backordersKey: String
    public let briefDescription: String?
    public let catalogVisibilityKey: String
    public let crossSellIDs: [Int64]?
    public let dateCreated: Date
    public let dateModified: Date?
    public let downloadable: Bool
    public let downloadExpiry: Int64
    public let downloadLimit: Int64
    public let externalURL: String?
    public let featured: Bool
    public let fullDescription: String?
    public let groupedProducts: [Int64]
    public let manageStock: Bool
    public let menuOrder: Int64
    public let name: String
    public let onSale: Bool
    public let parentID: Int64
    public let permalink: String
    public let price: String
    public let productID: Int64
    public let productTypeKey: String
    public let purchasable: Bool
    public let purchaseNote: String?
    public let ratingCount: Int64
    public let regularPrice: String?
    public let relatedIDs: [Int64]?
    public let reviewsAllowed: Bool
    public let salePrice: String?
    public let shippingClass: String?
    public let shippingClassID: Int64
    public let shippingRequired: Bool
    public let shippingTaxable: Bool
    public let siteID: Int64
    public let sku: String?
    public let slug: String
    public let soldIndividually: Bool
    public let statusKey: String
    public let stockQuantity: String?
    public let stockStatusKey: String
    public let taxClass: String?
    public let taxStatusKey: String
    public let totalSales: Int64
    public let upsellIDs: [Int64]?
    public let variations: [Int64]?
    public let virtual: Bool
    public let weight: String?
    // Relationships.
    public let attributes: [ProductAttribute]
    public let categories: [ProductCategory]
    public let defaultAttributes: [ProductDefaultAttribute]
    public let dimensions: ProductDimensions?
    public let downloads: [ProductDownload]
    public let images: [ProductImage]
    public let productVariations: [ProductVariation]
    public let searchResults: [ProductSearchResults]
    public let tags: [ProductTag]

    /// Product initializer.
    ///
    public init(averageRating: String,
                backordered: Bool,
                backordersAllowed: Bool,
                backordersKey: String,
                briefDescription: String?,
                catalogVisibilityKey: String,
                crossSellIDs: [Int64]?,
                dateCreated: Date,
                dateModified: Date?,
                downloadable: Bool,
                downloadExpiry: Int64,
                downloadLimit: Int64,
                externalURL: String?,
                featured: Bool,
                fullDescription: String?,
                groupedProducts: [Int64],
                manageStock: Bool,
                menuOrder: Int64,
                name: String,
                onSale: Bool,
                parentID: Int64,
                permalink: String,
                price: String,
                productID: Int64,
                productTypeKey: String,
                purchasable: Bool,
                purchaseNote: String?,
                ratingCount: Int64,
                regularPrice: String?,
                relatedIDs: [Int64]?,
                reviewsAllowed: Bool,
                salePrice: String?,
                shippingClass: String?,
                shippingClassID: Int64,
                shippingRequired: Bool,
                shippingTaxable: Bool,
                siteID: Int64,
                sku: String?,
                slug: String,
                soldIndividually: Bool,
                statusKey: String,
                stockQuantity: String?,
                stockStatusKey: String,
                taxClass: String?,
                taxStatusKey: String,
                totalSales: Int64,
                upsellIDs: [Int64]?,
                variations: [Int64]?,
                virtual: Bool,
                weight: String?,
                // Relationships.
                attributes: [ProductAttribute],
                categories: [ProductCategory],
                defaultAttributes: [ProductDefaultAttribute],
                dimensions: ProductDimensions?,
                downloads: [ProductDownload],
                images: [ProductImage],
                productVariations: [ProductVariation],
                searchResults: [ProductSearchResults],
                tags: [ProductTag])
        // Entities.
        self.averageRating = averageRating
        self.backordered = backordered
        self.backordersAllowed = backordersAllowed
        self.backordersKey = backordersKey
        self.briefDescription = briefDescription
        self.catalogVisibilityKey = catalogVisibilityKey
        self.crossSellIDs = crossSellIDs
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.downloadable = downloadable
        self.downloadExpiry = downloadExpiry
        self.downloadLimit = downloadLimit
        self.externalURL = externalURL
        self.featured = featured
        self.fullDescription = fullDescription
        self.groupedProducts = groupedProducts
        self.manageStock = manageStock
        self.menuOrder = menuOrder
        self.name = name
        self.onSale = onSale
        self.parentID = parentID
        self.permalink = permalink
        self.price = price
        self.productID = productID
        self.productTypeKey = productTypeKey
        self.purchasable = purchasable
        self.purchaseNote = purchaseNote
        self.ratingCount = ratingCount
        self.regularPrice = regularPrice
        self.relatedIDs = relatedIDs
        self.reviewsAllowed = reviewsAllowed
        self.salePrice = salePrice
        self.shippingClass = shippingClass
        self.shippingClassID = shippingClassID
        self.shippingRequired = shippingRequired
        self.shippingTaxable = shippingTaxable
        self.siteID = siteID
        self.sku = sku
        self.slug = slug
        self.soldIndividually = soldIndividually
        self.statusKey = statusKey
        self.stockQuantity = stockQuantity
        self.stockStatusKey = stockStatusKey
        self.taxClass = taxClass
        self.taxStatusKey = taxStatusKey
        self.totalSales = totalSales
        self.upsellIDs = upsellIDs
        self.variations = variations
        self.virtual = virtual
        self.weight = weight
        // Relationships.
        self.attributes = attributes
        self.categories = categories
        self.defaultAttributes = defaultAttributes
        self.dimensions = dimensions
        self.downloads = downloads
        self.images = images
        self.productVariations = productVariations
        self.searchResults = searchResults
        self.tags = tags
    }


    /// Public initializer for Product.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Entities.
        let averageRating = try container.decode(String.self, forKey: .averageRating)
        let backordered = try container.decode(Bool.self, forKey: .backordered)
        let backordersAllowed = try container.decode(Bool.self, forKey: .backordersAllowed)
        let backordersKey = try container.decode(String.self, forKey: .backordersKey)
        let briefDescription = try container.decodeIfPresent(String.self, forKey: .briefDescription)
        let catalogVisibilityKey = try container.decode(String.self, forKey: .catalogVisibilityKey)
        let crossSellIDs = try container.decodeIfPresent([Int64].self, forKey: .crossSellIDs)
        let dateCreated = try container.decode(Date.self, forKey: .dateCreated)
        let dateModified = try container.decodeIfPresent(Date.self, forKey: .dateModified)
        let downloadable = try container.decode(Bool.self, forKey: .downloadable)
        let downloadExpiry = try container.decode(Int64.self, forKey: .downloadExpiry)
        let downloadLimit = try container.decode(Int64.self, forKey: .downloadLimit)
        let externalURL = try container.decodeIfPresent(String.self, forKey: .externalURL)
        let featured = try container.decode(Bool.self, forKey: .featured)
        let fullDescription = try container.decodeIfPresent(String.self, forKey: .fullDescription)
        let groupedProducts = try container.decode([Int64].self, forKey: .groupedProducts)
        let manageStock = try container.decode(Bool.self, forKey: .manageStock)
        let menuOrder = try container.decode(Int64.self, forKey: .menuOrder)
        let name = try container.decode(String.self, forKey: .name)
        let onSale = try container.decode(Bool.self, forKey: .onSale)
        let parentID = try container.decode(Int64.self, forKey: .parentID)
        let permalink = try container.decode(String.self, forKey: .permalink)
        let price = try container.decode(String.self, forKey: .price)
        let productID = try container.decode(Int64.self, forKey: .productID)
        let productTypeKey = try container.decode(String.self, forKey: .productTypeKey)
        let purchasable = try container.decode(Bool.self, forKey: .purchasable)
        let purchaseNote = try container.decodeIfPresent(String.self, forKey: .purchaseNote)
        let ratingCount = try container.decode(Int64.self, forKey: .ratingCount)
        let regularPrice = try container.decodeIfPresent(String.self, forKey: .regularPrice)
        let relatedIDs = try container.decodeIfPresent([Int64].self, forKey: .relatedIDs)
        let reviewsAllowed = try container.decode(Bool.self, forKey: .reviewsAllowed)
        let salePrice = try container.decodeIfPresent(String.self, forKey: .salePrice)
        let shippingClass = try container.decodeIfPresent(String.self, forKey: .shippingClass)
        let shippingClassID = try container.decode(Int64.self, forKey: .shippingClassID)
        let shippingRequired = try container.decode(Bool.self, forKey: .shippingRequired)
        let shippingTaxable = try container.decode(Bool.self, forKey: .shippingTaxable)
        let siteID = try container.decode(Int64.self, forKey: .siteID)
        let sku = try container.decodeIfPresent(String.self, forKey: .sku)
        let slug = try container.decode(String.self, forKey: .slug)
        let soldIndividually = try container.decode(Bool.self, forKey: .soldIndividually)
        let statusKey = try container.decode(String.self, forKey: .statusKey)
        let stockQuantity = try container.decodeIfPresent(String.self, forKey: .stockQuantity)
        let stockStatusKey = try container.decode(String.self, forKey: .stockStatusKey)
        let taxClass = try container.decodeIfPresent(String.self, forKey: .taxClass)
        let taxStatusKey = try container.decode(String.self, forKey: .taxStatusKey)
        let totalSales = try container.decode(Int64.self, forKey: .totalSales)
        let upsellIDs = try container.decodeIfPresent([Int64].self, forKey: .upsellIDs)
        let variations = try container.decodeIfPresent([Int64].self, forKey: .variations)
        let virtual = try container.decode(Bool.self, forKey: .virtual)
        let weight = try container.decodeIfPresent(String.self, forKey: .weight)

        // Relationships.
        let attributes = try container.decodeIfPresent([ProductAttribute].self, forKey: .attributes) ?? []
        let categories = try container.decodeIfPresent([ProductCategory].self, forKey: .categories) ?? []
        let defaultAttributes = try container.decodeIfPresent([ProductDefaultAttribute].self, forKey: .defaultAttributes) ?? []
        let dimensions = try container.decodeIfPresent(ProductDimensions.self, forKey: .dimensions)
        let downloads = try container.decodeIfPresent([ProductDownload].self, forKey: .downloads) ?? []
        let images = try container.decodeIfPresent([ProductImage].self, forKey: .images) ?? []
        let productVariations = try container.decodeIfPresent([ProductVariation].self, forKey: .productVariations) ?? []
        let searchResults = try container.decodeIfPresent([ProductSearchResults].self, forKey: .searchResults) ?? []
        let tags = try container.decodeIfPresent([ProductTag].self, forKey: .tags) ?? []

        self.init(averageRating: averageRating,
                  backordered: backordered,
                  backordersAllowed: backordersAllowed,
                  backordersKey: backordersKey,
                  briefDescription: briefDescription,
                  catalogVisibilityKey: catalogVisibilityKey,
                  crossSellIDs: crossSellIDs,
                  dateCreated: dateCreated,
                  dateModified: dateModified,
                  downloadable: downloadable,
                  downloadExpiry: downloadExpiry,
                  downloadLimit: downloadLimit,
                  externalURL: externalURL,
                  featured: featured,
                  fullDescription: fullDescription,
                  groupedProducts: groupedProducts,
                  manageStock: manageStock,
                  menuOrder: menuOrder,
                  name: name,
                  onSale: onSale,
                  parentID: parentID,
                  permalink: permalink,
                  price: price,
                  productID: productID,
                  productTypeKey: productTypeKey,
                  purchasable: purchasable,
                  purchaseNote: purchaseNote,
                  ratingCount: ratingCount,
                  regularPrice: regularPrice,
                  relatedIDs: relatedIDs,
                  reviewsAllowed: reviewsAllowed,
                  salePrice: salePrice,
                  shippingClass: shippingClass,
                  shippingClassID: shippingClassID,
                  shippingRequired: shippingRequired,
                  shippingTaxable: shippingTaxable,
                  siteID: siteID,
                  sku: sku,
                  slug: slug,
                  soldIndividually: soldIndividually,
                  statusKey: statusKey,
                  stockQuantity: stockQuantity,
                  stockStatusKey: stockStatusKey,
                  taxClass: taxClass,
                  taxStatusKey: taxStatusKey,
                  totalSales: totalSales,
                  upsellIDs: upsellIDs,
                  variations: variations,
                  virtual: virtual,
                  weight: weight,
                  // Relationships.
                  attributes: attributes,
                  categories: categories,
                  defaultAttributes: defaultAttributes,
                  dimensions: dimensions,
                  downloads: downloads,
                  images: images,
                  productVariations: productVariations,
                  searchResults: searchResults,
                  tags: tags)
    }
}


/// Defines all of the Product CodingKeys
///
private extension Product {
    enum CodingKeys: String, CodingKey {
        case averageRating
        case backordered
        case backordersAllowed
        case backordersKey
        case briefDescription
        case catalogVisibilityKey
        case crossSellIDs
        case dateCreated
        case dateModified
        case downloadable
        case downloadExpiry
        case downloadLimit
        case externalURL
        case featured
        case fullDescription
        case groupedProducts
        case manageStock
        case menuOrder
        case name
        case onSale
        case parentID
        case permalink
        case price
        case productID
        case productTypeKey
        case purchasable
        case purchaseNote
        case ratingCount
        case regularPrice
        case relatedIDs
        case reviewsAllowed
        case salePrice
        case shippingClass
        case shippingClassID
        case shippingRequired
        case shippingTaxable
        case siteID
        case sku
        case slug
        case soldIndividually
        case statusKey
        case stockQuantity
        case stockStatusKey
        case taxClass
        case taxStatusKey
        case totalSales
        case upsellIDs
        case variations
        case virtual
        case weight
    }
}


// MARK: - Equatable Conformance
//
extension Product: Equatable {
    public static func == (lhs: Product, rhs: Product) -> Bool {
        return lhs.averageRating == rhs.averageRating
            lhs.backordered == rhs.backordered
            lhs.backordersAllowed == rhs.backordersAllowed
            lhs.backordersKey == rhs.backordersKey
            lhs.briefDescription == rhs.briefDescription
            lhs.catalogVisibilityKey == rhs.catalogVisibilityKey
            lhs.crossSellIDs == rhs.crossSellIDs
            lhs.dateCreated == rhs.dateCreated
            lhs.dateModified == rhs.dateModified
            lhs.downloadable == rhs.downloadable
            lhs.downloadExpiry == rhs.downloadExpiry
            lhs.downloadLimit == rhs.downloadLimit
            lhs.externalURL == rhs.externalURL
            lhs.featured == rhs.featured
            lhs.fullDescription == rhs.fullDescription
            lhs.groupedProducts == rhs.groupedProducts
            lhs.manageStock == rhs.manageStock
            lhs.menuOrder == rhs.menuOrder
            lhs.name == rhs.name
            lhs.onSale == rhs.onSale
            lhs.parentID == rhs.parentID
            lhs.permalink == rhs.permalink
            lhs.price == rhs.price
            lhs.productID == rhs.productID
            lhs.productTypeKey == rhs.productTypeKey
            lhs.purchasable == rhs.purchasable
            lhs.purchaseNote == rhs.purchaseNote
            lhs.ratingCount == rhs.ratingCount
            lhs.regularPrice == rhs.regularPrice
            lhs.relatedIDs == rhs.relatedIDs
            lhs.reviewsAllowed == rhs.reviewsAllowed
            lhs.salePrice == rhs.salePrice
            lhs.shippingClass == rhs.shippingClass
            lhs.shippingClassID == rhs.shippingClassID
            lhs.shippingRequired == rhs.shippingRequired
            lhs.shippingTaxable == rhs.shippingTaxable
            lhs.siteID == rhs.siteID
            lhs.sku == rhs.sku
            lhs.slug == rhs.slug
            lhs.soldIndividually == rhs.soldIndividually
            lhs.statusKey == rhs.statusKey
            lhs.stockQuantity == rhs.stockQuantity
            lhs.stockStatusKey == rhs.stockStatusKey
            lhs.taxClass == rhs.taxClass
            lhs.taxStatusKey == rhs.taxStatusKey
            lhs.totalSales == rhs.totalSales
            lhs.upsellIDs == rhs.upsellIDs
            lhs.variations == rhs.variations
            lhs.virtual == rhs.virtual
            lhs.weight == rhs.weight
            // Relationships.
            lhs.attributes == rhs.attributes
            lhs.categories == rhs.categories
            lhs.defaultAttributes == rhs.defaultAttributes
            lhs.dimensions == rhs.dimensions
            lhs.downloads == rhs.downloads
            lhs.images == rhs.images
            lhs.productVariations == rhs.productVariations
            lhs.searchResults == rhs.searchResults
            lhs.tags == rhs.tags
    }
}
