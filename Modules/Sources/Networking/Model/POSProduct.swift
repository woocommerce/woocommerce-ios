import Foundation
import Codegen

/// Represents a Product Entity, for use in Point of Sale.
/// This deliberately only includes a subset of the fields available for Product.
/// It's likely that most or all of a store's products will be fetched and stored for POS,
/// so we wanted a smaller representation and to reduce the risk of decoding issues
/// caused by plugin incompatibilities.
///
public struct POSProduct: Codable, Equatable, GeneratedCopiable, GeneratedFakeable {
    public let siteID: Int64
    public let productID: Int64
    public let name: String
    public let productTypeKey: String
    public let fullDescription: String?
    // periphery:ignore - Will be used for search in future
    public let shortDescription: String?
    public let sku: String?
    public let globalUniqueID: String?

    public let price: String

    public let downloadable: Bool

    public let parentID: Int64

    public let images: [ProductImage]

    public let attributes: [ProductAttribute]

    public var productType: ProductType {
        return ProductType(rawValue: productTypeKey)
    }

    /// Filtered product attributes available for variations
    /// (attributes with `variation == true`)
    ///
    public var attributesForVariations: [ProductAttribute] {
        attributes.filter { $0.variation }
    }

    public let manageStock: Bool
    public let stockQuantity: Decimal?
    public let stockStatusKey: String

    public let statusKey: String

    public var productStatus: ProductStatus {
        return ProductStatus(rawValue: statusKey)
    }

    public let variationIDs: [Int64]

    public init(siteID: Int64,
                productID: Int64,
                name: String,
                productTypeKey: String,
                fullDescription: String?,
                shortDescription: String?,
                sku: String?,
                globalUniqueID: String?,
                price: String,
                downloadable: Bool,
                parentID: Int64,
                images: [ProductImage],
                attributes: [ProductAttribute],
                manageStock: Bool,
                stockQuantity: Decimal?,
                stockStatusKey: String,
                statusKey: String,
                variationIDs: [Int64]) {
        self.siteID = siteID
        self.productID = productID
        self.name = name
        self.productTypeKey = productTypeKey
        self.fullDescription = fullDescription
        self.shortDescription = shortDescription
        self.sku = sku
        self.globalUniqueID = globalUniqueID

        self.price = price

        self.downloadable = downloadable

        self.parentID = parentID

        self.images = images

        self.attributes = attributes

        self.manageStock = manageStock
        self.stockQuantity = stockQuantity
        self.stockStatusKey = stockStatusKey

        self.statusKey = statusKey

        self.variationIDs = variationIDs
    }

    public init(from decoder: any Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw POSProductDecodingError.missingSiteID
        }

        /// If you make a change which improves the safety of this decoding,
        /// consider applying it to `Product` as well.

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decimalString = AlternativeDecodingType.decimal { value in
            NSDecimalNumber(decimal: value).stringValue
        }

        let productID = try container.decode(Int64.self, forKey: .productID)
        let name = try container.decode(String.self, forKey: .name)
        let productTypeKey = try container.decode(String.self, forKey: .productTypeKey)
        let fullDescription = try container.decodeIfPresent(String.self, forKey: .fullDescription)
        let shortDescription = try container.decodeIfPresent(String.self, forKey: .shortDescription)
        let sku = container.failsafeDecodeIfPresent(
            targetType: String.self,
            forKey: .sku,
            alternativeTypes: [decimalString])
        let globalUniqueID = try container.decodeIfPresent(String.self, forKey: .globalUniqueID)

        let price = container.failsafeDecodeIfPresent(
            targetType: String.self,
            forKey: .price,
            alternativeTypes: [decimalString]) ?? ""

        let downloadable = try container.decode(Bool.self, forKey: .downloadable)

        let parentID = try container.decode(Int64.self, forKey: .parentID)

        let images = try container.decode([ProductImage].self, forKey: .images)

        let attributes = try container.decode([ProductAttribute].self, forKey: .attributes)

        let manageStock = try container.decode(Bool.self, forKey: .manageStock)
        let stockQuantity = container.failsafeDecodeIfPresent(decimalForKey: .stockQuantity)
        let stockStatusKey = try container.decode(String.self, forKey: .stockStatusKey)

        let statusKey = try container.decode(String.self, forKey: .statusKey)

        let variationIDs = try container.decodeIfPresent([Int64].self, forKey: .variationIDs) ?? []

        self.init(siteID: siteID,
                  productID: productID,
                  name: name,
                  productTypeKey: productTypeKey,
                  fullDescription: fullDescription,
                  shortDescription: shortDescription,
                  sku: sku,
                  globalUniqueID: globalUniqueID,
                  price: price,
                  downloadable: downloadable,
                  parentID: parentID,
                  images: images,
                  attributes: attributes,
                  manageStock: manageStock,
                  stockQuantity: stockQuantity,
                  stockStatusKey: stockStatusKey,
                  statusKey: statusKey,
                  variationIDs: variationIDs)
    }

    static let requestFields: [String] = {
        CodingKeys.allCases.map( \.rawValue )
    }()
}

// MARK: - Decoding Errors
//
enum POSProductDecodingError: Error {
    case missingSiteID
}

// MARK: - Coding Keys
//
private extension POSProduct {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case productID = "id"
        case name
        case productTypeKey = "type"
        case fullDescription = "description"
        case shortDescription = "short_description"
        case sku
        case globalUniqueID = "global_unique_id"
        case price
        case downloadable
        case parentID = "parent_id"
        case images
        case attributes
        case manageStock = "manage_stock"
        case stockQuantity = "stock_quantity"
        case stockStatusKey = "stock_status"
        case statusKey = "status"
        case variationIDs = "variations"
    }
}
