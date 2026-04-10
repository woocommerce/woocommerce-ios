import Foundation
import Codegen

/// Represents stock details for a Product.
///
public struct ProductStock: Decodable, GeneratedCopiable, Equatable, GeneratedFakeable, Sendable {

    public let siteID: Int64
    public let productID: Int64
    public let parentID: Int64
    public let name: String

    public let sku: String?
    public let manageStock: Bool
    public let stockQuantity: Decimal?    // Core API reports Int or null; some extensions allow decimal values as well
    public let stockStatusKey: String   // instock, outofstock, backorder

    public var productStockStatus: ProductStockStatus {
        ProductStockStatus(rawValue: stockStatusKey)
    }

    public var isProductVariation: Bool {
        parentID != 0
    }

    public init(siteID: Int64,
                productID: Int64,
                parentID: Int64,
                name: String,
                sku: String?,
                manageStock: Bool,
                stockQuantity: Decimal?,
                stockStatusKey: String) {
        self.siteID = siteID
        self.productID = productID
        self.parentID = parentID
        self.name = name
        self.sku = sku
        self.manageStock = manageStock
        self.stockQuantity = stockQuantity
        self.stockStatusKey = stockStatusKey
    }

    /// The public initializer.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ProductDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let productID = try container.decode(Int64.self, forKey: .productID)
        let parentID = (try? container.decode(Int64.self, forKey: .parentID)) ?? 0
        let name = try container.decode(String.self, forKey: .name)

        // Even though a plain install of WooCommerce Core provides String values,
        // some plugins alter the field value from String to Int or Decimal.
        let sku = container.failsafeDecodeIfPresent(targetType: String.self,
                                                    forKey: .sku,
                                                    alternativeTypes: [.decimal(transform: { NSDecimalNumber(decimal: $0).stringValue })])

        // Even though the API docs claim `manageStock` is a bool, it's possible that `"parent"`
        // could be returned as well (typically with variations) — we need to account for this.
        // A "parent" value means that stock mgmt is turned on + managed at the parent product-level, therefore
        // we need to set this var as `true` in this situation.
        // See: https://github.com/woocommerce/woocommerce-ios/issues/884 for more deets
        let manageStock = container.failsafeDecodeIfPresent(targetType: Bool.self,
                                                            forKey: .manageStock,
                                                            alternativeTypes: [
                                                                .string(transform: { value in
                                                                    // A bool could not be parsed — check if "parent" is set, and if so, set manageStock to
                                                                    // `true`
                                                                    value.lowercased() == Values.manageStockParent ? true : false
                                                                })
        ]) ?? false

        // Even though WooCommerce Core returns Int or null values,
        // some plugins alter the field value from Int to Decimal or String.
        // We handle this as an optional Decimal value.
        let stockQuantity = container.failsafeDecodeIfPresent(decimalForKey: .stockQuantity)

        let stockStatusKey = try container.decode(String.self, forKey: .stockStatusKey)

        self.init(siteID: siteID,
                  productID: productID,
                  parentID: parentID,
                  name: name,
                  sku: sku,
                  manageStock: manageStock,
                  stockQuantity: stockQuantity,
                  stockStatusKey: stockStatusKey)
    }
}

/// Defines all of the ProductStock CodingKeys
///
private extension ProductStock {

    enum CodingKeys: String, CodingKey {
        case productID  = "id"
        case parentID   = "parent_id"
        case name
        case sku            = "sku"

        case manageStock    = "manage_stock"
        case stockQuantity  = "stock_quantity"
        case stockStatusKey = "stock_status"
    }

    // Decoding Errors
    enum DecodingError: Error {
        case missingSiteID
    }

    enum Values {
        static let manageStockParent = "parent"
    }
}
