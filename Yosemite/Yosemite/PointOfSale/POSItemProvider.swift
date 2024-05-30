import class WooFoundation.CurrencySettings
import class WooFoundation.CurrencyFormatter

public struct CartProduct {
    public let id: UUID
    public let product: POSProduct
    public let quantity: Int

    public init(id: UUID, product: POSProduct, quantity: Int) {
        self.id = id
        self.product = product
        self.quantity = quantity
    }
}


public struct POSProduct: POSItem {
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

public protocol POSItem {
    var itemID: UUID { get }
}

public protocol POSItemProvider {
    func providePointOfSaleItems() -> [POSItem]
}
