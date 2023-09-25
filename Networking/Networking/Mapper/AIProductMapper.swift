import Foundation

/// Mapper: `Product` generated using AI
///
struct AIProductMapper: Mapper {
    let siteID: Int64
    let existingCategories: [ProductCategory]
    let existingTags: [ProductTag]

    func map(response: Data) throws -> Product {
        let decoder = JSONDecoder()
        let textCompletion = try decoder.decode(TextCompletionResponse.self, from: response).completion
        let aiProduct = try decoder.decode(AIProduct.self, from: Data(textCompletion.utf8))

        let categories = existingCategories.filter({ aiProduct.categories.contains($0.name) })
        let tags = existingTags.filter({ aiProduct.tags.contains($0.name) })

        return Product(siteID: siteID,
                       aiProduct: aiProduct,
                       categories: categories,
                       tags: tags)
    }
}

private struct TextCompletionResponse: Decodable {
    let completion: String
}

private struct AIProduct: Codable {
    struct Shipping: Codable {
        let length: String
        let weight: String
        let width: String
        let height: String

        init(length: String,
             weight: String,
             width: String,
             height: String) {
            self.length = length
            self.weight = weight
            self.width = width
            self.height = height
        }

        init(from decoder: Decoder) throws {
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
    let name: String
    let description: String
    let shortDescription: String
    let virtual: Bool
    let shipping: Shipping
    let tags: [String]
    let price: String
    let categories: [String]

    init(name: String,
         description: String,
         shortDescription: String,
         virtual: Bool,
         shipping: Shipping,
         tags: [String],
         price: String,
         categories: [String]) {
        self.name = name
        self.description = description
        self.shortDescription = shortDescription
        self.virtual = virtual
        self.shipping = shipping
        self.tags = tags
        self.price = price
        self.categories = categories
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let name = container.failsafeDecodeIfPresent(String.self, forKey: .name) ?? ""
        let description = container.failsafeDecodeIfPresent(String.self, forKey: .description) ?? ""
        let shortDescription = container.failsafeDecodeIfPresent(String.self, forKey: .shortDescription) ?? ""
        let virtual = container.failsafeDecodeIfPresent(Bool.self, forKey: .virtual) ?? false
        let shipping = try container.decode(Shipping.self, forKey: .shipping)
        let tags = container.failsafeDecodeIfPresent([String].self, forKey: .tags) ?? []
        let price = container.failsafeDecodeIfPresent(targetType: String.self,
                                                      forKey: .price,
                                                      alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })]) ?? ""
        let categories = container.failsafeDecodeIfPresent([String].self, forKey: .categories) ?? []

        self.init(name: name,
                  description: description,
                  shortDescription: shortDescription,
                  virtual: virtual,
                  shipping: shipping,
                  tags: tags,
                  price: price,
                  categories: categories)
    }

    enum CodingKeys: String, CodingKey {
        case name = "name"
        case description = "description"
        case shortDescription = "short_description"
        case virtual = "virtual"
        case shipping = "shipping"
        case tags = "tags"
        case price = "price"
        case categories = "categories"
    }
}

// MARK: Helper to init Product
//
private extension Product {
    init(siteID: Int64,
         aiProduct: AIProduct,
         categories: [ProductCategory],
         tags: [ProductTag]) {
        self.init(siteID: siteID,
                  productID: 0,
                  name: aiProduct.name,
                  slug: "",
                  permalink: "",
                  date: Date(),
                  dateCreated: Date(),
                  dateModified: nil,
                  dateOnSaleStart: nil,
                  dateOnSaleEnd: nil,
                  productTypeKey: ProductType.simple.rawValue,
                  statusKey: ProductStatus.published.rawValue,
                  featured: false,
                  catalogVisibilityKey: ProductCatalogVisibility.visible.rawValue,
                  fullDescription: aiProduct.description,
                  shortDescription: aiProduct.shortDescription,
                  sku: "",
                  price: aiProduct.price,
                  regularPrice: "",
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
                  bundledItems: [],
                  compositeComponents: [],
                  subscription: nil,
                  minAllowedQuantity: nil,
                  maxAllowedQuantity: nil,
                  groupOfQuantity: nil,
                  combineVariationQuantities: nil)
    }
}
