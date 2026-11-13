import Foundation

/// Product identifiers returned from a WooShipping config line item.
public struct WooShippingEUProductIdentifiers: Equatable, Sendable {
    public let productID: Int64
    public let sku: String
    public let manufacturerProductID: String
    public let standardizedProductID: String

    public init(productID: Int64,
                sku: String,
                manufacturerProductID: String,
                standardizedProductID: String) {
        self.productID = productID
        self.sku = sku
        self.manufacturerProductID = manufacturerProductID
        self.standardizedProductID = standardizedProductID
    }
}

extension WooShippingEUProductIdentifiers: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let productID = try container.decode(Int64.self, forKey: .productID)
        let sku = try container.decodeIfPresent(String.self, forKey: .sku) ?? ""
        let meta = try? container.decode(Meta.self, forKey: .meta)
        let customsInfo = meta?.customsInfo

        self.init(productID: productID,
                  sku: sku,
                  manufacturerProductID: customsInfo?.manufacturerProductID ?? "",
                  standardizedProductID: customsInfo?.standardizedProductID ?? "")
    }

    private enum CodingKeys: String, CodingKey {
        case productID = "product_id"
        case sku
        case meta
    }

    private struct Meta: Decodable, Sendable {
        let customsInfo: CustomsInfo?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // Ignore malformed customs metadata so a legacy value cannot drop its line item.
            customsInfo = try? container.decode(CustomsInfo.self, forKey: .customsInfo)
        }

        private enum CodingKeys: String, CodingKey {
            case customsInfo = "customs_info"
        }
    }

    private struct CustomsInfo: Decodable, Sendable {
        let manufacturerProductID: String?
        let standardizedProductID: String?

        private enum CodingKeys: String, CodingKey {
            case manufacturerProductID = "manufacturer_product_id"
            case standardizedProductID = "standardized_product_id"
        }
    }
}
