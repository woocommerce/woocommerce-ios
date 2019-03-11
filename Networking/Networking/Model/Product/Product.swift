import Foundation


/// Represents a Product Entity.
///
public struct Product: Decodable {
    public let productID: Int
    public let name: String
    public let slug: String
    public let permalink: String
    public let dateCreated: Date       // gmt
    public let dateModified: Date?     // gmt
    public let productType: ProductType
    public let status: Product.Status
    public let featured: Bool
    public let catalogVisibility: Product.Visibility
    public let description: String?
    public let shortDescription: String?
    public let sku: String?
    public let price: String
    public let regularPrice: String?
    public let salePrice: String?
    public let dateOnSaleFrom: Date?   // gmt
    public let dateOnSaleTo: Date?     // gmt
    public let priceHTML: String?
    public let onSale: Bool
    public let purchasable: Bool
    public let totalSales: Int
    public let virtual: Bool
    public let downloadable: Bool
    public let downloads: [Download?]
    public let downloadLimit: Int     // defaults to -1
    public let downloadExpiry: Int    // defaults to -1
    public let externalURL: String?
    public let buttonText: String?
    public let taxStatus: Product.TaxStatus
    public let taxClass: String?
    public let manageStock: Bool
    public let stockQuantity: Int?   // API reports Int or null
    public let stockStatus: Product.StockStatus
    public let backOrders: Product.BackOrders
    public let backOrdersAllowed: Bool
    public let backOrdered: Bool
    public let soldIndividually: Bool
    public let weight: String?
    public let dimensions: Dimension // struct
    public let shippingRequired: Bool
    public let shippingTaxable: Bool
    public let shippingClass: String?
    public let shippingClassID: Int
    public let reviewsAllowed: Bool
    public let averageRating: String
    public let ratingCount: Int
    public let relatedIDs: [Int?]
    public let upsellIDs: [Int?]
    public let crossSellIDs: [Int?]
    public let parentID: Int
    public let purchaseNote: String?
    public let categories: [ProductCategory?]
    public let tags: [ProductTag?]
    public let images: [ProductImage?]
    public let attributes: [ProductAttribute?]
    public let defaultAttributes: [ProductDefaultAttribute?]
    public let variations: [Int?]
    public let groupedProducts: [Int?]
    public let menuOrder: Int
    public let metaData: [ProductMetaData?]

    /// Product struct initializer.
    ///
    public init(productID: Int,
                name: String,
                slug: String,
                permalink: String,
                dateCreated: Date,      // gmt
                dateModified: Date?,    // gmt
                productType: ProductType,
                status: Product.Status,
                featured: Bool,
                catalogVisibility: Product.Visibility,
                description: String?,
                shortDescription: String?,
                sku: String?,
                price: String,
                regularPrice: String?,
                salePrice: String?,
                dateOnSaleFrom: Date?,  // gmt
                dateOnSaleTo: Date?,    // gmt
                priceHTML: String?,
                onSale: Bool,
                purchasable: Bool,
                totalSales: Int,
                virtual: Bool,
                downloadable: Bool,
                downloads: [Download?],
                downloadLimit: Int,    // defaults to -1
                downloadExpiry: Int,   // defaults to -1
                externalURL: String?,
                buttonText: String?,
                taxStatus: Product.TaxStatus,
                taxClass: String?,
                manageStock: Bool,
                stockQuantity: Int?,  // API reports Int or null
                stockStatus: Product.StockStatus,
                backOrders: Product.BackOrders,
                backOrdersAllowed: Bool,
                backOrdered: Bool,
                soldIndividually: Bool,
                weight: String?,
                dimensions: Dimension, // struct
                shippingRequired: Bool,
                shippingTaxable: Bool,
                shippingClass: String?,
                shippingClassID: Int,
                reviewsAllowed: Bool,
                averageRating: String,
                ratingCount: Int,
                relatedIDs: [Int?],
                upsellIDs: [Int?],
                crossSellIDs: [Int?],
                parentID: Int,
                purchaseNote: String?,
                categories: [ProductCategory?],
                tags: [ProductTag?],
                images: [ProductImage?],
                attributes: [ProductAttribute?],
                defaultAttributes: [ProductDefaultAttribute?],
                variations: [Int?],
                groupedProducts: [Int?],
                menuOrder: Int,
                metaData: [ProductMetaData?]) {
        self.productID = productID
        self.name = name
        self.slug = slug
        self.permalink = permalink
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.productType = productType
        self.status = status
        self.featured = featured
        self.catalogVisibility = catalogVisibility
        self.description = description
        self.shortDescription = shortDescription
        self.sku = sku
        self.price = price
        self.regularPrice = regularPrice
        self.salePrice = salePrice
        self.dateOnSaleFrom = dateOnSaleFrom
        self.dateOnSaleTo = dateOnSaleTo
        self.priceHTML = priceHTML
        self.onSale = onSale
        self.purchasable = purchasable
        self.totalSales = totalSales
        self.virtual = virtual
        self.downloadable = downloadable
        self.downloads = downloads
        self.downloadLimit = downloadLimit
        self.downloadExpiry = downloadExpiry
        self.externalURL = externalURL
        self.buttonText = buttonText
        self.taxStatus = taxStatus
        self.taxClass = taxClass
        self.manageStock = manageStock
        self.stockQuantity = stockQuantity
        self.stockStatus = stockStatus
        self.backOrders = backOrders
        self.backOrdersAllowed = backOrdersAllowed
        self.backOrdered = backOrdered
        self.soldIndividually = soldIndividually
        self.weight = weight
        self.dimensions = dimensions
        self.shippingRequired = shippingRequired
        self.shippingTaxable = shippingTaxable
        self.shippingClass = shippingClass
        self.shippingClassID = shippingClassID
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
        self.metaData = metaData
    }

    /// The public initializer for Product.
    ///
    public init(from decoder: Decoder) throws {
        // to do
    }
}


/// Defines all of the Product CodingKeys
///
private extension Product {

    enum CodingKeys: String, CodingKey {
        case productID = "id"
        case name
        case slug
        case permalink
        case dateCreated = "date_created_gmt"
        case dateModified = "date_modified_gmt"
        case status
        case featured
        case catalogVisibility = "catalog_visibility"
        case description
        case shortDescription = "short_description"
        case sku
        case price
        case regularPrice = "regular_price"
        case salePrice = "sale_price"
        case dateOnSaleFrom = "date_on_sale_from_gmt"
        case dateOnSaleTo = "date_on_sale_to_gmt"
        case priceHTML = "price_html"
        case onSale = "on_sale"
        case purchasable
        case totalSales = "total_sales"
        case virtual
        case downloadable
        case downloads
        case downloadLimit = "download_limit"
        case downloadExpiry = "download_expiry"
        case externalURL = "external_url"
        case buttonText = "button_text"
        case taxStatus = "tax_status"
        case taxClass = "tax_class"
        case manageStock = "manage_stock"
        case stockQuantity = "stock_quantity"
        case backorders
        case backOrdersAllowed = "backorders_allowed"
        case backordered
        case soldIndividually = "sold_individually"
        case weight
        case dimensions
        case shippingRequired = "shipping_required"
        case shippingTaxable = "shipping_taxable"
        case shippingClass = "shipping_class"
        case shippingClassID = "shipping_class_id"
        case reviewsAllowed = "reviews_allowed"
        case averageRating = "average_rating"
        case ratingCount = "rating_count"
        case relatedIDs = "related_ids"
        case upsellIDs = "upsell_ids"
        case crossSellIDs = "cross_sell_ids"
        case parentID = "parent_id"
        case purchaseNote = "purchase_note"
        case categories
        case tags
        case images
        case attributes
        case defaultAttributes = "default_attributes"
        case variations
        case groupedProducts = "grouped_products"
        case menuOrder = "menu_order"
        case metaData = "meta_data"
    }
}
