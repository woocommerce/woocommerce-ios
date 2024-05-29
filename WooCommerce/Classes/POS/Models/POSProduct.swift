import Foundation
import class WooFoundation.CurrencySettings
import class WooFoundation.CurrencyFormatter
import enum Yosemite.ProductType

public struct POSProduct: Equatable {
    public static func == (lhs: POSProduct, rhs: POSProduct) -> Bool {
        lhs.productID == rhs.productID
    }

    public let itemID: UUID
    public let productID: Int64
    public let name: String
    public let price: String
    public let productType: ProductType
    // The WooCommerce core API for Product makes stockQuantity Int or null, however some extensions allow decimal values as well.
    // We might want to use Decimal type for consistency with the rest of the app
    public let stockQuantity: Int
    public let priceWithCurrency: String
    private let currencySettings: CurrencySettings

    public init(itemID: UUID, productID: Int64, name: String, price: String, productType: ProductType, stockQuantity: Int, currencySettings: CurrencySettings) {
        self.itemID = itemID
        self.productID = productID
        self.name = name
        self.price = price
        self.productType = productType
        self.stockQuantity = stockQuantity
        self.currencySettings = currencySettings
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.priceWithCurrency = currencyFormatter.formatAmount(price, with: currencySettings.currencyCode.rawValue) ?? String()
    }

    public func createWithUpdatedQuantity(_ updatedQuantity: Int) -> POSProduct {
        return POSProduct(itemID: itemID,
                          productID: productID,
                          name: name,
                          price: price,
                          productType: productType,
                          stockQuantity: updatedQuantity,
                          currencySettings: currencySettings)
    }
}
