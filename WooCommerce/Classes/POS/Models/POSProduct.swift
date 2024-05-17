import Foundation

public struct POSProduct {
    public let itemID: UUID
    public let productID: Int64
    public let name: String
    public let price: String
    // The WooCommerce core API for Product makes stockQuantity Int or null, however some extensions allow decimal values as well.
    // We might want to use Decimal type for consistency with the rest of the app
    public let stockQuantity: Int

    public init(itemID: UUID, productID: Int64, name: String, price: String, stockQuantity: Int) {
        self.itemID = itemID
        self.productID = productID
        self.name = name
        self.price = price
        self.stockQuantity = stockQuantity
    }
}
