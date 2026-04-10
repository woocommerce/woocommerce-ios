import Foundation
import Codegen
import class Aztec.HTMLParser

/// Represents a single product in a products analytics report over a specific period.
///
public struct ProductsReportItem: Decodable, Equatable, GeneratedFakeable {

    /// Product ID
    ///
    public let productID: Int64

    /// Product name
    ///
    public let productName: String

    /// Quantity sold
    ///
    public let quantity: Int

    /// Net revenue from product
    ///
    public let total: Double

    /// Image URL for product
    ///
    public let imageUrl: String?


    /// Designated Initializer.
    ///
    public init(productID: Int64, productName: String, quantity: Int, total: Double, imageUrl: String?) {
        self.productID = productID
        self.productName = productName
        self.quantity = quantity
        self.total = total
        self.imageUrl = imageUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let productID = try container.decode(Int64.self, forKey: .productID)
        let quantity = try container.decode(Int.self, forKey: .quantity)
        let total = try container.decode(Double.self, forKey: .total)

        let extendedInfo = try container.nestedContainer(keyedBy: ExtendedInfoCodingKeys.self, forKey: .extendedInfo)

        let productName = try extendedInfo.decode(String.self, forKey: .productName)

        // Parse and extract the `src` string out of the image html using `Aztec parser`
        let imageUrl: String? = {
            guard let imageHTML = try? extendedInfo.decodeIfPresent(String.self, forKey: .imageHTML),
            let img = HTMLParser().parse(imageHTML).firstChild(ofType: .img),
            let src = img.attribute(ofType: .src)?.value.toString() else {
                return nil
            }
            return src
        }()

        self.init(productID: productID, productName: productName, quantity: quantity, total: total, imageUrl: imageUrl)
    }
}


/// Defines all of the ProductsReportItem CodingKeys.
///
private extension ProductsReportItem {
    enum CodingKeys: String, CodingKey {
        case productID      = "product_id"
        case total          = "net_revenue"
        case quantity       = "items_sold"
        case extendedInfo   = "extended_info"
    }

    enum ExtendedInfoCodingKeys: String, CodingKey {
        case productName    = "name"
        case imageHTML      = "image"
    }
}


// MARK: - Comparable Conformance
//
extension ProductsReportItem: Comparable {
    public static func < (lhs: ProductsReportItem, rhs: ProductsReportItem) -> Bool {
        return lhs.quantity < rhs.quantity ||
            (lhs.quantity == rhs.quantity && lhs.total < rhs.total)
    }
}
