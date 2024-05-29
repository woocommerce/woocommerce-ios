import Foundation
import class WooFoundation.CurrencySettings
import class WooFoundation.CurrencyFormatter

public struct POSProduct {
    public let itemID: UUID
    public let productID: Int64
    public let name: String
    public let price: String
    public let priceWithCurrency: String
    private let currencySettings: CurrencySettings

    public init(itemID: UUID, productID: Int64, name: String, price: String, currencySettings: CurrencySettings) {
        self.itemID = itemID
        self.productID = productID
        self.name = name
        self.price = price
        self.currencySettings = currencySettings
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.priceWithCurrency = currencyFormatter.formatAmount(price, with: currencySettings.currencyCode.rawValue) ?? String()
    }
}
