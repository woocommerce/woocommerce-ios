import Foundation
import Codegen

public struct POSProduct: Codable, Equatable, GeneratedCopiable, GeneratedFakeable {
    public let siteID: Int64
    public let productID: Int64
    public let name: String
    public let productTypeKey: String
    public let sku: String?
    public let globalUniqueID: String?

    public let price: String
    public let regularPrice: String?
    public let salePrice: String?
    public let onSale: Bool

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

    public init(siteID: Int64,
                productID: Int64,
                name: String,
                productTypeKey: String,
                sku: String?,
                globalUniqueID: String?,
                price: String,
                regularPrice: String?,
                salePrice: String?,
                onSale: Bool,
                images: [ProductImage],
                attributes: [ProductAttribute]) {
        self.siteID = siteID
        self.productID = productID
        self.name = name
        self.productTypeKey = productTypeKey
        self.sku = sku
        self.globalUniqueID = globalUniqueID

        self.price = price
        self.regularPrice = regularPrice
        self.salePrice = salePrice
        self.onSale = onSale

        self.images = images

        self.attributes = attributes
    }

    public init(from decoder: any Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw POSProductDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decimalString = AlternativeDecodingType.decimal { value in
            NSDecimalNumber(decimal: value).stringValue
        }

        let productID = try container.decode(Int64.self, forKey: .productID)
        let name = try container.decode(String.self, forKey: .name)
        let productTypeKey = try container.decode(String.self, forKey: .productTypeKey)
        let sku = container.failsafeDecodeIfPresent(
            targetType: String.self,
            forKey: .sku,
            alternativeTypes: [decimalString])
        let globalUniqueID = try container.decodeIfPresent(String.self, forKey: .globalUniqueID)

        let price = container.failsafeDecodeIfPresent(
            targetType: String.self,
            forKey: .price,
            alternativeTypes: [decimalString]) ?? ""
        let regularPrice = container.failsafeDecodeIfPresent(
            targetType: String.self,
            forKey: .regularPrice,
            alternativeTypes: [decimalString])
        let onSale = container.failsafeDecodeIfPresent(
            targetType: Bool.self,
            forKey: .onSale,
            alternativeTypes: [ .string(transform: { NSString(string: $0).boolValue })]) ?? false

        // Even though a plain install of WooCommerce Core provides string values,
        // some plugins alter the field value from String to Int or Decimal.
        let salePrice = container.failsafeDecodeIfPresent(
            targetType: String.self,
            forKey: .salePrice,
            shouldDecodeTargetTypeFirst: false,
            alternativeTypes: [
                .string(transform: { (onSale && $0.isEmpty) ? "0" : $0 }),
                decimalString])


        let images = try container.decode([ProductImage].self, forKey: .images)

        let attributes = try container.decode([ProductAttribute].self, forKey: .attributes)

        self.init(siteID: siteID,
                  productID: productID,
                  name: name,
                  productTypeKey: productTypeKey,
                  sku: sku,
                  globalUniqueID: globalUniqueID,
                  price: price,
                  regularPrice: regularPrice,
                  salePrice: salePrice,
                  onSale: onSale,
                  images: images,
                  attributes: attributes)
    }
}

// MARK: - Decoding Errors
//
enum POSProductDecodingError: Error {
    case missingSiteID
}

// MARK: - Coding Keys
//
private extension POSProduct {
    enum CodingKeys: String, CodingKey {
        case productID = "id"
        case name
        case productTypeKey = "type"
        case sku
        case globalUniqueID = "global_unique_id"
        case price
        case regularPrice = "regular_price"
        case salePrice = "sale_price"
        case onSale = "on_sale"
        case images
        case attributes
    }
}
