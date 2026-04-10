import Foundation
import Codegen

/// Represents a single top earner stat for a specific period.
///
public struct TopEarnerStatsItem: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {

    /// Product ID
    ///
    public let productID: Int64

    /// Product name
    ///
    public let productName: String?

    /// Quantity sold
    ///
    public let quantity: Int

    /// Total revenue from product
    ///
    public let total: Double

    /// Currency
    ///
    public let currency: String

    /// Image URL for product
    ///
    public let imageUrl: String?


    /// Designated Initializer.
    ///
    public init(productID: Int64, productName: String?, quantity: Int, total: Double, currency: String, imageUrl: String?) {
        self.productID = productID
        self.productName = productName ?? ""
        self.quantity = quantity
        self.total = total
        self.currency = currency
        self.imageUrl = imageUrl
    }
}


/// Defines all of the TopEarnerStatsItem CodingKeys.
///
private extension TopEarnerStatsItem {
    enum CodingKeys: String, CodingKey {
        case productID = "ID"
        case productName = "name"
        case total = "total"
        case quantity = "quantity"
        case imageUrl = "image"
        case currency = "currency"
    }
}


// MARK: - Comparable Conformance
//
extension TopEarnerStatsItem: Comparable {
    public static func < (lhs: TopEarnerStatsItem, rhs: TopEarnerStatsItem) -> Bool {
        return lhs.quantity < rhs.quantity ||
            (lhs.quantity == rhs.quantity && lhs.total < rhs.total)
    }
}

// MARK: - Identifiable Conformance
//
extension TopEarnerStatsItem: Identifiable {
    public var id: Int64 {
        productID
    }
}

// MARK: - Helper to init Product
//
public extension Product {
    init(siteID: Int64,
         productID: Int64,
         name: String,
         images: [ProductImage]) {
        self.init(siteID: siteID,
                  productID: productID,
                  name: name,
                  slug: "",
                  permalink: "",
                  date: Date(),
                  dateCreated: Date(),
                  dateModified: nil,
                  dateOnSaleStart: nil,
                  dateOnSaleEnd: nil,
                  productTypeKey: ProductType.simple.rawValue,
                  statusKey: ProductStatus.draft.rawValue,
                  featured: false,
                  catalogVisibilityKey: ProductCatalogVisibility.visible.rawValue,
                  fullDescription: "",
                  shortDescription: "",
                  sku: "",
                  globalUniqueID: "",
                  price: "",
                  regularPrice: "",
                  salePrice: "",
                  onSale: false,
                  purchasable: false,
                  totalSales: 0,
                  virtual: false,
                  downloadable: false,
                  downloads: [],
                  downloadLimit: -1,
                  downloadExpiry: -1,
                  buttonText: "",
                  externalURL: "",
                  taxStatusKey: ProductTaxStatus.taxable.rawValue,
                  taxClass: "",
                  manageStock: false,
                  stockQuantity: nil,
                  stockStatusKey: ProductStockStatus.inStock.rawValue,
                  backordersKey: ProductBackordersSetting.notAllowed.rawValue,
                  backordersAllowed: false,
                  backordered: false,
                  soldIndividually: false,
                  weight: "",
                  dimensions: ProductDimensions(length: "", width: "", height: ""),
                  shippingRequired: true,
                  shippingTaxable: true,
                  shippingClass: "",
                  shippingClassID: 0,
                  productShippingClass: nil,
                  reviewsAllowed: true,
                  averageRating: "",
                  ratingCount: 0,
                  relatedIDs: [],
                  upsellIDs: [],
                  crossSellIDs: [],
                  parentID: 0,
                  purchaseNote: "",
                  categories: [],
                  tags: [],
                  images: images,
                  attributes: [],
                  defaultAttributes: [],
                  variations: [],
                  groupedProducts: [],
                  menuOrder: 0,
                  addOns: [],
                  isSampleItem: false,
                  bundleStockStatus: nil,
                  bundleStockQuantity: nil,
                  bundleMinSize: nil,
                  bundleMaxSize: nil,
                  bundledItems: [],
                  password: nil,
                  compositeComponents: [],
                  subscription: nil,
                  minAllowedQuantity: nil,
                  maxAllowedQuantity: nil,
                  groupOfQuantity: nil,
                  combineVariationQuantities: nil,
                  customFields: [])
    }
}
