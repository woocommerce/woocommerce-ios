import Foundation
import Codegen

/// Product generated using AI.
///
public struct AIProduct: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    public struct Shipping: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
        public let length: String
        public let weight: String
        public let width: String
        public let height: String

        public init(length: String,
                    weight: String,
                    width: String,
                    height: String) {
            self.length = length
            self.weight = weight
            self.width = width
            self.height = height
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            let length = container.failsafeDecodeIfPresent(targetType: String.self,
                                                           forKey: .length,
                                                           alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })])
            ?? ""

            let weight = container.failsafeDecodeIfPresent(targetType: String.self,
                                                           forKey: .weight,
                                                           alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })])
            ?? ""

            let width = container.failsafeDecodeIfPresent(targetType: String.self,
                                                          forKey: .width,
                                                          alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })])
            ?? ""

            let height = container.failsafeDecodeIfPresent(targetType: String.self,
                                                           forKey: .height,
                                                           alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })])
            ?? ""

            self.init(length: length, weight: weight, width: width, height: height)
        }

        enum CodingKeys: String, CodingKey {
            case length
            case weight
            case width
            case height
        }
    }
    public let names: [String]
    public let descriptions: [String]
    public let shortDescriptions: [String]
    public let virtual: Bool
    public let shipping: Shipping
    public let tags: [String]
    public let price: String
    public let categories: [String]

    public init(names: [String],
                descriptions: [String],
                shortDescriptions: [String],
                virtual: Bool,
                shipping: Shipping,
                tags: [String],
                price: String,
                categories: [String]) {
        self.names = names
        self.descriptions = descriptions
        self.shortDescriptions = shortDescriptions
        self.virtual = virtual
        self.shipping = shipping
        self.tags = tags
        self.price = price
        self.categories = categories
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let names = container.failsafeDecodeIfPresent([String].self, forKey: .names) ?? []
        let descriptions = try container.decode([String].self, forKey: .descriptions)
        let shortDescriptions = try container.decode([String].self, forKey: .shortDescriptions)
        let virtual = container.failsafeDecodeIfPresent(Bool.self, forKey: .virtual) ?? false
        let shipping = container.failsafeDecodeIfPresent(Shipping.self, forKey: .shipping) ?? Shipping(length: "", weight: "", width: "", height: "")
        let tags = container.failsafeDecodeIfPresent([String].self, forKey: .tags) ?? []
        let price = container.failsafeDecodeIfPresent(targetType: String.self,
                                                      forKey: .price,
                                                      alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })]) ?? ""
        let categories = container.failsafeDecodeIfPresent([String].self, forKey: .categories) ?? []

        self.init(names: names,
                  descriptions: descriptions,
                  shortDescriptions: shortDescriptions,
                  virtual: virtual,
                  shipping: shipping,
                  tags: tags,
                  price: price,
                  categories: categories)
    }

    enum CodingKeys: String, CodingKey {
        case names = "names"
        case descriptions = "descriptions"
        case shortDescriptions = "short_descriptions"
        case virtual = "virtual"
        case shipping = "shipping"
        case tags = "tags"
        case price = "price"
        case categories = "categories"
    }
}

// MARK: Helper to init Product
//
public extension Product {
    init(siteID: Int64,
         name: String,
         fullDescription: String?,
         shortDescription: String?,
         aiProduct: AIProduct,
         categories: [ProductCategory],
         tags: [ProductTag]) {
        self.init(siteID: siteID,
                  productID: 0,
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
                  fullDescription: fullDescription,
                  shortDescription: shortDescription,
                  sku: "",
                  price: "",
                  regularPrice: aiProduct.price,
                  salePrice: "",
                  onSale: false,
                  purchasable: false,
                  totalSales: 0,
                  virtual: aiProduct.virtual,
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
                  weight: aiProduct.shipping.weight,
                  dimensions: ProductDimensions(length: aiProduct.shipping.length, width: aiProduct.shipping.width, height: aiProduct.shipping.height),
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
                  categories: categories,
                  tags: tags,
                  images: [],
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
                  combineVariationQuantities: nil)
    }
}
