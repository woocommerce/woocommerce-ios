import Foundation
import Codegen

/// A struct to decode product reports.
///
public struct ProductReport: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable, Sendable {
    public let productID: Int64
    public let variationID: Int64?
    public let name: String
    public let imageURL: URL?
    public let itemsSold: Int
    public let stockQuantity: Decimal?

    public init(productID: Int64,
                variationID: Int64?,
                name: String,
                imageURL: URL? = nil,
                itemsSold: Int,
                stockQuantity: Decimal?) {
        self.productID = productID
        self.variationID = variationID
        self.itemsSold = itemsSold
        self.name = name
        self.imageURL = imageURL
        self.stockQuantity = stockQuantity
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let productID = container.failsafeDecodeIfPresent(
            targetType: Int64.self,
            forKey: .productID,
            alternativeTypes: [.string(transform: { Int64($0) ?? 0 })]) ?? 0
        let variationID = container.failsafeDecodeIfPresent(
            targetType: Int64.self,
            forKey: .variationID,
            alternativeTypes: [.string(transform: { Int64($0) ?? 0 })])
        let itemsSold = try container.decode(Int.self, forKey: .itemsSold)
        let extendedInfo = try container.decode(ExtendedInfo.self, forKey: .extendedInfo)
        let imageURL = Self.extractSourceURL(from: (extendedInfo.image ?? ""))
        let stockQuantity = extendedInfo.stockQuantity
        let name = extendedInfo.name

        self.init(productID: productID,
                  variationID: variationID,
                  name: name,
                  imageURL: imageURL,
                  itemsSold: itemsSold,
                  stockQuantity: stockQuantity)
    }
}

public extension ProductReport {
    struct ExtendedInfo: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {
        public let name: String
        public let image: String?
        public let stockQuantity: Decimal?

        public init(name: String,
                    image: String?,
                    stockQuantity: Decimal?) {
            self.name = name
            self.image = image
            self.stockQuantity = stockQuantity
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let name = try container.decode(String.self, forKey: .name)
            let image = try container.decodeIfPresent(String.self, forKey: .image)

            // Even though WooCommerce Core returns Int or null values,
            // some plugins alter the field value from Int to Decimal or String.
            // We handle this as an optional Decimal value.
            let stockQuantity = container.failsafeDecodeIfPresent(decimalForKey: .stockQuantity)

            self.init(name: name, image: image, stockQuantity: stockQuantity)
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case image
            case stockQuantity = "stock_quantity"
        }
    }
}

private extension ProductReport {
    static func extractSourceURL(from content: String) -> URL? {
        let components = content.split(separator: " ")
        if let src = components.first(where: { $0.hasPrefix("src=")}) {
            let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let input = String(src)
            let matches = detector?.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
            if let match = matches?.first,
               let range = Range(match.range, in: input) {
                let url = String(input[range])
                return URL(string: url)
            }
        }
        DDLogError("⛔️ Error detecting URL from \(content)")
        return nil
    }

    enum CodingKeys: String, CodingKey {
        case productID = "product_id"
        case variationID = "variation_id"
        case itemsSold  = "items_sold"
        case extendedInfo = "extended_info"
    }
}
