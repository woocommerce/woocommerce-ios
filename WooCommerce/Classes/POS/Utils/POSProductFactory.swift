import Foundation
import class WooFoundation.CurrencySettings

/// Temporary fake product factory
///
final class POSProductFactory {
    static func makeProduct(currencySettings: CurrencySettings = ServiceLocator.currencySettings) -> POSProduct {
        POSProduct(itemID: UUID(),
                   productID: 1,
                   name: "Product 1",
                   price: "1.00",
                   currencySettings: currencySettings)
    }

    static func makeFakeProducts(currencySettings: CurrencySettings = ServiceLocator.currencySettings) -> [POSProduct] {
        return [
            POSProduct(itemID: UUID(), productID: 1, name: "Product 1", price: "1.00", currencySettings: currencySettings),
            POSProduct(itemID: UUID(), productID: 2, name: "Product 2", price: "2.00", currencySettings: currencySettings),
            POSProduct(itemID: UUID(), productID: 3, name: "Product 3", price: "3.00", currencySettings: currencySettings),
            POSProduct(itemID: UUID(), productID: 4, name: "Product 4", price: "4.00", currencySettings: currencySettings),
            ]
    }
}
