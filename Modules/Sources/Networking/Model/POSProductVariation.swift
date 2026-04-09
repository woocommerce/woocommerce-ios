import CocoaLumberjackSwift
import Foundation
import Codegen

/// Represents a Product Variation Entity for use in Point of Sale.
/// This deliberately only includes a subset of the fields available for ProductVariation.
/// It's likely that most or all of a store's variations will be fetched and stored for POS,
/// so we wanted a smaller representation and to reduce the risk of decoding issues
/// caused by plugin incompatibilities.
///
public struct POSProductVariation: Codable, Equatable, GeneratedCopiable, GeneratedFakeable {
    public let siteID: Int64
    public let productID: Int64

    public let productVariationID: Int64

    public let attributes: [ProductVariationAttribute]
    public let image: ProductImage?

    // periphery:ignore - Will be used for search in future
    public let fullDescription: String?
    public let sku: String?
    public let globalUniqueID: String?

    public let typeKey: String

    public let price: String
    public let downloadable: Bool

    public let manageStock: Bool
    public let stockQuantity: Decimal?
    public let stockStatusKey: String

    public var stockStatus: ProductStockStatus {
        return ProductStockStatus(rawValue: stockStatusKey)
    }

    public init(siteID: Int64,
                productID: Int64,
                productVariationID: Int64,
                attributes: [ProductVariationAttribute],
                image: ProductImage?,
                fullDescription: String?,
                sku: String?,
                globalUniqueID: String?,
                typeKey: String = "variation",
                price: String,
                downloadable: Bool,
                manageStock: Bool,
                stockQuantity: Decimal?,
                stockStatusKey: String) {
        self.siteID = siteID
        self.productID = productID
        self.productVariationID = productVariationID
        self.attributes = attributes
        self.image = image
        self.fullDescription = fullDescription
        self.sku = sku
        self.globalUniqueID = globalUniqueID
        self.typeKey = typeKey
        self.price = price
        self.downloadable = downloadable
        self.manageStock = manageStock
        self.stockQuantity = stockQuantity
        self.stockStatusKey = stockStatusKey
    }

    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw POSProductVariationDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decimalString = AlternativeDecodingType.decimal { value in
            NSDecimalNumber(decimal: value).stringValue
        }

        let productVariationID = try container.decode(Int64.self, forKey: .productVariationID)
        let productID = try container.decode(Int64.self, forKey: .productID)
        let attributes = try container.decode([ProductVariationAttribute].self, forKey: .attributes)
        let image = try container.decodeIfPresent(ProductImage.self, forKey: .image)
        let fullDescription = try container.decodeIfPresent(String.self, forKey: .fullDescription)
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
        let manageStock = container.failsafeDecodeIfPresent(
            targetType: Bool.self,
            forKey: .manageStock,
            alternativeTypes: [
                .string(transform: { value in
                    guard value.lowercased() == Values.manageStockParent else {
                        let message = "Unexpected manage stock value: \(value)"
                        assertionFailure(message)
                        let formattedMessage = DDLogMessageFormat(stringLiteral: message)
                        DDLogError(formattedMessage)
                        return false
                    }
                    return false
                })
        ]) ?? false
        let stockQuantity = container.failsafeDecodeIfPresent(decimalForKey: .stockQuantity)
        let typeKey = try container.decodeIfPresent(String.self, forKey: .typeKey) ?? "variation"
        let stockStatusKey = try container.decode(String.self, forKey: .stockStatusKey)

        self.init(siteID: siteID,
                  productID: productID,
                  productVariationID: productVariationID,
                  attributes: attributes,
                  image: image,
                  fullDescription: fullDescription,
                  sku: sku,
                  globalUniqueID: globalUniqueID,
                  typeKey: typeKey,
                  price: price,
                  downloadable: downloadable,
                  manageStock: manageStock,
                  stockQuantity: stockQuantity,
                  stockStatusKey: stockStatusKey)
    }

    static let requestFields: [String] = {
        CodingKeys.allCases.map( \.rawValue )
    }()
}

// MARK: - Decoding Errors
//
enum POSProductVariationDecodingError: Error {
    case missingSiteID
    case missingProductID
}

// MARK: - Coding Keys
//
private extension POSProductVariation {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case productVariationID = "id"
        case productID = "parent_id"
        case attributes
        case image
        case price
        case fullDescription = "description"
        case sku
        case globalUniqueID = "global_unique_id"
        case typeKey = "type"
        case downloadable
        case manageStock = "manage_stock"
        case stockQuantity = "stock_quantity"
        case stockStatusKey = "stock_status"
    }
}

private extension POSProductVariation {
    enum Values {
        static let manageStockParent = "parent"
    }
}
