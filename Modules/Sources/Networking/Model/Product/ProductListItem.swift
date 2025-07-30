import Foundation
import CocoaLumberjackSwift
import Codegen

/// Represents a Product Entity with basic details to display in the product list.
///
public struct ProductListItem: GeneratedCopiable, Equatable, GeneratedFakeable {
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
    public let globalUniqueID: String?

    public let price: String
    public let regularPrice: String?
    public let salePrice: String?
    public let onSale: Bool

    public let purchasable: Bool
    public let totalSales: Int
    public let virtual: Bool

    public let downloadable: Bool
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

    public let shippingRequired: Bool
    public let shippingTaxable: Bool
    public let shippingClass: String?
    public let shippingClassID: Int64

    public let reviewsAllowed: Bool
    public let averageRating: String
    public let ratingCount: Int

    public let parentID: Int64

    public let purchaseNote: String?
    public let images: [ProductImage]

    public let menuOrder: Int

    public let addOns: [ProductAddOn] //TODO: migrate AddOns to MetaData

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

    /// If not `nil` the product is protected by password. This parameter is available from WooCommerce 8.1.
    /// If under `<8.1`, it should be used `Post` entity under WP.
    public let password: String?

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

    /// Whether the product has an integer (or nil) stock quantity.
    /// Decimal (non-integer) stock quantities currently aren't accepted by the Core API.
    /// Related issue: https://github.com/woocommerce/woocommerce-ios/issues/3494
    private var hasIntegerStockQuantity: Bool {
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
                globalUniqueID: String?,
                price: String,
                regularPrice: String?,
                salePrice: String?,
                onSale: Bool,
                purchasable: Bool,
                totalSales: Int,
                virtual: Bool,
                downloadable: Bool,
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
                shippingRequired: Bool,
                shippingTaxable: Bool,
                shippingClass: String?,
                shippingClassID: Int64,
                reviewsAllowed: Bool,
                averageRating: String,
                ratingCount: Int,
                parentID: Int64,
                purchaseNote: String?,
                images: [ProductImage],
                menuOrder: Int,
                addOns: [ProductAddOn],
                isSampleItem: Bool,
                bundleStockStatus: ProductStockStatus?,
                bundleStockQuantity: Int64?,
                bundleMinSize: Decimal?,
                bundleMaxSize: Decimal?,
                password: String?,
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
        self.globalUniqueID = globalUniqueID
        self.price = price
        self.regularPrice = regularPrice
        self.salePrice = salePrice
        self.onSale = onSale
        self.purchasable = purchasable
        self.totalSales = totalSales
        self.virtual = virtual
        self.downloadable = downloadable
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
        self.shippingRequired = shippingRequired
        self.shippingTaxable = shippingTaxable
        self.shippingClass = shippingClass
        self.shippingClassID = shippingClassID
        self.reviewsAllowed = reviewsAllowed
        self.averageRating = averageRating
        self.ratingCount = ratingCount
        self.parentID = parentID
        self.purchaseNote = purchaseNote
        self.images = images
        self.menuOrder = menuOrder
        self.isSampleItem = isSampleItem
        self.bundleStockStatus = bundleStockStatus
        self.bundleStockQuantity = bundleStockQuantity
        self.bundleMinSize = bundleMinSize
        self.bundleMaxSize = bundleMaxSize
        self.password = password
        self.minAllowedQuantity = minAllowedQuantity.refinedMinMaxQuantityEmptyValue
        self.groupOfQuantity = groupOfQuantity.refinedMinMaxQuantityEmptyValue
        self.maxAllowedQuantity = maxAllowedQuantity
        self.combineVariationQuantities = combineVariationQuantities
        self.addOns = addOns
    }

}

public extension ProductListItem {
    /// Default product URL {site_url}?post_type=product&p={product_id} works for all sites.
    func alternativePermalink(with siteURL: String) -> String {
        String(format: "%@?post_type=product&p=%d", siteURL, productID)
    }
}

// MARK: - Hashable Conformance
//
extension ProductListItem: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(siteID)
        hasher.combine(productID)
    }
}
