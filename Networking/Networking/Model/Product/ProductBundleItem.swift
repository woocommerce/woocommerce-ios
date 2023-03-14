import Foundation
import Codegen

/// Represents an item in a Product Bundle
///
public struct ProductBundleItem: Codable, Equatable, GeneratedCopiable, GeneratedFakeable {
    /// Bundled item ID
    public let bundledItemID: Int64

    /// Bundled product ID
    public let productID: Int64

    /// Bundled item menu order
    public let menuOrder: Int64

    /// Title of the bundled product to display.
    public let title: String

    /// Stock status of the bundled item, taking minimum quantity into account.
    public let stockStatus: ProductBundleItemStockStatus

    /// ProductBundleItem struct initializer
    ///
    public init(bundledItemID: Int64,
                productID: Int64,
                menuOrder: Int64,
                title: String,
                stockStatus: ProductBundleItemStockStatus) {
        self.bundledItemID = bundledItemID
        self.productID = productID
        self.menuOrder = menuOrder
        self.title = title
        self.stockStatus = stockStatus
    }

    /// The public initializer for ProductBundleItem.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let bundledItemID = try container.decode(Int64.self, forKey: .bundledItemID)
        let productID = try container.decode(Int64.self, forKey: .productID)
        let menuOrder = try container.decode(Int64.self, forKey: .menuOrder)
        let title = try container.decode(String.self, forKey: .title)
        let stockStatus = try container.decode(ProductBundleItemStockStatus.self, forKey: .stockStatus)

        self.init(bundledItemID: bundledItemID,
                  productID: productID,
                  menuOrder: menuOrder,
                  title: title,
                  stockStatus: stockStatus)
    }
}

/// Defines all of the ProductBundleItem CodingKeys
///
private extension ProductBundleItem {

    enum CodingKeys: String, CodingKey {
        case bundledItemID                      = "bundled_item_id"
        case productID                          = "product_id"
        case menuOrder                          = "menu_order"
        case title
        case stockStatus                        = "stock_status"
    }
}

/// Represents all ProductBundleItem stock statuses
///
public enum ProductBundleItemStockStatus: String, Codable, GeneratedFakeable {
    case inStock        = "in_stock"
    case outOfStock     = "out_of_stock"
    case onBackOrder    = "on_backorder"

    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .inStock:
            return NSLocalizedString("In stock", comment: "Display label for the bundle item's inventory stock status")
        case .outOfStock:
            return NSLocalizedString("Out of stock", comment: "Display label for the bundle item's inventory stock status")
        case .onBackOrder:
            return NSLocalizedString("On back order", comment: "Display label for the bundle item's inventory stock status")
        }
    }
}
